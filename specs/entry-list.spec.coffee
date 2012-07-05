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

    it 'loads all entries in reversed chronological order', (done) ->
      # stub shell script
      cp.exec = chai.spy (str, callback) -> callback null, paths.join('\n')
      EntryList.load '/tmp', (err, entries) ->
        cp.exec.should.have.been.called.once
        entries.should.have.length 4
        entries[3].should.have.property 'basepath', '/tmp/2011/12/24/aaaa'
        entries[2].should.have.property 'basepath', '/tmp/2012/04/13/bbbb'
        entries[1].should.have.property 'basepath', '/tmp/2012/06/06/cccc'
        entries[0].should.have.property 'basepath', '/tmp/2012/06/06/dddd'
        done()

    it 'loads all entries with the same date', (done) ->
      # stub shell script
      cp.exec = chai.spy (str, callback) -> callback null, paths.slice(2).join('\n')
      options =
        year: '2012'
        month: '06'
        date: '06'
      EntryList.load '/tmp', options, (err, entries) ->
        entries.should.have.length 2
        entries[1].should.have.property 'basepath', '/tmp/2012/06/06/cccc'
        entries[0].should.have.property 'basepath', '/tmp/2012/06/06/dddd'
        done()

    it 'loads all entries with the same year', (done) ->
      # stub shell script
      cp.exec = chai.spy (str, callback) -> callback null, paths.slice(1).join('\n')
      options =
        year: '2012'
      EntryList.load '/tmp', options, (err, entries) ->
        entries.should.have.length 3
        entries[2].should.have.property 'basepath', '/tmp/2012/04/13/bbbb'
        entries[1].should.have.property 'basepath', '/tmp/2012/06/06/cccc'
        entries[0].should.have.property 'basepath', '/tmp/2012/06/06/dddd'
        done()