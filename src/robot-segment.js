var _ = require('lodash');

function RobotSegment(robot, segmentName) {
  if (segmentName === undefined) {
    segmentName = _.uniqueId();
  }

  var obj = Object.create(robot);

  obj.brain = robot.brain.segment(segmentName);

  return obj;
}

module.exports = RobotSegment;
