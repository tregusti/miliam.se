chai = require 'chai'
should = chai.should()
expect = chai.expect

mockery = require 'mockery'
fs = require 'fs'

ArgumentError = require '../lib/errors/argument'
spyfs = require './helpers/spy-fs'

Importer = require '../lib/importer'
Entry = require '../lib/entry'
Path = require 'path'
config = require '../lib/config'

p = config.get('paths')

Object::tap = (f) ->
  f.call @
  @

# If the specs below fails with timeout. It's a bad signal.
# Some of the expectations are failing, not timing out
# Strange behaviour. Might have to do with Q.


describe 'Importer', ->
  createDirectory = p.create

  entry = null

  spies = {}

  beforeEach ->
    entry = new Entry().tap ->
       @time = new Date
       @basepath = createDirectory

    spies.gm_identify = chai.spy 'gm-identify', (cb) -> cb null, { exif: true }
    spies.gm_save = chai.spy 'gm-save', (path, cb) -> cb null
    spies.gm_resize = (w, h) -> gmObject
    spies.mkdirp = chai.spy 'mkdirp', (path, cb) -> cb null
    spies.writeFile = chai.spy 'fs-writeFile', (path, data, cb) -> cb null
    spies.rename = chai.spy 'fs-rename', (from, to, cb) -> cb null
    spies.findit =
      find: ->
        EventEmitter = require('events').EventEmitter
        ee = new EventEmitter
        process.nextTick ->
          ee.emit 'file', file for file in spies.findit._files
          ee.emit 'end'
        ee

      _files: []
      add: (file) -> @_files.push file
      name: 'findit'
    mockery.registerAllowable 'events'
    mockery.registerAllowable 'slug'
    mockery.registerMock 'mkdirp', spies.mkdirp
    mockery.registerMock 'findit', spies.findit
    mockery.registerMock 'fs',
      writeFile: spies.writeFile
      rename: spies.rename


    # Lazy props to make refs overridable in specs
    gmObject = {}
    Object.defineProperty gmObject, 'identify', get: -> spies.gm_identify
    Object.defineProperty gmObject, 'write',    get: -> spies.gm_save
    Object.defineProperty gmObject, 'resize',   get: -> spies.gm_resize

    mockery.registerMock 'gm', (file) ->
      expect(file).to.match /\.jpg$/
      gmObject

    mockery.enable()

  afterEach ->
    mockery.deregisterAll()
    mockery.disable()
    # spyfs.off()

  it 'should exist', ->
    expect(Importer).to.be.defined

  describe "#import", ->


    it "should take an entry as param", ->
      (-> Importer.import null).should.throw ArgumentError
      (-> Importer.import true).should.throw ArgumentError
      (-> Importer.import {}).should.throw ArgumentError
      (-> Importer.import entry).should.not.throw Error



    it "should not read date from image when specified in info.txt", (done) ->
      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.gm_identify.should.not.have.been.called
        done()



    it "should import earliest image capture date if not specified in info.txt", (done) ->
      # These are the files we want to have in the dir
      file1 = "#{createDirectory}/miliam1.jpg"
      file2 = "#{createDirectory}/miliam2.jpg"

      spies.findit.add file1
      spies.findit.add file2
      filecounter = 0
      spies.gm_identify = chai.spy 'specific-identify', (callback) ->
        if ++filecounter is 1
          date = "2010:10:10 10:10:10"
        else if filecounter is 2
          date = "2011:11:11 11:11:11"

        expect(arguments).to.have.length 1
        returns =
          "Profile-EXIF":
            "Date Time Original": date
        callback null, returns

      entry.time = null

      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.gm_identify.should.have.been.called.exactly 2 # times
        expect(entry.time).to.not.be.null
        entry.time.toString().should.equal new Date("2010-10-10T10:10:10+0200").toString()
        done()



    it "should create folder based on date and title", (done) ->
      entry.title = 'Wonderboy'
      entry.time = new Date('2012-02-28T13:13:13+0100')
      Importer.import entry, config.get('paths:data'), (err) ->
        spies.mkdirp.should.have.been.called.once
        spies.mkdirp.__spy.calls[0][0].should.equal Path.join p.data, '2012/02/28/wonderboy'
        done()



    it "should generate images in new folder", (done) ->
      file1 = "#{config.get 'paths:create'}/miliam1.jpg"
      file2 = "#{config.get 'paths:create'}/miliam2.jpg"

      spies.findit.add file1
      spies.findit.add file2

      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "Miliam"

      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.gm_save.should.have.been.called.exactly 6 # times

        base = Path.join p.data, '2012/06/06/miliam/miliam1'
        expect(spies.gm_save.__spy.calls[0][0]).to.equal base + ".w320.jpg"
        expect(spies.gm_save.__spy.calls[1][0]).to.equal base + ".w640.jpg"
        expect(spies.gm_save.__spy.calls[2][0]).to.equal base + ".w960.jpg"

        base = Path.join p.data, '2012/06/06/miliam/miliam2'
        expect(spies.gm_save.__spy.calls[3][0]).to.equal base + ".w320.jpg"
        expect(spies.gm_save.__spy.calls[4][0]).to.equal base + ".w640.jpg"
        expect(spies.gm_save.__spy.calls[5][0]).to.equal base + ".w960.jpg"

        done()

    it "should update entry with new image paths"


    it "should move original image", (done) ->
      file1 = "#{p.create}/cutie.jpg"
      spies.findit.add file1

      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "Cutie pie"

      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.rename.should.have.been.called.once

        expect(spies.rename.__spy.calls[0][0]).to.equal Path.join p.create, 'cutie.jpg'
        expect(spies.rename.__spy.calls[0][1]).to.equal p.data + '/2012/06/06/cutie-pie/cutie.jpg'

        done()




    it "should write meta data into info.txt", (done) ->
      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "I am a boy"

      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.writeFile.should.have.been.called.once
        expect(spies.writeFile.__spy.calls[0][0]).to.equal p.data + '/2012/06/06/i-am-a-boy/info.txt'
        expect(spies.writeFile.__spy.calls[0][1]).to.equal entry.serialize()
        done()