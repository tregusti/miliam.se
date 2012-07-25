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

  spies   = new Object
  _import = Importer.import

  beforeEach ->
    Importer.import   = chai.spy 'Importer.import'
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
    mockery.registerMock 'findit', spies.findit

    mockery.enable()

  afterEach ->
    Importer.import = _import
    mockery.deregisterAll()
    mockery.disable()


  describe "#check", ->
    it "exists", ->
      Importer.should.respondTo 'check'

    it "should not give an error if 'ok' folder is present", (done) ->
      spies.findit.dir config.get('paths:create') + '/ok'
      Importer.check (err) ->
        expect(err).to.be.null
        done()

    it "should not give an error if 'OK' folder is present", (done) ->
      spies.findit.dir config.get('paths:create') + '/OK'
      Importer.check (err) ->
        expect(err).to.be.null
        done()

    it "should not give an error if 'Ok' folder is present", (done) ->
      spies.findit.dir config.get('paths:create') + '/Ok'
      Importer.check (err) ->
        expect(err).to.be.null
        done()

    it "should give an error if 'ok' folder is missing", (done) ->
      Importer.check (err) ->
        expect(err).to.be.an.instanceof InvalidStateError
        done()
