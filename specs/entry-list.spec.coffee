# system modules
Path = require 'path'

# spec helpers
chai = require 'chai'
should = chai.should()
expect = chai.expect
spies = require 'chai-spies'
chai.use spies

# own code
ArgumentError = require '../lib/errors/argument'
NotFoundError = require '../lib/errors/notfound'

describe 'EntryList', ->

  Entry = require '../lib/entry'
  EntryList = require '../lib/entry-list'
  datapath = Path.join __dirname, 'fixtures'

  it 'should exist', ->
    expect(EntryList).to.be.defined

  it 'requires a datapath', ->
    (-> new EntryList '').should.throw ArgumentError

  describe 'with data path', ->
    el = null
    beforeEach -> el = new EntryList datapath

    it 'should have a limit method', ->
      el.should.have.a.property('get').and.should.be.a 'function'

    it 'loads all entries', (done) ->
      @timeout 4000
      el.get (err, entries) ->
        entries.should.have.length 4
        entries[i].should.be.an.instanceof Entry for i in [0..3]
        done err

    it 'loads all entries with the same date', (done) ->
      opts =  year: '2012', month: '01', date: '11'

      el.get opts, (err, entries) ->
        expect(entries).to.have.length 2
        # Sort by descending time
        entries[0].should.have.property 'title', 'With image and datetime'
        entries[1].should.have.property 'title', 'Text only'
        done()

    it 'loads all entries within the specified year', (done) ->
      opts =  year: '2012'

      el.get opts, (err, entries) ->
        expect(entries).to.have.length 3
        done()

    it 'should not find anything in 2010', (done) ->
      opts =  year: '2010'
      el.get opts, (err, entries) ->
        expect(err).to.be.an.instanceof NotFoundError
        expect(entries).to.be.null
        done()