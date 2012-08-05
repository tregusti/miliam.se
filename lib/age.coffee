require 'date-utils'

BIRTH = '2012-06-06 00:00:00'

pluralize = (entity, count) ->
  switch entity
    when 'år'
      'år'
    when 'månad'
      if count > 1 then 'månader' else 'månad'
    when 'dag'
      if count > 1 then 'dagar' else 'dag'

since = (date) ->
  # resets
  years = months = 0
  now = new Date

  # years
  years++ while date.isBefore now.clone().addYears(-years - 1).addDays(1)
  date = date.addYears years

  # months
  months++ while date.isBefore now.clone().addMonths(-months - 1).addDays(1)
  date = date.addMonths months

  days = date.getDaysBetween now.clone()

  a = []
  if years
    entity = pluralize 'år', years
    a.push "#{years} #{entity}"

  if months
    entity = pluralize 'månad', months
    a.push "#{months} #{entity}"

  if days
    entity = pluralize 'dag', days
    a.push "#{days} #{entity}"

  s = a.shift()
  s += ", #{a.shift()}" while a.length > 1
  s += " och #{a.shift()}" if a.length
  s

module.exports.since = since

attach = (app) ->
  app.locals.use (req, res) ->
    res.locals.humanAge = since new Date BIRTH


module.exports.birth = BIRTH # should not be exposed
module.exports.attach = attach