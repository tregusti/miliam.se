pluralize = (entity, count) ->
  switch entity
    when 'år'
      'år'
    when 'månad'
      if count > 1 then 'månader' else 'månad'
    when 'dag'
      if count > 1 then 'dagar' else 'dag'

since = (date) ->
  years = months = 0
  days = date.getDaysBetween new Date
  while days > 366
    years++
    count = date.getDaysBetween new Date().addYears(-years)
  while days > 28
    months++
    days = date.getDaysBetween new Date().addMonths -months

  a = []
  if years
    entity = pluralize 'år', months
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