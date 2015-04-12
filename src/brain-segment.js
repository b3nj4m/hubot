var _ = require('lodash');

function BrainSegment(brain, segmentName) {
  if (segmentName === undefined) {
    segmentName = _.uniqueId();
  }

  var obj = Object.create(brain);
  var segmentRegex = new RegExp("^" + segmentName + ":");

  obj.key = function(key) {
    return brain.key(segmentName + ":" + key);
  };
  obj.unkey = function(key) {
    return brain.unkey(key).replace(segmentRegex, '');
  };

  return obj;
}

module.exports = BrainSegment;
