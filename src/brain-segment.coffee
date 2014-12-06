_ = require 'lodash'

class BrainSegment
  constructor: (brain, segmentName = _.uniqueId()) ->
    obj = Object.create(brain)

    obj.key = (key) ->
      "#{segmentName}:#{key}"

    return obj

module.exports = BrainSegment
