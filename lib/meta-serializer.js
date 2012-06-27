var contains = function(a, o) {
  return a.indexOf(o) >= 0;
}

var deserialize = function(entry, contents) {
  var meta = contents
              .split('\n\n')[0] // upper part
              .trim()           // remove whitespace
              .split('\n')      // Split into separate lines
              .reduce(function(meta, line) {  // iterate all lines
                var m = line.match(/^(\w+):\s*(.*)$/); // Find valid key:value pair
                if (m) meta[m[1]] = m[2]; // Add it to meta object
                return meta
              }, {});

  if (meta.hasOwnProperty('title')) entry.title = meta.title;
  // if (meta.hasOwnProperty('time')) {
  //   var s =
  //   entry.title = meta.title;
  // }
}

//
// var date = meta.date.split('-');
// var time = meta.time.split(':');
//
// if (date.length != 3 || time.length != 3) throw "Blä"
// s = sprintf('%4s-%2s-%2sT%2s:%2s:%2s', date[0], date[1], date[2], time[0] || 0, time[1] || 0, time[2] || 0)
//
// var body = info.split('\n\n')[1].trim();
//
// return {
//   body: body,
//   title: meta.title,
//   date: new Date(dateutils.ISOStringInSweden(s))
//
//


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