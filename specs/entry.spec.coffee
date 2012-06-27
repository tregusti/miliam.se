# system modules
path = require 'path'

# spec helpers
chai = require 'chai'
should = chai.should()
expect = chai.expect
spies = require 'chai-spies'
chai.use spies

# own code
ArgumentError = require '../lib/errors/argument'


describe 'Entry class', ->

  Entry = require '../lib/entry'

  fixture = (slug) ->
    return path.join __dirname, 'fixtures', slug

  it 'should exist', ->
    expect(Entry).to.be.defined

  describe 'constructor', ->
    it 'should take 1 param', ->
      Entry.should.have.length 1
    it 'throws an error when path is undefined', ->
      (-> new Entry).should.throw ArgumentError
    it 'throws an error when path is empty', ->
      (-> new Entry '').should.throw ArgumentError

  describe 'observable', ->
    it 'should inherit from observable', ->
      expect(Entry.prototype.constructor.name).to.equal 'Observable'
    it 'should invoke observable constructor', ->
      expect(new Entry fixture 'only-text').to.have.property 'observableId'

  xdescribe 'with bad path', ->
    it 'triggers an error'

  describe 'with entry only-text', ->

    create = -> new Entry fixture 'only-text'

    it 'should not throw error', ->
      create.should.not.throw Error
    it 'should trigger load event', (done) ->
      create().on 'load', done

    describe 'when loaded', ->
      it 'should invoke MetaSerializer.deserialize', (done) ->
        MetaSerializer = require './../lib/meta-serializer'
        deserialize = MetaSerializer.deserialize
        MetaSerializer.deserialize = chai.spy ->
          arguments[0].should.be.an.instanceof Entry
          arguments[1].should.be.a 'string'
          deserialize.apply null, arguments

        subject = create()
        subject.on 'load', ->
          MetaSerializer.deserialize.should.have.been.called.once
          MetaSerializer.deserialize = deserialize
          done()