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

    describe "#entries property", ->

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