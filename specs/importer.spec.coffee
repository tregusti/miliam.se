chai = require 'chai'
should = chai.should()
expect = chai.expect

mockery = require 'mockery'
fs = require 'fs'

ArgumentError = require '../lib/errors/argument'
spyfs = require './helpers/spy-fs'

Importer = require '../lib/importer'

# If the specs below fails with timeout. It's a bad signal.
# Some of the expectations are failing, not timing out
# Strange behaviour. Might have to do with Q.


describe 'Importer', ->
  afterEach ->
    spyfs.off()

  it 'should exist', ->
    expect(Importer).to.be.defined

  describe "#load", ->
    it "have a load method", ->
      Importer.should.have.a.property 'load'
      Importer.load.should.be.an.instanceof Function

    it 'results in an error if no path param', (done) ->
      Importer.load '', (err, entry) ->
        expect(err).to.be.an.instanceof ArgumentError
        done()

    describe "with title only info.txt file", ->
      cp = require 'child_process'
      original = cp.exec
      spy = null
      beforeEach ->
        spy = spyfs.on '/tmp/new/info.txt', 'title: Miliam'
        cp.exec = chai.spy (str, callback) ->
          if /^find .*jpg/.test str
            callback null, "/tmp/new/glenn.jpg\n/tmp/new/sigyn.jpg\n"
          else if /^\/usr\/local\/bin\/gm .*echo '(.*?)'$/.test str
            callback null, RegExp.$1
          else
            expect(str).to.equal 'something else...'


      afterEach ->
        # revert mock
        cp.exec = original

      it "should load an entry with a valid path", (done) ->
        Importer.load spy.dirname, (err, entry) ->
          expect(err).to.be.null
          expect(entry).to.not.be.null
          entry.should.have.property 'basepath', spy.dirname
          done()

      it "should invoke graphicsmagick to generate all sizes for each image", (done) ->
        Importer.load spy.dirname, (err, entry) ->

          cp.exec.__spy.calls.should.have.length 7

          i = 0
          for file in ['glenn', 'sigyn']
            for size in [320, 640, 1024]
              i++
              cp.exec.__spy.calls[i][0].should.include " -resize #{size}x#{size} "
              cp.exec.__spy.calls[i][0].should.include "#{file}.jpg"
              cp.exec.__spy.calls[i][0].should.include "echo '/tmp/new/#{file}.w#{size}.jpg'"

          done()


      it "should expose images in folder in entry", (done) ->
        Importer.load spy.dirname, (err, entry) ->
          cp.exec.__spy.calls[0][0].should.include ' /tmp/new '
          expect(entry).to.have.a.property('images').and.is.an.instanceof Array
          entry.images.should.have.length 2

          g =
            w320:  "/tmp/new/glenn.w320.jpg"
            w640:  "/tmp/new/glenn.w640.jpg"
            w1024: "/tmp/new/glenn.w1024.jpg"
          s =
            w320:  "/tmp/new/sigyn.w320.jpg"
            w640:  "/tmp/new/sigyn.w640.jpg"
            w1024: "/tmp/new/sigyn.w1024.jpg"

          entry.images.should.deep.equal [g, s]

          done()

  describe "move pickup contents", ->
    Entry = require '../lib/entry'
    mkdirp_spy = entry = null
    originalWriteFile = fs.writeFile

    beforeEach ->
      entry = new Entry
      entry.title = "Miliam går på tå"
      entry.time = new Date 2012, 4, 7, 1, 0, 0
      entry.text = "Text 1\nText 2\nText 3"
      entry.images = []
      entry.images.push
        w320:  "/tmp/new/image1.w320.jpg"
        w640:  "/tmp/new/image1.w640.jpg"
        w1024: "/tmp/new/image1.w1024.jpg"
      entry.images.push
        w320:  "/tmp/new/image2.w320.jpg"
        w640:  "/tmp/new/image2.w640.jpg"
        w1024: "/tmp/new/image2.w1024.jpg"
      mockery.enable()
      mockery.registerAllowable 'slug'

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

    it "should move the image files to new folder", (done) ->
      fs.writeFile = chai.spy (path, data, encoding, callback) -> callback null
      originalRename = fs.rename
      fs.rename = chai.spy (path1, path2, callback) -> callback null

      Importer.import entry, '/tmp/data', (err) ->
        fs.rename.should.have.been.called.exactly 6 # times

        expect(fs.rename.__spy.calls[0][0]).to.equal '/tmp/new/image1.w320.jpg'
        expect(fs.rename.__spy.calls[1][0]).to.equal '/tmp/new/image1.w640.jpg'
        expect(fs.rename.__spy.calls[2][0]).to.equal '/tmp/new/image1.w1024.jpg'
        expect(fs.rename.__spy.calls[0][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image1.w320.jpg'
        expect(fs.rename.__spy.calls[1][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image1.w640.jpg'
        expect(fs.rename.__spy.calls[2][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image1.w1024.jpg'

        expect(fs.rename.__spy.calls[3][0]).to.equal '/tmp/new/image2.w320.jpg'
        expect(fs.rename.__spy.calls[4][0]).to.equal '/tmp/new/image2.w640.jpg'
        expect(fs.rename.__spy.calls[5][0]).to.equal '/tmp/new/image2.w1024.jpg'
        expect(fs.rename.__spy.calls[3][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image2.w320.jpg'
        expect(fs.rename.__spy.calls[4][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image2.w640.jpg'
        expect(fs.rename.__spy.calls[5][1]).to.equal '/tmp/data/2012/05/07/miliam-gar-pa-ta/image2.w1024.jpg'

        fs.rename = originalRename
        fs.writeFile = originalWriteFile
        done()