class BrainSegment
  constructor: (@brain, @segment = uniqueId()) ->
    #TODO user methods
    @get = (key) ->
      @brain.get("#{segment}:#{key}")
    @set = (key, value) ->
      @brain.set("#{segment}:#{key}", value)

id = 0
uniqueId = ->
  id++

module.exports = BrainSegment
