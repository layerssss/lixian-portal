express = require 'express'
http = require 'http'
path = require 'path'
fs = require 'fs'
moment = require 'moment'
icedcoffeescript = require('iced-coffee-script')
client = require './client'

{
  exec
  execFile
  spawn
} = require 'child_process'

moment.locale 'zh-cn'

app = express favicon: false
app.locals.info = client = require './client'
app.locals.pretty = true
app.locals.moment = moment
app.locals.filesize = require 'filesize'
app.locals.active_tab = 'unknown'
app.locals.version = require('./package').version
app.set 'view engine', 'jade'
app.set 'views', path.join __dirname, 'views'
app.use '/browse', express.static client.cwd
app.use express.bodyParser()
app.use (req, res, next)->
  req.body[k] = v for k, v of req.query
  next()
app.use express.methodOverride()

vcodeReqs = []

await client.init defer e
throw e if e

client.startCron()
queue = client.queue
queue.lixian.vcodeHandler = (vcodeData, cb)->
  vcodeReqs.push 
    data: "data:image/jpeg;base64,#{vcodeData.toString 'base64'}"
    cb: cb

app.get '/stats.json', (req, res, n)->
  for task in client.stats.tasks
    task.total = 0
    task.fetched = 0
    for file in task.files
      file.retrieving = client.stats.retrieving?.task.id == task.id && client.stats.retrieving?.file.name == file.name 

      task.total += file.size
      if file.finished
        task.fetched += file.size
      else if file.retrieving && client.stats.retrieving?.progress
        task.fetched += client.stats.retrieving.progress.currentSize
    task.progress = task.fetched * 100 / task.total
  data = 
    vcode: vcodeReqs[0]?.data
    executings: client.stats.executings
    tasks: client.stats.tasks
  if client.stats.retrieving?.progress
    data.progress = 
      speed: client.stats.retrieving.progress.speed
      progress: client.stats.retrieving.progress.percentage
      fetched: client.stats.retrieving.progress.currentSize
      eta: client.stats.retrieving.progress.remainingTime
  res.json data

  return res.end '' unless vcodeReqs[0]
  res.end 

app.get '/script.js', (req, res, n)->
  await fs.readFile path.join(__dirname, 'script.iced'), 'utf8', defer e, script
  return n e if e
  try
    script = icedcoffeescript.compile script, runtime: 'window'
  catch e 
    return n e
  res.end script


app.get '/', (req, res, n)->
  return res.redirect '/login' if client.stats.requireLogin
  while client.log.length > 100
    client.log.pop()
  res.render 'tasks', active_tab: 'tasks'

app.get '/new_task', (req, res, n)->
  return res.redirect '/login' if client.stats.requireLogin
  res.render 'new_task', active_tab: 'new_task'

app.get '/browse', (req, res, n)->
  req.query.path ?= ''
  dirpath = path.resolve client.cwd, req.query.path
  return n 403 unless 0 == dirpath.indexOf client.cwd
  await fs.readdir dirpath, defer e, files 
  return n e if e
  res.locals.files = []
  res.locals.path = req.query.path
  for file in files
    continue if file.match /^\./
    await fs.stat path.join(dirpath, file), defer e, stats
    return n e if e
    res.locals.files.push 
      name: file
      path: path.join(req.query.path, file)
      isFile: stats.isFile()
      isDirectory: stats.isDirectory()
      size: stats.size
      mtime: stats.mtime
      atime: stats.atime
  segs = req.query.path.split '/'
  segs = segs.filter (s)-> s != ''
  res.locals.parents = []
  for seg, i in segs
    res.locals.parents.push
      name: seg
      path: segs[0..i].join path.sep
  res.render 'browse', 
    active_tab: 'browse'


app.all '*', (req, res, n)->
  return n null if req.method is 'GET'
  ip = req.header('x-forwarded-for') || req.connection.remoteAddress
  ip = ip.split(',')[0].trim()
  return n 403 if process.env.ONLYFROM && -1 == process.env.ONLYFROM.indexOf ip
  n null

app.post '/vcode', (req, res, n)->
  vcodeReqs.shift()?.cb null, req.body.vcode
  res.end ''

app.post '/', (req, res, n)->
  if req.files && req.files.bt && req.files.bt.path && req.files.bt.length
    bt = req.files.bt
    await fs.rename bt.path, "#{bt.path}.torrent", defer e 
    return n e if e
    await queue.execute 'addBtTask', bt.name, "#{bt.path}.torrent", defer e
    return n e if e
  if req.body.url && req.body.url.length
    await queue.execute 'addTask', req.body.url, defer e
    return n e if e
  res.redirect '/'

app.get '/login', (req, res)-> 
  res.locals.vcode = null
  res.render 'login'
app.post '/login', (req, res, n)-> 
  await queue.execute 'login', req.body.username, req.body.password, defer e
  return n e if e
  res.redirect '/'
app.get '/logout', (req, res, n)-> 
  await queue.execute 'logout', defer e
  return n e if e
  res.redirect '/'

app.delete '/tasks/:id', (req, res, n)->
  await queue.execute 'deleteTask', req.params.id, defer e
  return n e if e
  res.redirect '/'
        

app.use (e, req, res, next)->
  res.render 'error',
    error: e

autorefresh = ->
  await queue.execute 'updateTasklist', defer(e)
  setTimeout autorefresh, 60000 * (1 + Math.random() * 3)
autorefresh()

port = process.env.PORT || 3000
if isNaN Number port
  await exec "fuser #{port}", defer e
  throw new Error "#{port} already owned by another process" unless e
  await fs.unlink port, defer e

  await (server = http.createServer app).listen port, defer e
  throw e if e
  console.log "portal ready on unix://#{port}"

  await fs.chmod port, '0777', defer e
  throw e if e
else
  await (server = http.createServer app).listen (Number port), defer e
  throw e if e
  address = server.address().address
  address = '*' if address == '0.0.0.0'
  console.log "portal ready on http://#{address}:#{port}/"
