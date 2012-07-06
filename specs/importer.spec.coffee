chai = require 'chai'
should = chai.should()
expect = chai.expect

ArgumentError = require '../lib/errors/argument'
spyfs = require './helpers/spy-fs'

Importer = require '../lib/importer'

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
            callback null, "/tmp/new/glenn.jpg\n/tmp/new/sigyn.jpg"
          else if /^\/usr\/local\/bin\/gm .*echo '(.*?)'$/.test str
            callback null, RegExp.$1
          else
            expect(str).to.equal 'something else...'


      afterEach ->
        # revert mock
        cp.exec = original

      # If the specs below fails with timeout. It's a bad signal.
      # Some of the expectations are failing, not timing out
      # Strange behaviour. Might have to do with Q.

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