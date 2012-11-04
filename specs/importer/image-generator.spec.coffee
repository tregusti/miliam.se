chai = require 'chai'
should = chai.should()
expect = chai.expect

spies = require 'chai-spies'
chai.use spies

mockery = require 'mockery'

unless Number::times then Object.defineProperty Number::, 'times', get: -> @
unless Number::time then Object.defineProperty Number::, 'time', get: -> @


Path = require 'path'
require '../helpers/function.parameters'

imggen = require('../../lib/importer/image-generator').generate

datapath = config.get 'paths:data'

describe "Image generator", ->

  spies = {}

  beforeEach ->
    # define spies
    spies.gm_write    = chai.spy 'gm.write',       (path, cb) -> setTimeout (-> cb null), 10
    spies.gm_orient   = chai.spy 'gm.autoOrient',             -> this
    spies.gm_resize   = chai.spy 'gm.resize',                 -> this
    spies.gm_identify = chai.spy 'gm.identify',          (cb) -> setTimeout (-> cb null, { exif: true }), 10

    # define gm mock module
    gmMock = chai.spy 'gm', (file) ->
      expect(file).to.match /\.jpg$/
      gmObject
    gmObject = {}
    Object.defineProperty gmObject, 'toString',   get: -> -> "#{gmMock}"
    Object.defineProperty gmObject, 'identify',   get: -> spies.gm_identify
    Object.defineProperty gmObject, 'resize',     get: -> spies.gm_resize
    Object.defineProperty gmObject, 'write',      get: -> spies.gm_write
    Object.defineProperty gmObject, 'autoOrient', get: -> spies.gm_orient

    mockery.registerMock 'gm', gmMock
    mockery.enable()


  afterEach ->
    mockery.disable()
    mockery.deregisterMock 'gm'

  it "should be a function", ->
    imggen.should.be.an.instanceof Function

  it "should take a path, a outputpath and a callback", ->
    imggen.parameters.should.eql [ 'path', 'outpath', 'callback' ]

  it "gives an error if no path", (done) ->
    imggen null, 'hepp', (err) ->
      expect(err).to.not.be.null
      done()

  it "gives an error if no outpath", (done) ->
    imggen 'blah.jpg', null, (err) ->
      expect(err).to.not.be.null
      done()

  it "should auto rotate the image", (done) ->
    imggen '/tmp/path/image.jpg', '/tmp/data', ->
      spies.gm_orient.should.be.called.once
      done()

  it "should write the files out", (done) ->
    imggen '/tmp/path/image.jpg', '/tmp/data', ->
      spies.gm_write.should.be.called.exactly 3 # times

      spies.gm_write.__spy.calls[0][0].should.equal '/tmp/data/image.w320.jpg'
      spies.gm_write.__spy.calls[1][0].should.equal '/tmp/data/image.w640.jpg'
      spies.gm_write.__spy.calls[2][0].should.equal '/tmp/data/image.w960.jpg'

      done()

  it "resizes the image to a minimum width but no height", (done) ->
    imggen '/tmp/path/image.jpg', '/tmp/data', ->
      spies.gm_resize.should.be.called.exactly 3 # times

      spies.gm_resize.__spy.calls[0].should.eql [ 320, null, '^' ]
      spies.gm_resize.__spy.calls[1].should.eql [ 640, null, '^' ]
      spies.gm_resize.__spy.calls[2].should.eql [ 960, null, '^' ]

      done()