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

Object::tap = (f) ->
  f.call @
  @

# If the specs below fails with timeout. It's a bad signal.
# Some of the expectations are failing, not timing out
# Strange behaviour. Might have to do with Q.


describe 'Importer', ->
  createDirectory = '/tmp/data/create'

  entry = null

  spies =
    gm: null
    findit: null
    mkdirp: null
    gm_identify: null
    gm_save: null

  beforeEach ->
    entry = new Entry().tap ->
       @time = new Date
       @basepath = createDirectory

    spies.gm_identify = chai.spy 'gm-identify', (cb) -> cb null, { exif: true }
    spies.gm_save = chai.spy 'gm-save', (path, cb) -> cb null
    spies.gm_resize = (w, h) -> gmObject
    spies.mkdirp = chai.spy 'mkdirp', (path, cb) -> cb null
    spies.writeFile = chai.spy 'writeFile', (path, data, cb) -> cb null
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
      Importer.import entry, '/tmp/data', (err) ->
        spies.mkdirp.should.have.been.called.once
        spies.mkdirp.__spy.calls[0][0].should.equal '/tmp/data/2012/02/28/wonderboy'
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
        spies.gm_save.should.have.been.called.exactly 6 # times

        base = '/tmp/data/2012/06/06/miliam/miliam1'
        expect(spies.gm_save.__spy.calls[0][0]).to.equal base + ".w320.jpg"
        expect(spies.gm_save.__spy.calls[1][0]).to.equal base + ".w640.jpg"
        expect(spies.gm_save.__spy.calls[2][0]).to.equal base + ".w950.jpg"

        base = '/tmp/data/2012/06/06/miliam/miliam2'
        expect(spies.gm_save.__spy.calls[3][0]).to.equal base + ".w320.jpg"
        expect(spies.gm_save.__spy.calls[4][0]).to.equal base + ".w640.jpg"
        expect(spies.gm_save.__spy.calls[5][0]).to.equal base + ".w950.jpg"

        done()

    it "should update entry with new image paths"
    it "should move original image"

    it "should write meta data into info.txt", (done) ->
      entry.time = new Date("2012-06-06T19:31:00+0200")
      entry.title = "I am a boy"

      Importer.import entry, null, (err) ->
        expect(err).to.be.null
        spies.writeFile.should.have.been.called.once
        expect(spies.writeFile.__spy.calls[0][0]).to.equal '/tmp/data/2012/06/06/i-am-a-boy/info.txt'
        expect(spies.writeFile.__spy.calls[0][1]).to.equal entry.serialize()
        done()


###
  # describe "#load", ->
  #   it "have a load method", ->
  #     Importer.should.have.a.property 'load'
  #     Importer.load.should.be.an.instanceof Function
  #
  #   it 'results in an error if no path param', (done) ->
  #     Importer.load '', (err, entry) ->
  #       expect(err).to.be.an.instanceof ArgumentError
  #       done()
  #
  #   describe "with title only info.txt file", ->
  #     cp = require 'child_process'
  #     # execOriginal = cp.exec
  #     infospy = execspy = null
  #     beforeEach ->
  #       infospy = spyfs.on '/tmp/new/info.txt', 'title: Miliam'
  #       # execspy = cp.exec = chai.spy (str, callback) ->
  #       #   if /^find .*jpg/.test str
  #       #     callback null, "/tmp/new/glenn.jpg\n/tmp/new/sigyn.jpg\n"
  #       #   else if /^\/usr\/local\/bin\/gm .*echo '(.*?)'$/.test str
  #       #     callback null, RegExp.$1
  #       #   else
  #       #     expect(str).to.equal 'something else...'
  #
  #
  #     afterEach ->
  #       # revert mock
  #       # cp.exec = execOriginal
  #
  #     it "should load an entry with a valid path", (done) ->
  #       Importer.load infospy.dirname, (err, entry) ->
  #         expect(err).to.be.null
  #         expect(entry).to.not.be.null
  #         entry.should.have.property 'basepath', infospy.dirname
  #         done()
  #



  describe "#import", ->
    Entry = require '../lib/entry'
    mkdirp_spy = entry = null
    originalWriteFile = fs.writeFile

    beforeEach ->
      entry = new Entry
      entry.title = "Miliam går på tå"
      entry.time = new Date 2012, 4, 7, 1, 0, 0
      entry.text = "Text 1\nText 2\nText 3"
      # entry.images = []
      # entry.images.push
      #   original: "/tmp/new/image1.jpg"
      #   w320:     "/tmp/new/image1.w320.jpg"
      #   w640:     "/tmp/new/image1.w640.jpg"
      #   w1024:    "/tmp/new/image1.w1024.jpg"
      # entry.images.push
      #   original: "/tmp/new/image2.jpg"
      #   w320:     "/tmp/new/image2.w320.jpg"
      #   w640:     "/tmp/new/image2.w640.jpg"
      #   w1024:    "/tmp/new/image2.w1024.jpg"
      mockery.enable()
      mockery.registerAllowable 'slug'
      mockery.registerAllowable 'fs'

      mkdirp_spy = chai.spy (path, callback) ->
        expect(path).to.equal "/tmp/data/2012/05/07/miliam-gar-pa-ta"
        callback null if path

      mockery.registerMock 'mkdirp', mkdirp_spy


    afterEach ->
      mockery.deregisterAll()
      mockery.disable()

    it "should create folder based on date and title", (done) ->
      Importer.import entry, '/tmp/data', (err) ->
        mkdirp_spy.should.have.been.called.once
        done()

    it "should create a new info.txt based on updated entry", (done) ->
      entry.serialize = -> "BOGUS"
      originalRename = fs.rename
      fs.rename = chai.spy (path1, path2, callback) -> callback null
      fs.writeFile = chai.spy (path, data, encoding, callback) ->
        expect(path).to.equal "/tmp/data/2012/05/07/miliam-gar-pa-ta/info.txt"
        expect(data).to.equal 'BOGUS'
        expect(encoding).to.equal 'utf8'
        callback null if path

      Importer.import entry, '/tmp/data', (err) ->
        fs.writeFile.should.be.called.once
        fs.rename = originalRename
        fs.writeFile = originalWriteFile
        done()

    # it "should expose images in folder in entry", (done) ->
    #   Importer.load infospy.dirname, (err, entry) ->
    #     execspy.__spy.calls[0][0].should.include ' /tmp/new '
    #     expect(entry).to.have.a.property('images').and.is.an.instanceof Array
    #     entry.images.should.have.length 2
    #
    #     g =
    #       original: "/tmp/new/glenn.jpg"
    #       w320:     "/tmp/new/glenn.w320.jpg"
    #       w640:     "/tmp/new/glenn.w640.jpg"
    #       w1024:    "/tmp/new/glenn.w1024.jpg"
    #     s =
    #       original: "/tmp/new/sigyn.jpg"
    #       w320:     "/tmp/new/sigyn.w320.jpg"
    #       w640:     "/tmp/new/sigyn.w640.jpg"
    #       w1024:    "/tmp/new/sigyn.w1024.jpg"
    #
    #     entry.images.should.deep.equal [g, s]
    #
    #     done()
    #

    # it "should invoke graphicsmagick to generate all sizes for each image and save it in new path", (done) ->
    #   Importer.load infospy.dirname, (err, entry) ->
    #
    #     execspy.__spy.calls.should.have.length 7
    #
    #     i = 0
    #     for file in ['glenn', 'sigyn']
    #       for size in [320, 640, 1024]
    #         i++
    #         execspy.__spy.calls[i][0].should.include " -resize #{size}x#{size} "
    #         execspy.__spy.calls[i][0].should.include "#{file}.jpg"
    #         execspy.__spy.calls[i][0].should.include "echo '/tmp/new/#{file}.w#{size}.jpg'"
    #
    #     done()
    #
    # it "should move the image files to folder", (done) ->
    #   fs.writeFile = chai.spy (path, data, encoding, callback) -> callback null
    #   originalRename = fs.rename
    #   fs.rename = chai.spy (path1, path2, callback) -> callback null
    #
    #   Importer.import entry, '/tmp/data', (err) ->
    #     fs.rename.should.have.been.called.exactly 8 # times
    #
    #     expect(fs.rename.__spy.calls[0][0]).to.equal '/tmp/new/image1.jpg'
    #     expect(fs.rename.__spy.calls[1][0]).to.equal '/tmp/new/image1.w320.jpg'
    #     expect(fs.rename.__spy.calls[2][0]).to.equal '/tmp/new/image1.w640.jpg'
    #     expect(fs.rename.__spy.calls[3][0]).to.equal '/tmp/new/image1.w1024.jpg'
    #     # add original to first file
    #     expect(fs.rename.__spy.calls[0][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image1.original.jpg'
    #     expect(fs.rename.__spy.calls[1][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image1.w320.jpg'
    #     expect(fs.rename.__spy.calls[2][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image1.w640.jpg'
    #     expect(fs.rename.__spy.calls[3][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image1.w1024.jpg'
    #
    #     expect(fs.rename.__spy.calls[4][0]).to.equal '/tmp/new/image2.jpg'
    #     expect(fs.rename.__spy.calls[5][0]).to.equal '/tmp/new/image2.w320.jpg'
    #     expect(fs.rename.__spy.calls[6][0]).to.equal '/tmp/new/image2.w640.jpg'
    #     expect(fs.rename.__spy.calls[7][0]).to.equal '/tmp/new/image2.w1024.jpg'
    #     # add original to first file
    #     expect(fs.rename.__spy.calls[4][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image2.original.jpg'
    #     expect(fs.rename.__spy.calls[5][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image2.w320.jpg'
    #     expect(fs.rename.__spy.calls[6][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image2.w640.jpg'
    #     expect(fs.rename.__spy.calls[7][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image2.w1024.jpg'
    #
    #     fs.rename = originalRename
    #     fs.writeFile = originalWriteFile
    #     done()
    #
    # it "should not used generated images as a base for new generation"
    # it "should import images capture date if not specified in info.txt"
###