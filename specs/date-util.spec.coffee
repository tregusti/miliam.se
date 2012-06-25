du = require '../lib/date-util'

describe 'date-util', ->
  describe 'ISOStringInSweden', ->
    it 'should take one param', ->
      expect(du.ISOStringInSweden.length).toBe 1
    it 'cant take invalid date strings', ->
      expect(du.ISOStringInSweden 'wewe').toBe null
      expect(du.ISOStringInSweden '20111111').toBe null
    it 'handles normal timezone', ->
      (expect du.ISOStringInSweden '2012-01-01T13:00:00').toBe '2012-01-01T13:00:00+0100'
    it 'handles summer time', ->
      (expect du.ISOStringInSweden '2012-06-05T13:00:00').toBe '2012-06-05T13:00:00+0200'