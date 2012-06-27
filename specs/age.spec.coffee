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

    describe 'of days', ->
      it 'counts whole days', ->
        Age.since(@date.addDays -4).should.equal '4 dagar'
    
      it "rounds off to nearest day count", ->
        Age.since(@date.addDays -2.9).should.equal '3 dagar'
    
      it "rounds up to next day count", ->
        Age.since(@date.addDays -3.1).should.equal '4 dagar'
    
      it "uses singular form when single day", ->
        Age.since(@date.addDays -1).should.equal '1 dag'
    
    describe 'of months', ->
      it "uses only months when same date", ->
        Age.since(@date.addMonths -2).should.equal '2 månader'
    
      it "uses singular form when only one", ->
        Age.since(@date.addMonths -1).should.equal '1 månad'
    
      it "uses month and day", ->
        Age.since(@date.addMonths(-1).addDays(-4)).should.equal '1 månad och 4 dagar'
    
      it "uses year, month and day", ->
        d = @date.addYears(-1).addMonths(-3).addDays(-12)
        Age.since(d).should.equal '1 år, 3 månader och 12 dagar'