# TODO: In error message names: Called, Used, or Specified: pick one
# TODO: pull the errors from the file and hard-code them here
messages = require("../messages/messages.en.json")


mock = (test_function) ->
  Object.prototype.expects = (method_name) ->
    fail(messages.ExpectsUsage) unless method_name?
    fail(messages.ExpectsUsage) if arguments.length != 1
    fail(messages.NotAnExistingMethod, method_name) unless is_mock_object(@) or has_method(@, method_name)
    fail(messages.PreExistingProperty, method_name) if has_property(@, method_name)
    fail(messages.ReservedMethodName, method_name) if method_name == "expects"      # TODO: extract is_reserved_method_name()
    expectations = @[method_name]?.expectations
    if ! expectations
      @[method_name] = (args...) ->
        expectation = expectations.find_expectation(args...)
        fail(messages.UnknownExpectation, method_name, args) unless expectation
        throw expectation._throws if expectation._throws
        expectation._returns
      expectations = @[method_name].expectations = new ExpectationList()
    expectations.create_expectation()
  mock_objects = ( new MockObject() for i in [1..5] )
  test_function.apply(null, mock_objects)
  
  
class MockObject
  
    # empty

  
class Expectation
  
  constructor: ->
    @_args = []
    @_returns = undefined
    @_throws = undefined
    
  args: (args...) ->
    fail(messages.ArgsUsage) if args.length == 0
    fail(messages.ArgsUsedMoreThanOnce) unless @_args.length == 0
    fail(messages.ArgsUsedAfterReturnsOrThrows) if @_returns? or @_throws?
    @_args = args
    @
    
  returns: (value) ->
    fail(messages.ReturnsUsage) unless value?
    fail(messages.ReturnsUsage) if arguments.length != 1
    fail(messages.ReturnsUsedMoreThanOnce) if @_returns?
    fail(messages.ReturnsAndThrowsBothUsed) if @_throws?
    @_returns = value
    @
    
  throws: (error) ->
    fail(messages.ThrowsUsage) unless error?
    fail(messages.ThrowsUsage) if arguments.length != 1
    fail(messages.ThrowsUsedMoreThanOnce) if @_throws?
    fail(messages.ReturnsAndThrowsBothUsed) if @_returns?
    @_throws = error
    @
    
  matches: (args...) ->
    ( @_args.length == args.length ) and
      ( @_args.every ( element, i ) -> element == args[ i ] )
      
      
class ExpectationList
  
  constructor: ->
    @_list = []
    
  create_expectation: ->
    expectation = new Expectation()
    @_list.push(expectation)
    expectation
    
  find_expectation: (args...) ->
    for expectation in @_list when expectation.matches(args...)
      return expectation
    undefined


#
# common functions
#

has_property = (object, property_name) ->
  object[ property_name ]? and (typeof object[ property_name ]) isnt 'function'

has_method = (object, method_name) ->
  object[ method_name ]?

is_mock_object = (object) ->
  object.constructor.name == 'MockObject'

fail = (message, args...) ->  
  throw new Error(format(message, args...))

#
# format("{0} + {1} = {2}", 2, 2, "four") => "2 + 2 = four"
#
# See: http://stackoverflow.com/questions/9880578/coffeescript-version-of-string-format-sprintf-etc-for-javascript-or-node-js
#
format = (message, args...) ->
  message.replace /{(\d)+}/g, (match, i) ->
    if typeof args[i] isnt 'undefined' then args[i] else match


#
# Export the mock() function.  In a node app:
#
#   mock = require("TinyMock")
#
# and in a browser:
#
#   <script src="TinyMock.js"></script>
#   <script>
#     mock( function(m) {
#       m.expects ...
#     });
#   </script>
#
# See: http://www.matteoagosti.com/blog/2013/02/24/writing-javascript-modules-for-both-browser-and-node/
#
if module?.exports?
  module.exports = mock
else
  window.mock = mock
