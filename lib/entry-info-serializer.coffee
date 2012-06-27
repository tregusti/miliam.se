deserialize = (entry, contents) ->
  return unless contents
  meta = contents
            # upper part
            .split('\n\n')[0]
            # remove whitespace
            .trim()
            # Split into separate lines
            .split('\n')
            # iterate all lines
            .reduce ((meta, line) ->
              # Find valid key:value pair
              m = line.match /^(\w+):\s*(.*)$/
              # Add it to meta object
              meta[m[1]] = m[2] if m
              meta
            ), {}

  entry.title = meta.title if 'title' of meta
  entry.text = contents.split('\n\n')[1] || null

  if 'time' of meta
    if 'date' of meta
      today = meta.date
    else
      today = new Date().toISOString().substr(0,10)
    entry.time = new Date "#{today} #{meta.time}"
  else
    entry.time = new Date

module.exports.deserialize = deserialize;