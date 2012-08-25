# system modules
Path = require 'path'

# spec helpers
chai = require 'chai'
should = chai.should()
expect = chai.expect
spies = require 'chai-spies'
chai.use spies

spyfs = require './helpers/spy-fs'

# own code
ArgumentError = require '../lib/errors/argument'
NotFoundError = require '../lib/errors/notfound'

describe 'EntryList', ->
  Entry = require '../lib/entry'
  EntryList = require '../lib/entry-list'
  datapath = Path.join __dirname, 'fixtures'

  it 'should exist', ->
    expect(EntryList).to.be.defined

  it 'requires a datapath', (done) ->
    EntryList.load '', (err) ->
      expect(err).to.be.an.instanceof ArgumentError
      done()

  describe 'with data path', ->
    cp = require 'child_process'
    original = cp.exec
    entries = null

    paths = "/tmp/2011/12/24/aaaa
             /tmp/2012/04/13/bbbb
             /tmp/2012/06/06/cccc
             /tmp/2012/06/06/dddd".split /\s+/

    beforeEach ->
      # stub file reads
      spyfs.on "#{path}/info.txt", "title: #{Path.basename path}" for path in paths

    afterEach ->
      # revert mock
      cp.exec = original
      # unstub file reads
      spyfs.off()

    it "should be be an EntryList", (done) ->
      cp.exec = chai.spy (str, callback) -> callback null, paths.join('\n')
      EntryList.load '/tmp', (err, list) ->
        list.should.be.an.instanceof EntryList
        done()

    describe "#title property", ->
      it "should be read only", ->
        el = new EntryList
        el.should.have.property 'title', ''
        el.title = 'nope'
        el.should.have.property 'title', ''

      it "reflects the year", ->
        el = new EntryList 2012
        el.should.have.property 'title', '2012'

      it "reflects the year and month", ->
        el = new EntryList 2012, 8
        el.should.have.property 'title', 'Augusti 2012'

      it "reflects the year, month and date", ->
        el = new EntryList 2012, 8, 12
        el.should.have.property 'title', '12 augusti 2012'

      it "handles zero padded months", ->
        el = new EntryList 2012, "07"
        el.should.have.property 'title', 'Juli 2012'

      it "handles zero padded dates", ->
        el = new EntryList 2012, 5, "07"
        el.should.have.property 'title', '7 maj 2012'


    describe "#entries property", ->

      it "invokes constructor with year, month and date", (done) ->
        cp.exec = chai.spy (str, callback) -> callback null, paths.join('\n')
        opts =
          year: 2011
          month: 2
          date: 9
        EntryList.load '/tmp', opts, (err, list) ->
          list.title.should.equal "9 februari 2011"
          done()

      it 'loads all entries in reversed chronological order', (done) ->
        # stub shell script
        cp.exec = chai.spy (str, callback) -> callback null, paths.join('\n')
        EntryList.load '/tmp', (err, list) ->
          expect(list.entries).to.not.be.undefined
          cp.exec.should.have.been.called.once
          list.entries.should.have.length 4
          list.entries[3].should.have.property 'basepath', '/tmp/2011/12/24/aaaa'
          list.entries[2].should.have.property 'basepath', '/tmp/2012/04/13/bbbb'
          list.entries[1].should.have.property 'basepath', '/tmp/2012/06/06/cccc'
          list.entries[0].should.have.property 'basepath', '/tmp/2012/06/06/dddd'
          done()

      it 'loads all entries with the same date', (done) ->
        # stub shell script
        cp.exec = chai.spy (str, callback) ->
          result = paths.slice(2).join('\n') if /2012\/06\/06/.test str
          callback null, result or ''
        options =
          year: '2012'
          month: '06'
          date: '06'
        EntryList.load '/tmp', options, (err, list) ->
          expect(list.entries).to.not.be.undefined
          list.entries.should.have.length 2
          list.entries[1].should.have.property 'basepath', '/tmp/2012/06/06/cccc'
          list.entries[0].should.have.property 'basepath', '/tmp/2012/06/06/dddd'
          done()

      it 'loads all entries with the same year', (done) ->
        # stub shell script
        cp.exec = chai.spy (str, callback) ->
          result = paths.slice(1).join('\n') if /2012/.test str
          callback null, result or ''
        options =
          year: '2012'
        EntryList.load '/tmp', options, (err, list) ->
          expect(list.entries).to.not.be.undefined
          list.entries.should.have.length 3
          list.entries[2].should.have.property 'basepath', '/tmp/2012/04/13/bbbb'
          list.entries[1].should.have.property 'basepath', '/tmp/2012/06/06/cccc'
          list.entries[0].should.have.property 'basepath', '/tmp/2012/06/06/dddd'
          done()

      it "limits the amount of entries when specified", (done) ->
        cp.exec = chai.spy (str, callback) -> callback null, paths.join('\n')
        options =
          limit: 2
        EntryList.load '/tmp', options, (err, list) ->
          list.entries.should.have.length 2
          done()

      it "offsets the start of the entries list when specified", (done) ->
        cp.exec = chai.spy (str, callback) -> callback null, paths.join('\n')
        options =
          offset: 1
        EntryList.load '/tmp', options, (err, list) ->
          list.entries.should.have.length 3
          done()