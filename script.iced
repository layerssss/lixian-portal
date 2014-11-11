await $ defer()
$modal = $("form.vcode-template").modal(show: false)
img = $modal.find("img")[0]
$modal.on "submit", (ev) ->
  ev.preventDefault()
  $.post "vcode", $modal.serialize()
  return
 
fmt_size = (size)->
  k = 1000
  m = 1000 * k
  g = 1000 * m
  return "#{(size / g).toFixed(2)}GB" if size > g
  return "#{(size / m).toFixed(2)}MB" if size > m
  return "#{Math.floor size / k}KB" if size > k
  "#{Math.floor size}B"
fmt_time = (time)->
  m = 60
  h = 60 * m
  d = h * 24
  return "#{Math.floor time / d}天#{fmt_time time % d}" if time > d
  return "#{Math.floor time / h}小时#{fmt_time time % h}" if time > h
  return "#{Math.floor time / m}分#{fmt_time time % m}" if time > m
  "#{Math.floor time}秒"

$.fn.text_update = (text)->
  return @ unless text !=$(@).text()
  return @text(text)
while true
  await $.get("stats.json").done defer data
  if data.vcode?.length
    $modal.modal "show"  unless $modal.is(":visible")
    unless img.src is data.vcode
      img.src = data.vcode
      $modal.find("input").val ""
  else
    $modal.modal "hide"  if $modal.is(":visible")
  if $('#accordion-log').length
    $("#queue").html $("#queue", data).html()
    $("#log").html $("#log", data).html()
  if $('#tasks').length
    task_template = $('#task_template').html()
    file_template = $('#file_template').html()
    tasks = d3.select('#tasks')
      .selectAll('.task')
      .data data.tasks, (task)-> task.id
    tasks.enter()
      .append('div')
      .classed('task', true)
      .html task_template
    tasks.exit().each -> $(@).fadeOut -> $(@).remove()
    tasks.each (task, i)->
      $(@).find('.task-name').text_update task.name
      $(@).find('.task-delete').attr href: "/tasks/#{task.id}?_method=delete"
      $(@).find('.task-toggler').attr href: "#task#{task.id}"
      $(@).find('.task-togglee').attr id: "task#{task.id}"
      $(@).find('.task-progressbar')
        .css('width': "#{task.progress}%")
        .removeClass('active progress-bar-striped')

      files = d3.select($(@).find('.task-files')[0])
        .selectAll('.file')
        .data task.files, (file)-> file.name
      files.enter()
        .append('div')
        .classed('file', true)
        .html file_template 
      files.exit().each -> $(@).remove()
      files.each (file, i)->
        $(@).find('.file-name').text_update file.name
        $(@).find('.file-size').text_update fmt_size file.size
        if file.retrieving && data.progress?
          $(@).find('.file-status').text_update "已取回#{fmt_size data.progress.fetched}；预计剩余#{fmt_time data.progress.eta}"
          $(@).find('.file-progressbar')
            .css(width: "#{100 * data.progress.progress}%")
            .addClass('active progress-bar-striped')
            .text_update("#{Math.floor 100 * data.progress.progress}%")
            .parent()
            .removeClass('notready')
          $(@).closest('.task').find('.task-progressbar').addClass('active progress-bar-striped')
        else if file.finished
          $(@).find('.file-status').text_update '已取回本地'
          $(@).find('.file-progressbar')
            .css(width: '100%')
            .text_update('')
            .removeClass('active progress-bar-striped')
            .parent()
            .removeClass('notready')
        else if file.url
          $(@).find('.file-progressbar')
            .text_update('')
          $(@).find('.file-status').text_update "等待取回"
        else
          $(@).find('.file-status').text_update "未就绪"
          $(@).find('.file-progressbar')
            .parent()
            .addClass('notready')

  $('.executings').empty()
  for executing in data.executings
    $(document.createElement 'li')
    .text(executing)
    .appendTo('.executings')
  if data?.progress
    $('#stats .speed').stop().fadeIn().text("#{fmt_size data.progress.speed}/s")
  else
    $('#stats .speed').stop().fadeOut()
  await setTimeout defer(), 500
