var _ = require('lodash');
var Q = require('q');
var inspect = require('util').inspect;
var TextMessage = require('./message').TextMessage;

//TODO hooks for testing expected responses

/*
 * Listeners receive every message from the chat source and decide if they
 * want to act on it.
 *
 * robot    - A Robot instance.
 * matcher  - A Function that determines if this listener should trigger the
 *            callback.
 * callback - A Function that is triggered if the incoming message matches.
 */
function Listener(robot, matcher, callback) {
  this.robot = robot;
  this.matcher = matcher;
  this.callback = callback;
  this.queue = [];
  this.inProgress = Q();
}

Listener.prototype.queueSize = 100;

/*
 * Check whether this listener matches the message.
 *
 * message - the message instance
 *
 * returns boolean
 */
Listener.prototype.matches = function(message) {
  return _.isFunction(this.matcher) ? this.matcher(message) : this.matcher;
};

/*
 * Public: Determines if the listener likes the content of the message. If
 * so, a Response built from the given Message is queued for processing.
 *
 * message - A Message instance.
 *
 * Returns false or the result of queueing the response
 */
Listener.prototype.process = function(message) {
  var match = this.matches(message);

  if (match) {
    if (this.regex) {
      this.robot.logger.debug("Message '" + message + "' matched regex " + this.regex.toString());
    }
    return this.enqueue(new this.robot.Response(this.robot, message, match));
  }
  else {
    if (this.regex) {
      this.robot.logger.debug("Message '" + message + "' not matched regex " + this.regex.toString());
    }
    return false;
  }
};

/*
 * Public: queue a response for processing
 *
 * Returns result of exec or nothing.
 */
Listener.prototype.enqueue = function(response) {
  if (this.inProgress.isPending() || this.queue.length > 0) {
    if (this.queue.length === this.queueSize) {
      this.queue.shift();
    }
    return this.queue.push(response);
  }
  else {
    return this.exec(response);
  }
};

/*
 * Public: process the reponse queue
 *
 * Returns: nothing.
 */
Listener.prototype.exec = function(response) {
  var self = this;

  this.inProgress = this.callback(response);
  if (!this.inProgress || !Q.isPromise(this.inProgress)) {
    this.inProgress = Q(this.inProgress);
  }

  this.inProgress.finally(function() {
    if (self.queue.length > 0) {
      return self.exec(self.queue.shift());
    }
  });
  return this.inProgress;
};

/*
 * TextListeners receive every message from the chat source and decide if they
 * want to act on it.
 *
 * robot    - A Robot instance.
 * regex    - A Regex that determines if this listener should trigger the
 *            callback.
 * callback - A Function that is triggered if the incoming message matches.
 */
function TextListener(robot, regex, callback) {
  Listener.apply(this, arguments);

  var self = this;
  this.robot = robot;
  this.regex = regex;
  this.callback = callback;

  this.matcher = function(message) {
    if (message instanceof TextMessage) {
      return message.match(self.regex);
    }
  };
}

TextListener.prototype = Object.create(Listener.prototype);
TextListener.prototype.constructor = TextListener;

module.exports = {
  Listener: Listener,
  TextListener: TextListener
};
