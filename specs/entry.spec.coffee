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


describe 'Entry', ->

  Entry = require '../lib/entry'

  fixture = (slug) ->
    base = Path.join __dirname, 'fixtures'
    switch slug
      when 'only-text'
        Path.join base, "2011", "11", "11", slug
      when 'with-image'
        Path.join base, "2012", "01", "10", slug
      when 'with-image-and-datetime'
        Path.join base, "2012", "01", "11", slug

  it 'should exist', ->
    expect(Entry).to.be.defined

  describe 'constructor', ->
    it 'should take 1 param', ->
      Entry.should.have.length 1
    it 'throws an error when path is undefined', ->
      (-> new Entry).should.throw ArgumentError
    it 'throws an error when path is empty', ->
      (-> new Entry '').should.throw ArgumentError

  describe 'observable', ->
    it 'should inherit from observable', ->
      expect(Entry.prototype.constructor.__super__.constructor.name).to.equal 'Observable'
    it 'should invoke observable constructor', ->
      expect(new Entry fixture 'only-text').to.have.property 'observableId'

  describe 'with entry only-text', ->

    it 'should not throw error', ->
      f = -> new Entry fixture 'only-text'
      f.should.not.throw Error
    it 'should trigger load event', (done) ->
      new Entry(fixture 'only-text').on 'load', done

    describe 'when loaded', ->
      it 'should invoke EntryInfoSerializer.deserialize', (done) ->
        EntryInfoSerializer = require './../lib/entry-info-serializer'
        deserialize = EntryInfoSerializer.deserialize
        EntryInfoSerializer.deserialize = chai.spy ->
          arguments[0].should.be.an.instanceof Entry
          arguments[1].should.be.a 'string'
          deserialize.apply null, arguments

        subject = new Entry fixture 'only-text'
        subject.on 'load', ->
          EntryInfoSerializer.deserialize.should.have.been.called.once
          EntryInfoSerializer.deserialize = deserialize
          done()

      describe 'human time', ->
        before (done) ->
          @subject = new Entry fixture 'only-text'
          @subject.on 'load', done
        it 'has a pretty date prop', ->
          @subject.should.have.property 'humanDate', "6 jun 2012"
        it 'has a pretty date prop', ->
          @subject.should.have.property 'humanTime', "10:14"
        it 'is readonly', ->
          @subject.humanTime = 'nope'
          @subject.humanDate = 'nope'
          @subject.should.have.property 'humanTime', "10:14"
          @subject.should.have.property 'humanDate', "6 jun 2012"
  describe 'image parsing', ->

    it 'should load ok with image', (done) ->
      # This spec sometimes takes time, so up the timout limit
      @timeout 2000
      new Entry(fixture 'with-image').on 'load', done
    it 'should have an image property with null when no images', (done) ->
      entry = new Entry fixture 'only-text'
      entry.on 'load', ->
        entry.should.have.property 'image', null
        done()
    it 'should have an image property with paths', (done) ->
      path = fixture 'with-image'
      entry = new Entry path
      entry.on 'load', ->
        entry.should.have.property 'image'
        entry.image[type].should.equal "#{path}/#{type}.jpg" for type in ['normal', 'thumb', 'original']
        done()

    it 'does not override info.txt datetime with image datetime', (done) ->
      entry = new Entry fixture 'with-image-and-datetime'
      entry.on 'load', ->
        # +0100 due to winter time
        entry.time.toISOString().should.equal new Date('2012-12-12 10:10:10+0100').toISOString()
        done()

    it 'sets date and time from original image when omitted in info.txt', (done) ->
      entry = new Entry fixture 'with-image'
      entry.on 'load', ->
        # +0200 due to summer time
        entry.time.toISOString().should.equal '2012-06-11T15:31:45.000Z'
        done()

    it 'should lookup the timezone from askgeo for images (postponed, build npm package)'