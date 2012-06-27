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
      @entry = new Object
      @entry.constructor = Entry

    it 'should exist', ->
      MetaSerializer.should.respondTo 'deserialize'
    it 'should take 2 params', ->
      MetaSerializer.deserialize.should.have.length 2
    it 'set the title', ->
      MetaSerializer.deserialize @entry, 'title: Hello'
      @entry.title.should.equal 'Hello'
    # it 'defaults to now if no time or date is specified', ->
    #   MetaSerializer.deserialize @entry, ''
    #   @entry.date
    # describe 'custom date and time', ->
    #   beforeEach ->
    #     MetaSerializer.deserialize @entry, "
    #       date: 2012-06-06
    #       time: 19:30:00
    #     "
    #
    #   it 'sets the date', ->
    #     @entry.date.to.to.should.equal 'Hello'

      # it 'should have a title', ->
      #   subject.should.have.property 'title', 'This is an example with only text'
      #
      # describe 'property date', ->
      #   it 'should exist', -> subject.should.have.property 'date'
      #   it 'should be a date', -> subject.date.should.be.a 'date'
      #   it 'should include hour', -> subject.date.getHours().should.be.equal 10
      #   it 'should include minutes', -> subject.date.getMinutes().should.be.equal 14
      #   it 'should include seconds', -> subject.date.getSeconds().should.be.equal 20
      #   it 'should be a date', -> subject.date.should.be.a 'date'