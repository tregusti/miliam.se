require 'date-utils'

BIRTH = '2012-06-07 00:00:00'

pluralize = (entity, count) ->
  switch entity
    when 'år'
      'år'
    when 'månad'
      if count > 1 then 'månader' else 'månad'
    when 'dag'
      if count > 1 then 'dagar' else 'dag'

days_between = (d1, d2) ->
  t = d1.clone().valueOf() - d2.clone().valueOf()
  Math.abs(t) / 86400000

between = (inStart, inEnd) ->
  start = inStart.clone()
  end = inEnd.clone()
  
  # resets
  years = months = 0

  # years
  years++ while start.isBefore end.clone().addYears(-years - 1).addDays(1)
  start = start.addYears years
  
  # months
  months++ while start.isBefore end.clone().addMonths(-months - 1).addDays(1)
  start = start.addMonths months

  days = days_between start, end

  a = []
  if years
    entity = pluralize 'år', years
    a.push "#{years} #{entity}"

  if months
    entity = pluralize 'månad', months
    a.push "#{months} #{entity}"

  days = days | 0 # math floor
  if days
    entity = pluralize 'dag', days
    a.push "#{days } #{entity}"

  s = a.shift()
  s += ", #{a.shift()}" while a.length > 1
  s += " och #{a.shift()}" if a.length
  s

since = (date) ->
  between date, new Date

attach = (app) ->
  app.locals.use (req, res) ->
    res.locals.humanAge = since new Date BIRTH



module.exports =
  between : between
  since   : since
  birth   : BIRTH # should not be exposed
  attach  : attach