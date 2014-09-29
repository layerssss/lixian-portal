express = require 'express'
http = require 'http'
path = require 'path'
fs = require 'fs'
client = require './client'
{
  exec
  execFile
  spawn
} = require 'child_process'

app = express favicon: false
app.locals.info = client = require './client'
app.locals.pretty = true
app.set 'view engine', 'jade'
app.set 'views', path.join __dirname, 'views'
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
    data: vcodeData
    cb: cb

app.get '/vcode', (req, res, n)->
  return res.end '' unless vcodeReqs[0]
  res.end vcodeReqs[0].data
app.post '/vcode', (req, res, n)->
  vcodeReqs.shift().cb null, req.body.vcode
  res.end ''


app.get '/', (req, res, n)->
  res.render 'frame'
app.get '/iframe', (req, res, n)->
  return res.redirect '/login' if client.stats.requireLogin
  while client.log.length > 100
    client.log.pop()
  res.render 'tasks'

app.all '*', (req, res, n)->
  return n null if req.method is 'GET'
  ip = req.header('x-forwarded-for') || req.connection.remoteAddress
  ip = ip.split(',')[0].trim()
  return n 403 if process.env.ONLYFROM && -1 == process.env.ONLYFROM.indexOf ip
  n null

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
  return cb e if e
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
