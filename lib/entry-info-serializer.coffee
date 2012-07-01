deserialize = (entry, contents) ->
  return unless contents
  chunks = contents.split '\n\n'
  # throw new Error 'Invalid metadata format' unless chunks.length >= 2
  meta = chunks
            .shift()
            .split('\n')
            .reduce ((meta, line) ->
              m = line.match /^(\w+):\s*(.+)$/
              meta[m[1]] = m[2] if m
              meta), {}

  entry.text = chunks.join('\n\n') or null
  entry.title = meta.title if 'title' of meta

  if 'time' of meta
    if 'date' of meta
      today = meta.date
    else
      today = new Date().toISOString().substr(0,10)
    entry.time = new Date "#{today} #{meta.time}"
  else
    entry.time = null

module.exports.deserialize = deserialize;