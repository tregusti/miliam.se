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
          expect(str).to.contain " /tmp/new "
          callback null, "/tmp/new/glenn.jpg\n/tmp/new/sigyn.jpg"

      afterEach ->
        # revert mock
        cp.exec = original

      it "should load an entry with a valid path", (done) ->
        Importer.load spy.dirname, (err, entry) ->
          expect(err).to.be.null
          expect(entry).to.not.be.null
          entry.should.have.property 'basepath', spy.dirname
          done()

      it "should expose images in folder in entry", (done) ->
        Importer.load spy.dirname, (err, entry) ->
          cp.exec.should.have.been.called.once
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