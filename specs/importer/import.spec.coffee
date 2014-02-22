chai = require 'chai'
should = chai.should()
expect = chai.expect

mockery = require 'mockery'
fs = require 'fs'

ArgumentError = require '../../lib/errors/argument'
spyfs = require './../helpers/spy-fs'
Generator = require "../../lib/importer/image-generator"

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
  originals = {}

  beforeEach ->
    entry = new Entry().tap ->
      @title = "Title"
      @time = new Date
      @basepath = createDirectory

    spies.imggen      = chai.spy 'image-generator', (path, outpath, cb)       -> process.nextTick -> cb null
    spies.gm_identify = chai.spy 'gm.identify',     (cb)                      -> process.nextTick -> cb null, exif: true
    spies.mkdirp      = chai.spy 'mkdirp',          (path, cb)                -> process.nextTick -> cb null
    spies.writeFile   = chai.spy 'fs.writeFile',    (path, data, cb)          -> process.nextTick -> cb null
    spies.rename      = chai.spy 'fs.rename',       (from, to, cb)            -> process.nextTick -> cb null
    spies.rmdir       = chai.spy 'fs.rmdir',        (path, cb)                -> process.nextTick -> cb null
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

    originals.imggen = Generator.generate
    Generator.generate = spies.imggen


    mockery.registerAllowable 'events'
    mockery.registerAllowable 'slug'
    mockery.registerMock './image-generator',
      generate: spies.imggen
    mockery.registerMock 'mkdirp', spies.mkdirp
    mockery.registerMock 'findit', spies.findit
    mockery.registerMock 'fs',
      writeFile:  spies.writeFile
      rename:     spies.rename
      rmdir:      spies.rmdir


    # Lazy props to make refs overridable in specs
    gmObject = {}
    Object.defineProperty gmObject, 'identify',   get: -> spies.gm_identify

    mockery.registerMock 'gm', (file) ->
      expect(file).to.match /\.jpg$/i
      gmObject

    mockery.enable()

  afterEach ->
    Generator.generate = originals.imggen

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
      file1 = "#{createDirectory}/miliam1.JPG"
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


    it "should invoke image generator", (done) ->
      # TODO: Remove this timeout. Way too long.
      @timeout 500

      spies.findit.add file = "#{createDirectory}/miliam1.jpg"

      entry.title = 'Oh boy'
      Importer.import entry, dataDirectory, (err) ->
        spies.imggen.should.have.been.called.once

        spies.imggen.__spy.calls[0][0].should.equal file
        spies.imggen.__spy.calls[0][1].should.equal entry.basepath

        done()

    it "should handle capital letter extensions", (done) ->
      # TODO: Remove this timeout. Way too long.
      @timeout 500

      spies.findit.add file = "#{createDirectory}/miliam1.JPg"

      entry.title = 'Oh boy'
      Importer.import entry, dataDirectory, (err) ->
        spies.imggen.should.have.been.called.once

        spies.imggen.__spy.calls[0][0].should.equal file
        spies.imggen.__spy.calls[0][1].should.equal entry.basepath

        done()



    it "should move original image", (done) ->
      file1 = "#{createDirectory}/cutie.jpg"
      spies.findit.add file1

      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "Cutie pie"

      Importer.import entry, null, (err) ->
        spies.rename.should.have.been.called.once

        expect(spies.rename.__spy.calls[0][0]).to.equal file1
        expect(spies.rename.__spy.calls[0][1]).to.equal Path.join dataDirectory, '2012/06/06/cutie-pie/cutie.jpg'

        expect(err).to.be.null
        done()



    it "should move original and lowercase filename", (done) ->
      file1 = "#{createDirectory}/Meat.JPG"
      spies.findit.add file1

      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "Meatloaf"

      Importer.import entry, null, (err) ->
        spies.rename.should.have.been.called.once

        expect(spies.rename.__spy.calls[0][0]).to.equal file1
        expect(spies.rename.__spy.calls[0][1]).to.equal Path.join dataDirectory, '2012/06/06/meatloaf/meat.jpg'

        expect(err).to.be.null
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
        expect(spies.writeFile.__spy.calls[1][1]).to.equal "title: Ändra mig\ndate: yyyy-mm-dd\ntime: hh:mm\ntype: post\n\nLite exempeltext. Brödtexten börjar 2 radbrytningar efter title etc ovanför."
        done()


    it "should remove 'ok' folder after import", (done) ->
      entry.title = 'Lige meget'
      entry.time = new Date('2012-02-28T14:14:14+0100')
      Importer.import entry, dataDirectory, (err) ->
        spies.rmdir.should.have.been.called.once
        spies.rmdir.__spy.calls[0][0].should.equal Path.join createDirectory, 'ok'
        done()

    it "should remove 'ok' folder when error importing", (done) ->
      entry.title = ""
      Importer.import entry, dataDirectory, (err) ->
        expect(err).to.not.equal null
        spies.rmdir.should.have.been.called.once
        spies.rmdir.__spy.calls[0][0].should.equal Path.join createDirectory, 'ok'
        done()