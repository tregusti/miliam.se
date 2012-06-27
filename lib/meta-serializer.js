var deserialize = function(entry, contents) {

}

module.exports.deserialize = deserialize;

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
*/