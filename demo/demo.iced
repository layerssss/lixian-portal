express = require 'express'
request = require 'request'
http = require 'http'
fs = require 'fs'

{
  exec
} = require 'child_process'

app = express favicon: false

for path in [
  "/"
  "/script.js"
  "/jquery-ujs.js"
  "/stats.json"
  "/new_task"
  "/browse"
]
  app.get path, (req, res, n)->
    path = req.originalUrl
    await request "http://lixian.home.micy.in#{path}", defer e, r, data
    return n e if e
    res.set 'Content-Type', type = r.headers['content-type']
    data += """
    <script>
    $(function(){
      $('<p class="navbar-text navbar-right alert alert-info" style="margin: 9px 10px 0 0; padding: 5px 10px;">这是运行在 Michael Yin 家里的一个 <a href="https://github.com/layerssss/lixian-portal" target="_blank">lixian-portal</a> 演示实例。</p>').appendTo('.navbar-collapse')
    })
    </script>
    """ if type?.match /^text\/html/
    res.end data
app.all '*', (req, res, n)->
  res.set 'Content-Type', 'text/html'
  res.end """
  <script>
  alert("这个功能在演示程序里不能使用，请将 lixian-portal 部署在您自己的计算机上使用。");
  history.go(-1);
  </script>
  """


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
