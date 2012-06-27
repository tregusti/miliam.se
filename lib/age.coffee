since = (date) ->
  count = date.getDaysBetween new Date
  entity = if count > 1 then "dagar" else "dag"
  "#{count} #{entity}"

module.exports.since = since