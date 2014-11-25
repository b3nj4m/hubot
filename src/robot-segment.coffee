_ = require 'lodash'

class RobotSegment
  constructor: (robot, segmentName = _.uniqueId()) ->
    obj = Object.create(robot)
    obj.brain = robot.brain.segment(segmentName)
    return obj

module.exports = RobotSegment
