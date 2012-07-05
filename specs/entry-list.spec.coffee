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
             /tmp/2012/06/13/dddd".split /\s+/

    beforeEach ->
      # stub shell script
      cp.exec = chai.spy (str, callback) -> callback null, paths.join('\n')
      # stub file reads
      spyfs.on "#{path}/info.txt", "title: #{Path.basename path}" for path in paths

    afterEach ->
      # revert mock
      cp.exec = original
      # unstub file reads
      spyfs.off()

    it 'loads all entries in reversed chronological order', (done) ->
      EntryList.load '/tmp', (err, entries) ->
        cp.exec.should.have.been.called.once
        entries.should.have.length 4
        entries[3].should.have.property 'basepath', '/tmp/2011/12/24/aaaa'
        entries[2].should.have.property 'basepath', '/tmp/2012/04/13/bbbb'
        entries[1].should.have.property 'basepath', '/tmp/2012/06/06/cccc'
        entries[0].should.have.property 'basepath', '/tmp/2012/06/13/dddd'
        done()




    #
    # it 'loads all entries with the same date', (done) ->
    #   opts =  year: '2012', month: '01', date: '11'
    #
    #   el.get opts, (err, entries) ->
    #     expect(entries).to.have.length 2
    #     # Sort by descending time
    #     entries[0].should.have.property 'title', 'With image and datetime'
    #     entries[1].should.have.property 'title', 'Text only'
    #     done()
    #
    # it 'loads all entries within the specified year', (done) ->
    #   opts =  year: '2012'
    #
    #   el.get opts, (err, entries) ->
    #     expect(entries).to.have.length 3
    #     done()
    #
    # it 'should not find anything in 2010', (done) ->
    #   opts =  year: '2010'
    #   el.get opts, (err, entries) ->
    #     expect(err).to.be.an.instanceof NotFoundError
    #     expect(entries).to.be.null
    #     done()