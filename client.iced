
path = require 'path'
fs = require 'fs'
lazy = require 'lazy'

cli = path.join __dirname, 'xunlei-lixian', 'lixian_cli.py'

{
  exec
  execFile
  spawn
} = require 'child_process'

statusMap = 
  completed: 'success'
  failed: 'error'
  waiting: 'warn'
  downloading: 'info'
statusMapLabel = 
  completed: '完成'
  failed: '失败'
  waiting: '等待'
  downloading: '下载中'

regexMG = /^([^ ]+) +(.+) +(completed|downloading|waiting|failed) *(http\:\/\/.+)?$/mg
regexQ = /^([^ ]+) +(.+) +(completed|downloading|waiting|failed) *(http\:\/\/.+)?$/m

exports.stats = stats = 
  task: null
  retrieving: null
  error: {}
  speed: 'NaN'
  tasks: []
  requireLogin: false
  requireVerificationCode: false
  password: ''
  username: ''

exports.queue = queue = []
exports.log = log = []

workingDirectory = process.cwd()
process.env.HOME = workingDirectory

queue.append = (task)->
  @push task unless (@filter (t)->t.name==task.name).length
queue.prepend = (task)->
  @unshift task unless (@filter (t)->t.name==task.name).length

exports.startCron = ->
  while true
    if queue.length
      stats.task = queue.shift()
      log.unshift  "#{stats.task.name} 启动"
      await stats.task.func defer e
      log.unshift "#{stats.task.name} 完成"
      if e
        log.unshift e.message
        console.error e.message

    await setTimeout defer(), 100

exports.init = (cb)->
  cb null

getPythonBin = (cb)->
  await exec 'which python2', cwd: workingDirectory, defer e
  return cb null, 'python2' unless e
  await exec 'python --version', cwd: workingDirectory, defer e, out, err
  return cb e if e
  return cb new Error "invalid Python version: #{err}. (Python 2.x needed)" unless err.match /Python[\s]+2\./
  return cb null, 'python'


queue.tasks = 
  retrieve: (task)->
    queue.append 
      name: "取回 #{task.id}"
      func: (cb)->
        await getPythonBin defer e, pyothon_bin
        return cb e if e
        stats.retrieving = spawn pyothon_bin, [cli, 'download', '--continue', '--no-hash', task.id], stdio: 'pipe', cwd: workingDirectory
        errBuffer = []
        stats.retrieving.task = task
        new lazy(stats.retrieving.stderr).lines.forEach (line)->
          line ?= []
          line = line.toString 'utf8'
          errBuffer.push line
          line = line.match /\s+(\d?\d%)\s+([^ ]{1,10})\s+([^ ]{1,10})\r?\n?$/
          [dummy, stats.progress, stats.speed, stats.time] = line if line

        await stats.retrieving.on 'exit', defer e
        if e
          stats.error[task.id] = errBuffer.join ''
        stats.retrieving = null
        queue.tasks.updateTasklist()
        queue.tasks.deleteTask(task.id)
        cb()
  

  updateTasklist: ->
    queue.prepend
      name: '刷新任务列表'
      func: (cb)->
        await getPythonBin defer e, pyothon_bin
        return cb e if e
        await exec "#{pyothon_bin} #{cli} config encoding utf-8", cwd: workingDirectory, defer e
        return cb e if e
        await exec "#{pyothon_bin} #{cli} list --no-colors", cwd: workingDirectory, defer e, out, err
        if e && err.match /user is not logged in|Verification code required/
          stats.requireLogin = true
          return cb e
        return cb e if e
        _tasks = []
        if out.match regexMG 
          for task in out.match regexMG
            task = task.match regexQ
            _tasks.push
              id: task[1]
              filename: task[2]
              status: statusMap[task[3]]
              statusLabel: statusMapLabel[task[3]]

        stats.tasks = _tasks
        
        for task in _tasks
          if task.status=='success' && !stats.error[task.id]?
            queue.tasks.retrieve task
        cb()
  deleteTask: (id)->
    queue.prepend
      name: "删除任务 #{id}"
      func: (cb)->
        await getPythonBin defer e, pyothon_bin
        return cb e if e
        await exec "#{pyothon_bin} #{cli} delete #{id}", cwd: workingDirectory, defer e, out, err
        return cb e if e
        queue.tasks.updateTasklist()
        cb null

  login: (username, password, vcode, cb)->
    await getPythonBin defer e, pyothon_bin
    return cb e if e
    console.log vcode
    if vcode
      await exec "#{pyothon_bin} #{cli} login #{username} #{password} --verification-code-input=#{vcode}", cwd: workingDirectory, defer e, out, err
    else
      await exec "#{pyothon_bin} #{cli} login #{username} #{password} --verification-code-path .lixian-portal-vcode.jpg --verification-code-input-later", cwd: workingDirectory, defer e, out, err
      console.log out
      if e && out.match /--verification-code-input/
        await fs.readFile (path.join workingDirectory, ".lixian-portal-vcode.jpg"), defer e, stats.requireVerificationCode
        return cb e if e
        stats.requireVerificationCode = stats.requireVerificationCode.toString 'base64'
        stats.username = username
        stats.password = password
        return cb null
    if e
      stats.requireVerificationCode = null
      stats.username = ''
      stats.password = ''
      return cb new Error '登录失败'

    stats.requireLogin = false
    stats.requireVerificationCode = null
    stats.password = ''
    stats.username = ''
    queue.tasks.updateTasklist()
    cb null
        
  logout: (username, password)->
    queue.append
      name: "登出"
      func: (cb)->
        await getPythonBin defer e, pyothon_bin
        return cb e if e
        await exec "#{pyothon_bin} #{cli} logout", cwd: workingDirectory, defer e, out, err
        queue.tasks.updateTasklist()
        cb null

  addBtTask: (filename, torrent)->
    queue.append
      name: "添加bt任务 #{filename}"
      func: (cb)->
        await getPythonBin defer e, pyothon_bin
        return cb e if e
        await exec "#{pyothon_bin} #{cli} add #{torrent}", cwd: workingDirectory, defer e, out, err
        return cb e if e
        queue.tasks.updateTasklist()
        cb null
  addTask: (url)->
    queue.append
      name: "添加任务 #{url}"
      func: (cb)->
        await getPythonBin defer e, pyothon_bin
        return cb e if e
        await exec "#{pyothon_bin} #{cli} add \"#{url}\"", cwd: workingDirectory, defer e, out, err
        return cb e if e
        queue.tasks.updateTasklist()
        cb null


