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
      expect(Entry.prototype.constructor.__super__.constructor.name).to.equal 'Observable'
    it 'should invoke observable constructor', ->
      expect(new Entry fixture 'only-text').to.have.property 'observableId'

  describe 'with entry only-text', ->

    it 'should not throw error', ->
      f = -> new Entry fixture 'only-text'
      f.should.not.throw Error
    it 'should trigger load event', (done) ->
      new Entry(fixture 'only-text').on 'load', done

    describe 'when loaded', ->
      it 'should invoke EntryInfoSerializer.deserialize', (done) ->
        EntryInfoSerializer = require './../lib/entry-info-serializer'
        deserialize = EntryInfoSerializer.deserialize
        EntryInfoSerializer.deserialize = chai.spy ->
          arguments[0].should.be.an.instanceof Entry
          arguments[1].should.be.a 'string'
          deserialize.apply null, arguments

        subject = new Entry fixture 'only-text'
        subject.on 'load', ->
          EntryInfoSerializer.deserialize.should.have.been.called.once
          EntryInfoSerializer.deserialize = deserialize
          done()

      describe 'human time', ->
        before (done) ->
          @subject = new Entry fixture 'only-text'
          @subject.on 'load', done
        it 'has a pretty date prop', ->
          @subject.should.have.property 'humanDate', "6 jun 2012"
        it 'has a pretty date prop', ->
          @subject.should.have.property 'humanTime', "10:14"
        it 'is readonly', ->
          @subject.humanTime = 'nope'
          @subject.humanDate = 'nope'
          @subject.should.have.property 'humanTime', "10:14"
          @subject.should.have.property 'humanDate', "6 jun 2012"
