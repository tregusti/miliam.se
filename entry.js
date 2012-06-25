var fs = require('fs');
var path = require('path');
var sprintf = require('sprintf').sprintf;
var dateutils = require('./lib/date-util');

const DATA_ROOT = path.resolve(path.join(__dirname, '..', 'data'));

function load(year, month, slug, done) {
  var base = path.join(DATA_ROOT, year, month, slug);
  var paths = {
    info: path.join(base, 'info.txt'),
    thumb: path.join(base, 'thumb.jpg')
  }
  path.exists(paths.info, function (exists) {
    if (!exists) return done(null);

    fs.readFile(paths.info, 'utf8', function(err, content) {
      if (err) done(null); // TODO: better error handling

      var info = parseInfo(content);

      done({
        status: 200,
        info: info
      })
    })
  });
}

function parseInfo(info) {
  var m, meta = {};
  info.split('\n\n')[0].trim().split('\n').forEach(function(line) {
    if (m = line.match(/^(\w+):\s*(.*)$/))
      meta[m[1]] = m[2];
  })

  var date = meta.date.split('-');
  var time = meta.time.split(':');

  if (date.length != 3 || time.length != 3) throw "Blä"
  s = sprintf('%4s-%2s-%2sT%2s:%2s:%2s', date[0], date[1], date[2], time[0] || 0, time[1] || 0, time[2] || 0)

  var body = info.split('\n\n')[1].trim();

  return {
    body: body,
    title: meta.title,
    date: dateutils.ISOStringInSweden(s)
  }
}

exports.load = load;