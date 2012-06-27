chai = require 'chai'
should = chai.should()
expect = chai.expect

Entry = require '../lib/entry'

describe 'EntryInfoSerializer', ->

  EntryInfoSerializer = require '../lib/entry-info-serializer'
  it 'should be defined', ->
    expect(EntryInfoSerializer).to.be.defined

  describe 'method deserialize', ->

    beforeEach ->
      @entry = new Entry '/tmp'

    it 'should exist', ->
      EntryInfoSerializer.should.respondTo 'deserialize'
    it 'should take 2 params', ->
      EntryInfoSerializer.deserialize.should.have.length 2
    it 'set the title', ->
      EntryInfoSerializer.deserialize @entry, 'title: Hello'
      @entry.should.have.property 'title', 'Hello'

    describe 'time property', ->

      it 'should be set', ->
        EntryInfoSerializer.deserialize @entry, 'title: Hello'
        @entry.should.have.property 'time'

      it 'defaults to now if no time or date is specified', ->
        EntryInfoSerializer.deserialize @entry, 'title: Hello'
        # equal dates (similar enough). Date is hard to mock...
        @entry.time.toISOString().substr(0,19).should.equal new Date().toISOString().substr(0, 19)

      it 'defaults to today but uses specified time', ->
        EntryInfoSerializer.deserialize @entry, 'time: 13:00:00'
        dateStr = new Date().toISOString().substr(0, 10)
        d = new Date dateStr + ' 13:00:00'
        @entry.time.toLocaleString().should.equal d.toLocaleString()

      it 'uses specified date and time', ->
        EntryInfoSerializer.deserialize @entry, "date: 2011-12-24\ntime: 15:00:00"
        @entry.time.toLocaleString().should.equal new Date("2011-12-24 15:00:00").toLocaleString()

      it 'allows for missing seconds', ->
        EntryInfoSerializer.deserialize @entry, "date: 2011-12-24\ntime: 15:25"
        @entry.time.toLocaleString().should.equal new Date("2011-12-24 15:25:00").toLocaleString()

      it "uses the corect timezone, no matter if it's currently windter/summer time", ->
        EntryInfoSerializer.deserialize @entry, "date: 2011-12-24\ntime: 15:25"
        @entry.time.toLocaleString().should.equal new Date("2011-12-24 15:25:00").toLocaleString()

        EntryInfoSerializer.deserialize @entry, "date: 2011-06-24\ntime: 15:25"
        @entry.time.toLocaleString().should.equal new Date("2011-06-24 15:25:00").toLocaleString()