chai = require 'chai'
should = chai.should()
expect = chai.expect

Entry = require '../lib/entry'

describe 'MetaSerializer', ->

  MetaSerializer = require '../lib/meta-serializer'
  it 'should be defined', ->
    expect(MetaSerializer).to.be.defined

  describe 'method deserialize', ->

    beforeEach ->
      @entry = new Entry '/tmp'

    it 'should exist', ->
      MetaSerializer.should.respondTo 'deserialize'
    it 'should take 2 params', ->
      MetaSerializer.deserialize.should.have.length 2
    it 'set the title', ->
      MetaSerializer.deserialize @entry, 'title: Hello'
      @entry.should.have.property 'title', 'Hello'

    describe 'time property', ->
      it 'should be set', ->
        MetaSerializer.deserialize @entry, 'title: Hello'
        @entry.should.have.property 'time'
      it 'defaults to now if no time or date is specified', ->
        MetaSerializer.deserialize @entry, 'title: Hello'
        # equal dates (similar enough). Date is hard to mock...
        @entry.time.toISOString().substr(0,19).should.equal new Date().toISOString().substr(0, 19)
      it 'defaults to today but uses specified time'
      it 'uses specified date and time'