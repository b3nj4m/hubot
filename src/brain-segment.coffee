_ = require 'lodash'

class BrainSegment
  constructor: (brain, @segment = _.uniqueId()) ->
    segment = ->
    segment.prototype = brain
    obj = new segment()

    obj.get = (key) ->
      brain.get("#{segment}:#{key}")
    obj.set = (key, value) ->
      brain.set("#{segment}:#{key}", value)

    return obj

module.exports = BrainSegment
