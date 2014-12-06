_ = require 'lodash'

class BrainSegment
  constructor: (brain, segmentName = _.uniqueId()) ->
    obj = Object.create(brain)

    segmentRegex = new RegExp "^#{segmentName}:"

    obj.key = (key) ->
      brain.key "#{segmentName}:#{key}"
    obj.unkey = (key) ->
      brain.unkey key.replace(segmentRegex, '')

    return obj

module.exports = BrainSegment
