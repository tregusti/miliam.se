chai = require 'chai'
should = chai.should()
expect = chai.expect

mockery = require 'mockery'
# fs = require 'fs'

InvalidStateError = require '../../lib/errors/invalidstate'
# spyfs = require './../helpers/spy-fs'

Entry = require '../../lib/entry'
Importer = require '../../lib/importer'
# Path = require 'path'
# util = require 'util'


describe "Importer", ->

  spies = new Object
  _import = Importer.import

  beforeEach ->
    Importer.import   = chai.spy 'Importer.import'
    # spies.mkdirp    = chai.spy 'mkdirp',        (path, cb)                -> setTimeout (-> cb null), 10
    # spies.writeFile = chai.spy 'fs-writeFile',  (path, data, cb)          -> setTimeout (-> cb null), 10
    spies.findit      =
      find: ->
        EventEmitter = require('events').EventEmitter
        ee = new EventEmitter
        process.nextTick ->
          ee.emit 'file', file for file in spies.findit._files
          ee.emit 'directory', dir for dir in spies.findit._dirs
          ee.emit 'end'
        ee

      _files: []
      _dirs: []
      dir: (dir) -> @_dirs.push dir
      file: (file) -> @_files.push file
      name: 'findit'
    mockery.registerAllowable 'events'
    # mockery.registerAllowable 'slug'
    # mockery.registerMock 'mkdirp', spies.mkdirp
    mockery.registerMock 'findit', spies.findit
    # mockery.registerMock 'fs',
    #   writeFile: spies.writeFile
    #   rename: spies.rename

    mockery.enable()

  afterEach ->
    Importer.import = _import
    mockery.deregisterAll()
    mockery.disable()


  describe "#check", ->
    it "exists", ->
      Importer.should.respondTo 'check'

    it "should give an entry if 'ok' folder is present", (done) ->
      spies.findit.dir config.get('paths:create') + '/ok'
      Importer.check (err, entry) ->
        expect(err).to.be.null
        expect(entry).to.be.an.instanceof Entry
        done()

    it "should give an entry if 'OK' folder is present", (done) ->
      spies.findit.dir config.get('paths:create') + '/OK'
      Importer.check (err, entry) ->
        expect(err).to.be.null
        expect(entry).to.be.an.instanceof Entry
        done()

    it "should give an entry if 'Ok' folder is present", (done) ->
      spies.findit.dir config.get('paths:create') + '/Ok'
      Importer.check (err, entry) ->
        expect(err).to.be.null
        expect(entry).to.be.an.instanceof Entry
        done()

    it "should give an error if 'ok' folder is missing", (done) ->
      Importer.check (err, entry) ->
        expect(err).to.be.an.instanceof InvalidStateError
        expect(entry).to.be.null
        done()