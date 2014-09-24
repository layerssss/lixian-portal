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
app.use express.static path.join __dirname, 'bower_components'
app.locals.pretty = true
app.set 'view engine', 'jade'
app.set 'views', path.join __dirname, 'views'
app.use express.bodyParser()
app.use (req, res, next)->
  req.body[k] = v for k, v of req.query
  next()
app.use express.methodOverride()

client.startCron()
queue = client.queue
autorefresh = ->
  queue.append
    name: "刷新任务列表"
    func: queue.tasks.updateTasklist
  setTimeout autorefresh, 60000 * (1 + Math.random() * 3)
autorefresh()


app.get '/', (req, res, n)->
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
app.post '/refresh', (req, res, n)->

  queue.append
    name: "刷新任务列表"
    func: queue.tasks.updateTasklist
  res.redirect 'back'

app.post '/', (req, res, n)->
  if req.files && req.files.bt && req.files.bt.path && req.files.bt.length
    bt = req.files.bt
    await fs.rename bt.path, "#{bt.path}.torrent", defer e 
    return n e if e
    await queue.tasks.addBtTask bt.name, "#{bt.path}.torrent", defer e
    return n e if e
  else
    await queue.tasks.addTask req.body.url, defer e
    return n e if e
  res.redirect '/'

app.get '/login', (req, res)-> 
  res.locals.vcode = null
  res.render 'login'
app.post '/login', (req, res, n)-> 
  await queue.tasks.login req.body.username, req.body.password, req.body.vcode, defer e
  return n e if e
  res.redirect '/'
app.get '/logout', (req, res, n)-> 
  await queue.tasks.logout defer e
  return n e if e
  res.redirect '/'

app.delete '/tasks/:id', (req, res, n)->
  if client.stats.retrieving?.task.id
    client.stats.retrieving.kill()
  queue.append
    name: "删除任务 #{task.id}"
    func: (fcb)->
      queue.tasks.deleteTask req.params.id, fcb
  res.redirect '/'
        

app.use (e, req, res, next)->
  res.render 'error',
    error: e
await client.init defer e
throw e if e

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
