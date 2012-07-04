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
Entry = require '../lib/entry'

describe 'Entry', ->
  afterEach -> spyfs.off()

  it 'should exist', ->
    expect(Entry).to.be.defined

  describe '#load', ->
    it 'should exist', ->
      expect(Entry.load).to.be.defined
    it 'should take 1 param', ->
      Entry.load.should.have.length 2
    it 'throws an error when path is undefined', ->
      Entry.load.should.throw ArgumentError
    it 'throws an error when path is empty', ->
      Entry.load.should.throw ArgumentError

    describe 'with valid entry data', ->

      it 'should invoke callback with entry and no error', (done) ->
        spy = spyfs.on '/tmp/callback-invocation/info.txt', ''
        Entry.load spy.dirname, (err, entry) ->
          expect(err).to.be.null
          expect(entry).to.be.defined
          done()

      describe 'when loaded', ->
        it 'should have a basepath', (done) ->
          spy = spyfs.on '/tmp/basepath', 'glenn'
          Entry.load spy.path, (err, entry) ->
            entry.should.have.a.property 'basepath', Path.resolve spy.path
            done()

        it 'should invoke EntryInfoSerializer.deserialize', (done) ->
          EntryInfoSerializer = require './../lib/entry-info-serializer'
          deserialize = EntryInfoSerializer.deserialize
          EntryInfoSerializer.deserialize = chai.spy ->
            deserialize.apply null, arguments

          spy = spyfs.on '/tmp/deserialize/info.txt', 'tregusti'
          subject = Entry.load spy.path, (err, entry) ->
            EntryInfoSerializer.deserialize.should.have.been.called.once
            EntryInfoSerializer.deserialize = deserialize
            done()

        describe 'human time', ->
          entry = null
          before (done) ->
            spy = spyfs.on '/tmp/human-time/info.txt', 'date: 2012-06-06\ntime: 10:14'
            Entry.load Path.dirname(spy.path), (err, _entry) ->
              entry = _entry
              done()
          it 'has a pretty date prop', ->
            entry.should.have.property 'humanDate', "6 jun 2012"
          it 'has a pretty date prop', ->
            entry.should.have.property 'humanTime', "10:14"
          it 'is readonly', ->
            entry.humanTime = 'nope'
            entry.humanDate = 'nope'
            entry.should.have.property 'humanTime', "10:14"
            entry.should.have.property 'humanDate', "6 jun 2012"

      it 'should set both text and html to null when no body', (done) ->
        spy = spyfs.on '/tmp/empty-body/info.txt', 'title: only'
        Entry.load spy.dirname, (err, entry) ->
          entry.should.have.property 'text', null
          entry.should.have.property 'html', null
          done()

      describe 'with body', ->
        entry = null
        before (done) ->
          spy = spyfs.on '/tmp/empty-body/info.txt', 'title:hej\n\nParagraph 1\n\nParagraph 2\n\nParagraph 3'
          Entry.load spy.dirname, (err, _entry) ->
            entry = _entry
            done()
        it 'should have a text property', ->
          entry.should.have.property 'text'
        it 'should have a html property', ->
          entry.should.have.property 'html'
        it 'html property should be readonly', ->
          entry.html = "nope"
          entry.html.should.not.equal 'nope'
        it 'should have a html property with paragraphs', ->
          entry.html.should.contain '<p>Paragraph 1'
          entry.html.should.contain '<p>Paragraph 2'
          entry.html.should.contain '<p>Paragraph 3'
  #
  # describe 'image parsing', ->
  #
  #   it 'should load ok with image', (done) ->
  #     new Entry(fixture 'with-image').on 'load', done
  #   it 'should have an image property with null when no images', (done) ->
  #     entry = new Entry fixture 'only-text'
  #     entry.on 'load', ->
  #       entry.should.have.property 'image', null
  #       done()
  #   it 'should have an image property with paths', (done) ->
  #     path = fixture 'with-image'
  #     entry = new Entry path
  #     entry.on 'load', ->
  #       entry.should.have.property 'image'
  #       entry.image[type].should.equal "#{path}/#{type}.jpg" for type in ['normal', 'thumb', 'original']
  #       done()
  #
  #   it 'does not override info.txt datetime with image datetime', (done) ->
  #     entry = new Entry fixture 'with-image-and-datetime'
  #     entry.on 'load', ->
  #       # +0100 due to winter time
  #       entry.time.toISOString().should.equal new Date('2012-01-11 10:10:10+0100').toISOString()
  #       done()
  #
  #   it 'sets date and time from original image when omitted in info.txt', (done) ->
  #     entry = new Entry fixture 'with-image'
  #     entry.on 'load', ->
  #       # +0200 due to summer time
  #       entry.time.toISOString().should.equal '2012-06-11T15:31:45.000Z'
  #       done()
  #
  #   it 'should lookup the timezone from askgeo for images (postponed, build npm package)'