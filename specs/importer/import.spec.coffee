chai = require 'chai'
should = chai.should()
expect = chai.expect

mockery = require 'mockery'
fs = require 'fs'

ArgumentError = require '../../lib/errors/argument'
spyfs = require './../helpers/spy-fs'

Importer = require '../../lib/importer'
Entry = require '../../lib/entry'
Path = require 'path'
util = require 'util'

Object::tap = (f) ->
  f.call @
  @

# If the specs below fails with timeout. It's a bad signal.
# Some of the expectations are failing, not timing out
# Strange behaviour. Might have to do with Q.


describe 'Importer', ->
  createDirectory = config.get 'paths:create'
  dataDirectory   = config.get 'paths:data'

  entry = null

  spies = {}

  beforeEach ->
    entry = new Entry().tap ->
       @time = new Date
       @basepath = createDirectory

    spies.gm_identify = chai.spy 'gm.identify',   (cb)                      -> setTimeout (-> cb null, { exif : true }), 10
    spies.gm_thumb    = chai.spy 'gm.thumb',      (w, h, out, quality, cb)  -> setTimeout (-> cb null), 10
    spies.mkdirp      = chai.spy 'mkdirp',        (path, cb)                -> setTimeout (-> cb null), 10
    spies.writeFile   = chai.spy 'fs.writeFile',  (path, data, cb)          -> setTimeout (-> cb null), 10
    spies.rename      = chai.spy 'fs.rename',     (from, to, cb)            -> setTimeout (-> cb null), 10
    spies.rmdir       = chai.spy 'fs.rmdir',      (path, cb)                -> setTimeout (-> cb null), 10
    spies.findit      =
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
      writeFile:  spies.writeFile
      rename:     spies.rename
      rmdir:      spies.rmdir


    # Lazy props to make refs overridable in specs
    gmObject = {}
    Object.defineProperty gmObject, 'identify', get: -> spies.gm_identify
    Object.defineProperty gmObject, 'thumb',    get: -> spies.gm_thumb

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
      Importer.import entry, dataDirectory, (err) ->
        spies.mkdirp.should.have.been.called.once
        spies.mkdirp.__spy.calls[0][0].should.equal Path.join dataDirectory, '2012/02/28/wonderboy'
        done()



    it "should generate images in new folder", (done) ->
      file1 = "#{createDirectory}/miliam1.jpg"
      file2 = "#{createDirectory}/miliam2.jpg"

      spies.findit.add file1
      spies.findit.add file2

      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "Miliam"

      Importer.import entry, null, (err) ->
        expect(err).to.be.null

        # Expect correct quality
        expect(spies.gm_thumb.__spy.calls[i][3]).to.equal 70 for i in [0..5]

        # Expect correct sizes
        expect(spies.gm_thumb.__spy.calls[i][0]).to.equal 320 for i in [0..5] by 3
        expect(spies.gm_thumb.__spy.calls[i+1][0]).to.equal 640 for i in [0..5] by 3
        expect(spies.gm_thumb.__spy.calls[i+2][0]).to.equal 960 for i in [0..5] by 3

        # expect correct output file
        base = Path.join dataDirectory, '2012/06/06/miliam/miliam1'
        expect(spies.gm_thumb.__spy.calls[0][2]).to.equal base + ".w320.jpg"
        expect(spies.gm_thumb.__spy.calls[1][2]).to.equal base + ".w640.jpg"
        expect(spies.gm_thumb.__spy.calls[2][2]).to.equal base + ".w960.jpg"

        base = Path.join dataDirectory, '2012/06/06/miliam/miliam2'
        expect(spies.gm_thumb.__spy.calls[3][2]).to.equal base + ".w320.jpg"
        expect(spies.gm_thumb.__spy.calls[4][2]).to.equal base + ".w640.jpg"
        expect(spies.gm_thumb.__spy.calls[5][2]).to.equal base + ".w960.jpg"

        done()



    it "should move original image", (done) ->
      file1 = "#{createDirectory}/cutie.jpg"
      spies.findit.add file1

      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "Cutie pie"

      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.rename.should.have.been.called.once

        expect(spies.rename.__spy.calls[0][0]).to.equal file1
        expect(spies.rename.__spy.calls[0][1]).to.equal Path.join dataDirectory, '2012/06/06/cutie-pie/cutie.jpg'

        done()




    it "should write meta data into info.txt", (done) ->
      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "I am a boy"

      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.writeFile.should.have.been.called.twice
        expect(spies.writeFile.__spy.calls[0][0]).to.equal dataDirectory + '/2012/06/06/i-am-a-boy/info.txt'
        expect(spies.writeFile.__spy.calls[0][1]).to.equal entry.serialize()
        done()



    it "should write a template info.txt when import was successful", (done) ->
      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "Whatever"

      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.writeFile.should.have.been.called.twice
        expect(spies.writeFile.__spy.calls[1][0]).to.equal createDirectory + '/info.txt'
        expect(spies.writeFile.__spy.calls[1][1]).to.equal "title: Ändra mig\n\nLite exempeltext. Brödtexten börjar 2 radbrytningar efter title etc ovanför."
        done()


    it "should remove 'ok' folder after import", (done) ->
      entry.title = 'Lige meget'
      entry.time = new Date('2012-02-28T14:14:14+0100')
      Importer.import entry, dataDirectory, (err) ->
        spies.rmdir.should.have.been.called.once
        spies.rmdir.__spy.calls[0][0].should.equal Path.join createDirectory, 'ok'
        done()