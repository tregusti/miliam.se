chai = require 'chai'
should = chai.should()
expect = chai.expect

ArgumentError = require '../lib/errors/argument'

Importer = require '../lib/importer'

spyfs = require './helpers/spy-fs'

describe 'Importer', ->
  afterEach ->
    spyfs.off()

  it 'should exist', ->
    expect(Importer).to.be.defined
  it 'requires a path param', ->
    (-> new Importer).should.throw ArgumentError
    (-> new Importer '').should.throw ArgumentError
    (-> new Importer '/tmp').should.not.throw

  describe '#entry', ->
    it 'should send an entry to callback', (done) ->
      spyfs.on '/tmp/entry/info.txt', "title: Hejsan\ntime: 10:00\n\nInnehåll"
      new Importer('/tmp/entry').entry (entry) ->
        entry.should.have.property 'title', 'Hejsan'
        entry.should.have.property 'text', 'Innehåll'
        done()