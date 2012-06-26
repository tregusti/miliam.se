require './matchers'

NotFoundError = require('../lib/errors').NotFoundError
ArgumentError = require('../lib/errors').ArgumentError
EntryError = require('../lib/errors').EntryError

path = require 'path'


describe 'Entry class', ->

  Entry = require('../lib/entry').Entry

  fixture = (slug) ->
    return path.join __dirname, 'fixtures', slug

  it 'should exist', ->
    expect(Entry).toBeTruthy()

  describe 'constructor', ->
    it 'should take 1 param', ->
      expect(Entry.length).toBe 1

  describe 'observable', ->
    it 'should inherit from observable', ->
      expect(Entry.prototype.constructor.name).toBe 'Observable'
    it 'should invoke observable constructor', ->
      expect(new Entry).toDefine('observableId')



  xdescribe 'static load method', ->

    entry = err = null
    beforeEach -> entry = err = null

    it 'takes a path parameter and a callback', ->
      (expect Entry.load.length).toBe 2

    it 'sends argument error when no path param is sent', ->
      runs ->
        Entry.load null, -> [err, entry] = arguments
      waits 100
      runs ->
        expect(err).toBeAnInstanceOf ArgumentError
        expect(err.argumentName).toBe 'path'
        expect(entry).toBeNull()

    it 'sends not found error if path does not exist', ->
      runs ->
        Entry.load (fixture 'non-existing'), -> [err, entry] = arguments
      waits 250
      runs ->
        expect(err).toBeAnInstanceOf NotFoundError
        expect(entry).toBeNull()

    it 'sends an error when no info-txt file exists', ->
      runs ->
        Entry.load '/tmp', -> [err, entry] = arguments
      waits 100
      runs ->
        expect(err).toBeAnInstanceOf EntryError

    describe 'entry with only text', ->
      beforeEach ->
        runs ->
          Entry.load (fixture 'only-text'), -> [err, entry] = arguments
        waits 100

      it 'sends an instance of the Entry class if info file exists', ->
        runs ->
          expect(err).toBeNull()
          expect(entry).toBeAnInstanceOf Entry

      # it 'should read in title', ->
      #   runs ->
      #     expect(entry.title).toBe 'This is an example with only text'