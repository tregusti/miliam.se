du = require 'date-utils'

chai = require 'chai'
should = chai.should()
expect = chai.expect

Age = require '../lib/age'

describe 'Age', ->
  it 'should be defined', ->
    expect(Age).to.be.defined
  it 'should have a since method', ->
    Age.should.have.property 'since'
    Age.since.should.be.a 'function'

  describe 'calculation', ->
    beforeEach ->
      @date = new Date

    it 'counts whole days', ->
      Age.since(@date.addDays -4).should.equal '4 dagar'

    it "rounds off to nearest day count"#, ->
#      Age.since(@date.addDays -2.9).should.equal '3 dagar'

    it "uses singular form when single day", ->
      Age.since(@date.addDays -1).should.equal '1 dag'