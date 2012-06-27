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
    expect(Entry).toBeTruthy()

  describe 'constructor', ->
    it 'should take 1 param', ->
      expect(Entry.length).toBe 1
    it 'throws an error when path is undefined', ->
      (-> new Entry).should.throw ArgumentError
    it 'throws an error when path is empty', ->
      (-> new Entry '').should.throw ArgumentError

  describe 'observable', ->
    it 'should inherit from observable', ->
      expect(Entry.prototype.constructor.name).toBe 'Observable'
    it 'should invoke observable constructor', ->
      expect(new Entry fixture 'only-text').toDefine('observableId')

  xdescribe 'with bad path', ->
    it 'triggers an error'

  describe 'with entry only-text', ->

    create = -> new Entry fixture 'only-text'

    it 'should not throw error', ->
      create.should.not.throw Error
    it 'should trigger load event', ->
      spy = chai.spy()
      create().on 'load', spy
      waits 50
      runs -> spy.should.have.been.called.once

    describe 'when loaded', ->
      # loaded = false
      # subject = null
      # runs ->
      #   subject = create()
      #   subject.on 'load', ->
      #     loaded = true
      # waitsFor (-> loaded), 200

      it 'should invoke MetaSerializer.deserialize', ->
        MetaSerializer = require './../lib/meta-serializer'
        deserialize = MetaSerializer.deserialize
        MetaSerializer.deserialize = chai.spy ->
          arguments[0].should.be.an.instanceof Entry
          arguments[1].should.be.a 'string'
          deserialize.apply null, arguments

        loaded = false
        subject = null
        runs ->
          subject = create()
          subject.on 'load', ->
            loaded = true
        waitsFor (-> loaded), 200

        runs ->
          MetaSerializer.deserialize.should.have.been.called.once
          MetaSerializer.deserialize = deserialize