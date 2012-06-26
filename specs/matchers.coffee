beforeEach ->
  @addMatchers

    toBeNumeric: ->
      self = @
      @message = ->
        neg = if self.isNot then 'not ' else ''
        "Expected #{self.actual} to #{neg}be a number";
      NaN isnt Number @actual

    toDefine: (expected) ->
      self = @
      @message = ->
        neg = if self.isNot then 'not ' else ''
        "Expected #{self.actual} to #{neg}define the propery '#{expected}'";
      !!@actual[expected]

    toBeAnInstanceOf: (expected) ->
      actual = @actual
      @message = -> "Expected " + actual + " to be an instance of " + expected.prototype.name

      actual instanceof expected