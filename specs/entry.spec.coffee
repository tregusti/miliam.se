NotFoundError = require('../lib/errors').NotFoundError
ArgumentError = require('../lib/errors').ArgumentError
path = require 'path'


describe 'Entry class', ->

  beforeEach ->
    @addMatchers
      toBeAnInstanceOf: (expected) ->
        actual = @actual
        @message = -> "Expected " + actual + " to be an instance of " + expected.name

        actual instanceof expected

  Entry = require '../lib/entry'

  fixture = (slug) ->
    return path.join __dirname, 'fixtures', slug

  it 'should exist', ->
    expect(Entry).toBeTruthy()

  describe 'static load method', ->

    it 'takes a path parameter and a callback', ->
      (expect Entry.load.length).toBe 2

    it 'sends argument error when no path param is sent', ->
      runs ->
        Entry.load null, (err) ->
          expect(err).toBeAnInstanceOf ArgumentError
          expect(err.argumentName).toBe 'path'
      waits 100


    it 'sends not found error if path does not exist', ->
      runs ->
        Entry.load (fixture 'non-existing'), (err) ->
          expect(err).toBeAnInstanceOf NotFoundError
      waits 250