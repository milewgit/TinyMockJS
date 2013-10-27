class Mock
  
  constructor: ->
    @call_counts = {}
  
  expects: (method_name) ->
    @call_counts[ method_name ] ?= { expected: 0, actual: 0 }
    @call_counts[ method_name ].expected += 1
    @[ method_name ] = -> @call_counts[ method_name ].actual += 1
    @
    
  check: ->
    messages = ""
    for method_name, call_count of @call_counts when call_count.expected != call_count.actual
      messages += "'#{method_name}' had #{call_count.actual} calls; expected #{call_count.expected} calls\n" 
    throw new Error(messages) unless messages == ""


(exports ? window).Mock = Mock
