chai = require 'chai'
should = chai.should()
expect = chai.expect

describe 'MetaSerializer', ->

  MetaSerializer = require '../lib/meta-serializer'
  it 'should be defined', ->
    expect(MetaSerializer).to.be.defined
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