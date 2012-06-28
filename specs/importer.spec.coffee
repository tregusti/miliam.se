chai = require 'chai'
should = chai.should()
expect = chai.expect

ArgumentError = require '../lib/errors/argument'

Importer = require '../lib/importer'

describe 'Importer', ->
  it 'should exist', ->
    expect(Importer).to.be.defined
  it 'requires a path param', ->
    (-> new Importer).should.throw ArgumentError
    (-> new Importer '').should.throw ArgumentError
    (-> new Importer '/tmp').should.not.throw

