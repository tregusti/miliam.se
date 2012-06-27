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
  if 'time' of meta
  else
    entry.time = new Date



# //
# // var date = meta.date.split('-');
# // var time = meta.time.split(':');
# //
# // if (date.length != 3 || time.length != 3) throw "Blä"
# // s = sprintf('%4s-%2s-%2sT%2s:%2s:%2s', date[0], date[1], date[2], time[0] || 0, time[1] || 0, time[2] || 0)
# //
# // var body = info.split('\n\n')[1].trim();
# //
# // return {
# //   body: body,
# //   title: meta.title,
# //   date: new Date(dateutils.ISOStringInSweden(s))
# //
# //


module.exports.deserialize = deserialize;

###
/*

var meta = parseMeta(data);
entry.title = meta.title;
entry.date = new Date(meta.date)



function parseMeta(info) {
  var m, meta = {};
  info.split('\n\n')[0].trim().split('\n').forEach(function(line) {
    if (m = line.match(/^(\w+):\s*(.*)$/))
      meta[m[1]] = m[2];
  })
  return meta;
}