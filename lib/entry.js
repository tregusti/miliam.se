var NotFoundError = require('./errors').NotFoundError;
var ArgumentError = require('./errors').ArgumentError;
var EntryError = require('./errors').EntryError;

var Path = require('path');
var Observable = require('observables').Observable;

var Entry = function(path) {
  Observable.call(this);
};
Entry.prototype = new Observable;

exports.Entry = Entry

/*

Entry.paths = function(base) {
  return {
    info: Path.join(base, 'info.txt')
  }
}


Entry.load = function(path, callback) {
  if (!path) return callback(new ArgumentError('path'), null);

  Path.exists(path, function(exists) {
    if (!exists) return callback(new NotFoundError(path), null);

    var paths = Entry.paths(path)

    Path.exists(paths.info, function(exists) {
      if (!exists) return callback(new EntryError(path), null);

      var entry = new Entry(paths);
      callback(null, entry);
      // entry.on('load', function() {
      //   callback(null, this);
      // })
      // entry.on('error', function(err) {
      //   callback(new EntryError(path), null);
      // })
    });
  });
};

exports.Entry = Entry

/*
var fs = require('fs');
var path = require('path');
var sprintf = require('sprintf').sprintf;
var dateutils = require('./date-util');
var im = require('imagemagick');

const DATA_ROOT = path.resolve(path.join(__dirname, '..', 'data'));

function load(year, month, slug, done) {
  var base = path.join(DATA_ROOT, year, month, slug);
  var paths = {
    info: path.join(base, 'info.txt'),
    thumbnail: path.join(base, 'thumbnail.jpg'),
    picture: path.join(base, 'picture.jpg'),
    original: path.join(base, 'original.jpg')
  }
  path.exists(paths.info, function (exists) {
    if (!exists) return done(null);

    fs.readFile(paths.info, 'utf8', function(err, content) {
      if (err) done(null); // TODO: better error handling

      var info = parseInfo(content);
      path.exists(paths.original, function(exists) {
        if (!exists)
        var image = im.identify(paths.original, function(err, features) {
          if (err) throw err;
          console.dir(features)
          done(features)
        });
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
    date: new Date(dateutils.ISOStringInSweden(s))
  }
}

exports.load = load;
*/