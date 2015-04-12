var EventEmitter = require('events').EventEmitter;
var Q = require('q');

/*
 * An adapter is a specific interface to a chat source for robots.
 *
 * robot - A Robot instance.
 */

function Adapter(robot) {
  this.robot = robot;
  this.ready = Q(this);
}


/*
 * Public: Raw method for sending data back to the chat source. Extend this.
 *
 * envelope - A Object with message, room and user details.
 * strings  - One or more Strings for each message to send.
 *
 * Returns nothing.
 */

Adapter.prototype.send = function(evenlope /*, *strings */) {
};


/*
 * Public: Raw method for sending emote data back to the chat source.
 * Defaults as an alias for send
 *
 * envelope - A Object with message, room and user details.
 * strings  - One or more Strings for each message to send.
 *
 * Returns nothing.
 */

Adapter.prototype.emote = function(envelope /*, *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  return this.send.apply(this, [envelope].concat(Array.prototype.slice.call(strings)));
};


/*
 * Public: Raw method for building a reply and sending it back to the chat
 * source. Extend this.
 *
 * envelope - A Object with message, room and user details.
 * strings  - One or more Strings for each reply to send.
 *
 * Returns nothing.
 */

Adapter.prototype.reply = function(envelope /*, *strings */) {
};


/*
 * Public: Raw method for setting a topic on the chat source. Extend this.
 *
 * envelope - A Object with message, room and user details.
 * strings  - One more more Strings to set as the topic.
 *
 * Returns nothing.
 */

Adapter.prototype.topic = function(envelope /*, *strings */) {
};


/*
 * Public: Raw method for playing a sound in the chat source. Extend this.
 *
 * envelope - A Object with message, room and user details.
 * strings  - One or more strings for each play message to send.
 *
 * Returns nothing
 */

Adapter.prototype.play = function(envelope /*, *strings */) {
};


/*
 * Public: Raw method for invoking the bot to run. Extend this.
 *
 * Returns nothing.
 */

Adapter.prototype.run = function() {};


/*
 * Public: Raw method for shutting the bot down. Extend this.
 *
 * Returns nothing.
 */

Adapter.prototype.close = function() {
  return Q(this);
};


/*
 * Public: Dispatch a received message to the robot.
 *
 * Returns nothing.
 */

Adapter.prototype.receive = function(message) {
  return this.robot.receive(message);
};


module.exports = Adapter;
