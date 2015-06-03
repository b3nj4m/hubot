var User = require('./src/user');
var Brain = require('./src/brain');
var Robot = require('./src/robot');
var Adapter = require('./src/adapter');
var Response = require('./src/response');
var listener = require('./src/listener');
var message = require('./src/message');

module.exports = {
  User: User,
  Brain: Brain,
  Robot: Robot,
  Adapter: Adapter,
  Response: Response,
  Listener: listener.Listener,
  TextListener: listener.TextListener,
  Message: message.Message,
  TextMessage: message.TextMessage,
  EnterMessage: message.EnterMessage,
  LeaveMessage: message.LeaveMessage,
  TopicMessage: message.TopicMessage,
  CatchAllMessage: message.CatchAllMessage
};

module.exports.loadBot = function(scripts, adapterName, brainName, enableHttpd, botName) {
  return new Robot(scripts, adapterName, brainName, enableHttpd, botName);
};
