_ = require 'lodash'

class RobotSegment
  constructor: (robot, @segment = _.uniqueId()) ->
    segment = ->
    segment.prototype = robot
    obj = new segment()

    obj.brain = robot.brain.segment(@segment)

    return obj

module.exports = RobotSegment
