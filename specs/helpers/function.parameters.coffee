unless Function::parameters

  Object.defineProperty Function::, 'parameters',
    enumerable: true
    get: ->
      s = "#{this}"
      params = s.match(/^function.*?\((.*?)\)/)[1]
      if params
        params.split /,\s*/
      else
        []