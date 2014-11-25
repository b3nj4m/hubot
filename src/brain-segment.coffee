_ = require 'lodash'

class BrainSegment
  constructor: (brain, segmentName = _.uniqueId()) ->
    obj = Object.create(brain)

    obj.get = (key) ->
      brain.get("#{segmentName}:#{key}")
    obj.set = (key, value) ->
      brain.set("#{segmentName}:#{key}", value)

    return obj

module.exports = BrainSegment
