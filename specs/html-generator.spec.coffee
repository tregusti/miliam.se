chai = require 'chai'
should = chai.should()
expect = chai.expect

subject = require '../lib/html-generator'

describe 'HTML generator', ->
  it 'should be a function', ->
    expect(subject).to.be.a 'function'
  
  it 'handles bold text as markdown', ->
    result = subject '**hello**'
    result.should.contain '<strong>hello</strong>'

  it 'handles code blocks as inline quotes', ->
    result = subject '`hello`'
    result.should.contain '<q>hello</q>'