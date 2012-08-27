require 'date-utils'

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


  describe "#between", ->
    it "counts whole days", ->
      start = new Date 2012, 1, 1, 13
      end   = new Date 2012, 1, 3, 13
      Age.between(start, end).should.equal "2 dagar"

    it "doesn't count big day fragments", ->
      start = new Date 2012, 1, 1, 13
      end   = new Date 2012, 1, 4, 12
      Age.between(start, end).should.equal "2 dagar"

    it "doesn't count small day fragments", ->
      start = new Date 2012, 1, 1, 13
      end   = new Date 2012, 1, 3, 14
      Age.between(start, end).should.equal "2 dagar"

    it "uses days, months, and years", ->
      start = new Date 2010, 1, 1
      end   = new Date 2012, 7, 2
      Age.between(start, end).should.equal "2 år, 6 månader och 1 dag"


  describe '#since', ->
    beforeEach ->
      @date = new Date

    describe 'of days', ->
      it 'counts whole days', ->
        Age.since(@date.addDays -4).should.equal '4 dagar'

      it "rounds off to nearest earlier day count", ->
        # When he is 3.3 days, it still counts as just 3 days
        Age.since(@date.addHours -3.3 * 24).should.equal '3 dagar'

      it "uses singular form when single day", ->
        Age.since(@date.addDays -1).should.equal '1 dag'

    describe 'of months and years', ->
      it "uses only months when same date", ->
        Age.since(@date.addMonths -2).should.equal '2 månader'

      it "uses singular form when only one", ->
        Age.since(@date.addMonths -1).should.equal '1 månad'

      it "uses month and day", ->
        Age.since(@date.addMonths(-1).addDays(-4)).should.equal '1 månad och 4 dagar'

      it "uses year, month and day"
      # , ->
      #   d = @date.addYears(-1).addMonths(-3).addDays(-12)
      #   Age.since(d).should.equal '1 år, 3 månader och 12 dagar'

      it "uses years and months", ->
        d = @date.addYears(-3).addMonths(-1)
        Age.since(d).should.equal '3 år och 1 månad'

  it 'should have a birth property', ->
    # Don't use real birth time. ppl only care about the day
    # Starnge. Need to be off one days for calcs to be correct. Hav'e inspected further
    Age.should.have.property 'birth', '2012-06-07 00:00:00'

  describe 'attach method', ->
    it 'should exist', ->
      Age.should.have.property('attach')
      Age.attach.should.be.a('function').and.have.length(1)
    it 'adds a property to view locals object', ->
      app = locals: use: chai.spy()
      Age.attach app
      app.locals.use.should.have.been.called.once