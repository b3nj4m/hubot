var Url = require('url');
var _ = require('lodash');
var Q = require('q');
var Fs = require('fs');
var Log = require('log');
var Path = require('path');
var HttpClient = require('scoped-http-client');
var EventEmitter = require('events').EventEmitter;
var User = require('./user');
var RobotSegment = require('./robot-segment');
var Response = require('./response');
var listener = require('./listener');
var Listener = listener.Listener;
var TextListener = listener.TextListener;
var TextMessage = require('./message').TextMessage;

var BROBBOT_DEFAULT_ADAPTERS = ['shell'];
var BROBBOT_DEFAULT_BRAINS = ['dumb'];
var BROBBOT_DOCUMENTATION_SECTIONS = ['description', 'dependencies', 'configuration', 'commands', 'notes', 'author', 'authors', 'examples', 'tags', 'urls'];

/*
 * Robots receive messages from a chat source (Campfire, irc, etc), and
 * dispatch them to matching listeners.
 *
 * scripts - An array of string modules names to load
 * adapter - A string adapter name or an adapter constructor.
 * brain - A string brain name or a brain constructor.
 * httpd - A boolean whether to enable the HTTP daemon.
 * name - A string of the robot name, defaults to Brobbot.
 *
 * Returns nothing.
 */
function Robot(scripts, adapter, brain, httpd, name) {
  var self = this;

  if (name === undefined) {
    name = 'Brobbot';
  }
  this.name = name;
  this.nameRegex = new RegExp("^\\s*@?" + name + ":?\\s+", 'i');
  this.events = new EventEmitter();
  this.alias = false;
  this.adapter = null;
  this.Response = Response;
  this.commands = [];
  this.listeners = {
    text: [],
    respond: [],
    topic: [],
    enter: [],
    leave: [],
    catchall: []
  };

  /*
   *TODO namespaced logger per-script
   */
  this.logger = new Log(process.env.BROBBOT_LOG_LEVEL || 'info');
  this.pingIntervalId = null;
  this.parseVersion();

  if (httpd) {
    this.setupExpress();
  } else {
    this.setupNullRouter();
  }

  this.brainReady = this.loadBrain(brain);
  this.scriptsReady = this.loadScripts(scripts);
  this.adapterReady = this.loadAdapter(adapter);
  this.ready = Q.all([this.brainReady, this.scriptsReady]);
  this.connected = this.adapterReady;
  this.adapterName = adapter;
  this.errorHandlers = [];

  this.ready.fail(function(err) {
    return self.logger.error(err.stack);
  });

  this.on('error', function(err, msg) {
    return self.invokeErrorHandlers(err, msg);
  });

  process.on('uncaughtException', function(err) {
    self.logger.error(err.stack);
    return self.emit('error', err);
  });
}

/*
 * Public: Adds a Listener that attempts to match incoming messages based on
 * a Regex.
 *
 * regex    - A Regex that determines if the callback should be called.
 * callback - A Function that is called with a Response object.
 *
 * Returns nothing.
 */
Robot.prototype.hear = function(regex, callback) {
  return this.listeners.text.push(new TextListener(this, regex, callback));
};

/*
 * Public: Adds a Listener that attempts to match incoming messages directed
 * at the robot based on a Regex. All regexes treat patterns like they begin
 * with a '^'
 *
 * regex    - A Regex that determines if the callback should be called.
 * callback - A Function that is called with a Response object.
 *
 * Returns nothing.
 */
Robot.prototype.respond = function(regex, callback) {
  return this.listeners.respond.push(new TextListener(this, regex, callback));
};

/*
 * Public: Adds a Listener that triggers when anyone enters the room.
 *
 * callback - A Function that is called with a Response object.
 *
 * Returns nothing.
 */
Robot.prototype.enter = function(callback) {
  return this.listeners.enter.push(new Listener(this, function(msg) {
    return true;
  }, callback));
};

/*
 * Public: Adds a Listener that triggers when anyone leaves the room.
 *
 * callback - A Function that is called with a Response object.
 *
 * Returns nothing.
 */
Robot.prototype.leave = function(callback) {
  return this.listeners.leave.push(new Listener(this, function(msg) {
    return true;
  }, callback));
};

/*
 * Public: Adds a Listener that triggers when anyone changes the topic.
 *
 * callback - A Function that is called with a Response object.
 *
 * Returns nothing.
 */
Robot.prototype.topic = function(callback) {
  return this.listeners.topic.push(new Listener(this, function(msg) {
    return true;
  }, callback));
};

/*
 * Public: Adds an error handler when an uncaught exception or user emitted
 * error event occurs.
 *
 * callback - A Function that is called with the error object.
 *
 * Returns nothing.
 */
Robot.prototype.error = function(callback) {
  return this.errorHandlers.push(callback);
};

/*
 * Calls and passes any registered error handlers for unhandled exceptions or
 * user emitted error events.
 *
 * err - An Error object.
 * msg - An optional Response object that generated the error
 *
 * Returns nothing.
 */
Robot.prototype.invokeErrorHandlers = function(err, msg) {
  this.logger.error(err.stack);

  var results = [];
  for (var i = 0; i < this.errorHandlers.length; i++) {
    try {
      results.push(this.errorHandlers[i](err, msg));
    }
    catch (err) {
      results.push(this.logger.error("while invoking error handler: " + err + "\n" + err.stack));
    }
  }
  return results;
};

/*
 * Public: Adds a Listener that triggers when no other text matchers match.
 *
 * callback - A Function that is called with a Response object.
 *
 * Returns nothing.
 */
Robot.prototype.catchAll = function(callback) {
  return this.listeners.catchall.push(new Listener(this, function(msg) {
    return true;
  }, function(msg) {
    msg.message = msg.message.message;
    return callback(msg);
  }));
};

/*
 * Check whether the message is addressed to brobbot.
 *
 * message - the message object to check
 *
 * Return boolean
 */
Robot.prototype.messageIsToMe = function(message) {
  if (this.alias) {
    this.aliasRegex = new RegExp("^\\s*@?" + this.alias + ":?\\s+", 'i');
  }
  else {
    this.aliasRegex = false;
  }
  return this.nameRegex.test(message.text) || (this.aliasRegex && this.aliasRegex.test(message.text));
};

/*
 * Public: Passes the given message to any interested Listeners.
 *
 * message - A Message instance. Listeners can flag this message as 'done' to
 *           prevent further execution.
 *
 * Returns nothing.
 */
Robot.prototype.receive = function(message) {
  var self = this;

  return this.connected.then(function() {
    var listeners = self.listeners[message._type];
    var matchedRespondListeners;

    message.isAddressedToBrobbot = self.messageIsToMe(message);

    var matchedListeners = _.filter(listeners, function(listener) {
      return listener.matches(message);
    });

    if (message.isAddressedToBrobbot) {
      //for respond listeners, chop off the brobbot's name/alias
      var respondText = message.text.replace(self.nameRegex, '');

      if (self.aliasRegex) {
        respondText = respondText.replace(self.aliasRegex, '');
      }

      var respondMessage = new TextMessage(message.user, respondText, message.id);
      respondMessage.isAddressedToBrobbot = message.isAddressedToBrobbot;

      matchedRespondListeners = _.filter(self.listeners.respond, function(listener) {
        return listener.matches(message);
      });
    }
    else {
      matchedRespondListeners = [];
    }

    console.log(matchedListeners, matchedRespondListeners);
    message.isBrobbotCommand = message.isAddressedToBrobbot && (matchedListeners.length > 0 || matchedRespondListeners.length > 0);

    _.each(matchedRespondListeners.concat(matchedListeners, self.listeners.catchall), function(listener) {
      listener.process(message);
      return !message.done;
    });
  });
};

Robot.prototype.loadScripts = function(scripts) {
  var self = this;

  return this.brainReady.then(function() {
    return Q.all(_.map(scripts, function(script) {
      return self.loadScript(script);
    }));
  });
};

Robot.prototype.loadScript = function(script) {
  var err;
  var path;

  try {
    path = "brobbot-" + script;
    require.resolve(path);
  }
  catch (_error) {
    err = _error;
    path = script;
  }

  try {
    return Q(require(path)(this.segment(script)));
  }
  catch (err) {
    return Q.reject(err);
  }
};

/*
 * Setup the Express server's defaults.
 *
 * Returns nothing.
 */
Robot.prototype.setupExpress = function() {
  var self = this;
  var user = process.env.EXPRESS_USER;
  var pass = process.env.EXPRESS_PASSWORD;
  var stat = process.env.EXPRESS_STATIC;
  var express = require('express');
  var app = express();

  app.use(function(req, res, next) {
    res.setHeader("X-Powered-By", "brobbot/" + self.name);
    return next();
  });

  if (user && pass) {
    app.use(express.basicAuth(user, pass));
  }

  app.use(express.query());
  app.use(express.bodyParser());

  if (stat) {
    app.use(express.static(stat));
  }

  try {
    this.server = app.listen(process.env.PORT || 8080, process.env.BIND_ADDRESS || '0.0.0.0');
    this.router = app;
  }
  catch (err) {
    this.logger.error("Error trying to start HTTP server: " + err + "\n" + err.stack);
    this.shutdown(1);
  }

  var herokuUrl = process.env.HEROKU_URL;
  if (herokuUrl) {
    if (!Url.parse(herokuUrl).protocol) {
      herokuUrl = 'http://' + herokuUrl;
    }
    if (!/\/$/.test(herokuUrl)) {
      herokuUrl += '/';
    }
    return this.pingIntervalId = setInterval(function() {
      return HttpClient.create(herokuUrl + "brobbot/ping").post()(function(err, res, body) {
        return self.logger.info('keep alive ping!');
      });
    }, 5 * 60 * 1000);
  }
};

/*
 * Setup an empty router object
 *
 * returns nothing
 */
Robot.prototype.setupNullRouter = function() {
  var self = this;
  var msg = "A script has tried registering a HTTP route while the HTTP server is disabled with --disabled-httpd.";

  return this.router = {
    get: function() {
      return self.logger.warning(msg);
    },
    post: function() {
      return self.logger.warning(msg);
    },
    put: function() {
      return self.logger.warning(msg);
    },
    delete: function() {
      return self.logger.warning(msg);
    }
  };
};

/*
 * Given a brain name, resolve to a module path
 *
 * brain - string brain name
 *
 * returns string path
 */
Robot.prototype.resolveBrain = function(brain) {
  var path = BROBBOT_DEFAULT_BRAINS.indexOf(brain) >= 0 ? "./brains/" + brain : "brobbot-" + brain + "-brain";

  try {
    require.resolve(path);
  }
  catch (err) {
    path = brain;
  }
  return path;
};

/*
 * Load the brain Brobbot is going to use.
 *
 * brain - A String of the brain name to use or a Brain constructor.
 *
 * Returns promise.
 */
Robot.prototype.loadBrain = function(brain) {
  brain = brain || 'dumb';

  this.logger.debug("Loading brain " + brain);

  if (_.isString(brain)) {
    path = this.resolveBrain(brain);
  }
  try {
    var BrainFn = _.isFunction(brain) && brain || require(path);
    this.brain = new BrainFn(this);
    return this.brain.ready || Q(this.brain);
  }
  catch (err) {
    this.logger.error("Cannot load brain " + brain + " - " + err.stack);
    return this.shutdown(1);
  }
};

/*
 * given an adapter name, resolve module path
 *
 * adapter - adapter name string
 *
 * returns string path
 */
Robot.prototype.resolveAdapter = function(adapter) {
  var path = BROBBOT_DEFAULT_ADAPTERS.indexOf(adapter) >= 0 ? "./adapters/" + adapter : "brobbot-" + adapter;

  try {
    require.resolve(path);
  }
  catch (err) {
    path = adapter;
  }
  return path;
};

/*
 * Load the adapter Brobbot is going to use.
 *
 * adapter - A String of the adapter name to use or an Adapter constructor.
 *
 * Returns promise.
 */
Robot.prototype.loadAdapter = function(adapter) {
  adapter = adapter || 'shell';

  this.logger.debug("Loading adapter " + adapter);

  if (_.isString(adapter)) {
    path = this.resolveAdapter(adapter);
  }

  try {
    var AdapterFn = _.isFunction(adapter) && adapter || require(path);
    this.adapter = new AdapterFn(this);
    return this.adapter.ready || Q(this.adapter);
  }
  catch (err) {
    this.logger.error("Cannot load adapter " + adapter + " - " + err.stack);
    return this.shutdown(1);
  }
};

/*
 * Public: Help Commands for Running Scripts.
 *
 * Returns an Array of help commands for running scripts.
 */
Robot.prototype.helpCommands = function() {
  return _.map(this.commands, function(command) {
    return command.command + ' - ' + command.description;
  });
};

/*
 * Public: add a help command
 */
Robot.prototype.helpCommand = function(command, description) {
  return this.commands.push({
    command: command,
    description: description
  });
};

/*
 * Public: A helper send function which delegates to the adapter's send
 * function.
 *
 * user    - A User instance.
 * strings - One or more Strings for each message to send.
 *
 * Returns nothing.
 */
Robot.prototype.send = function(user /*, *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  return this.adapter.send.apply(this.adapter, [user].concat(Array.prototype.slice.call(strings)));
};

/*
 * Public: A helper reply function which delegates to the adapter's reply
 * function.
 *
 * user    - A User instance.
 * strings - One or more Strings for each message to send.
 *
 * Returns nothing.
 */
Robot.prototype.reply = function(user /*, *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  return this.adapter.reply.apply(this.adapter, [user].concat(Array.prototype.slice.call(strings)));
};

/*
 * Public: A helper send function to message a room that the robot is in.
 *
 * room    - String designating the room to message.
 * strings - One or more Strings for each message to send.
 *
 * Returns nothing.
 */
Robot.prototype.messageRoom = function(room /*, *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  var user = {room: room};
  return this.adapter.send.apply(this.adapter, [user].concat(Array.prototype.slice.call(strings)));
};

/*
 * Public: A wrapper around the EventEmitter API to make usage
 * semanticly better.
 *
 * event    - The event name.
 * listener - A Function that is called with the event parameter
 *            when event happens.
 *
 * Returns nothing.
 */
Robot.prototype.on = function(event /*, *args */) {
  var args = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  return this.events.on.apply(this.events, [event].concat(Array.prototype.slice.call(args)));
};

/*
 * Public: A wrapper around the EventEmitter API to make usage
 * semanticly better.
 *
 * event   - The event name.
 * args...  - Arguments emitted by the event
 *
 * Returns nothing.
 */
Robot.prototype.emit = function(event /*, *args */) {
  var args = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  return this.events.emit.apply(this.events, [event].concat(Array.prototype.slice.call(args)));
};

/*
 * Public: Kick off the event loop for the adapter
 *
 * Returns nothing.
 */
Robot.prototype.run = function() {
  var self = this;

  return this.ready.then(function() {
    self.emit("running");
    return self.adapter.run();
  });
};

/*
 * Public: Gracefully shutdown the robot process
 *
 * Returns nothing.
 */
Robot.prototype.shutdown = function(exitCode) {
  var closing = [];

  this.logger.info("shutting down...");

  if (this.pingIntervalId !== undefined) {
    clearInterval(this.pingIntervalId);
  }

  if (this.adapter) {
    closing.push(this.adapter.close());
  }

  if (this.brain) {
    closing.push(this.brain.close());
  }

  return Q.all(closing).fin(function() {
    return process.exit(exitCode || 0);
  });
};

/*
 * Parse the brobbot version from package.json
 *
 * Returns string
 */
Robot.prototype.parseVersion = function() {
  return this.version = require('../package.json').version;
};

/*
 * Public: Creates a scoped http client with chainable methods for
 * modifying the request. This doesn't actually make a request though.
 * Once your request is assembled, you can call `get()`/`post()`/etc to
 * send the request.
 *
 * url - String URL to access.
 *
 * Examples:
 *
 *     res.http("http://example.com")
 *       // set a single header
 *       .header('Authorization', 'bearer abcdef')
 *
 *       // set multiple headers
 *       .headers(Authorization: 'bearer abcdef', Accept: 'application/json')
 *
 *       // add URI query parameters
 *       .query(a: 1, b: 'foo & bar')
 *
 *       // make the actual request
 *       .get() (err, res, body) ->
 *         console.log body
 *
 *       // or, you can POST data
 *       .post(data) (err, res, body) ->
 *         console.log body
 *
 * Returns a ScopedClient instance.
 */
Robot.prototype.http = function(url) {
  return HttpClient.create(url).header('User-Agent', "Brobbot/" + this.version);
};

/*
 * Return a robot with a name-spaced brain segment
 *
 * segmentName - the name-space to use
 *
 * Returns RobotSegment
 */
Robot.prototype.segment = function(segmentName) {
  return new RobotSegment(this, segmentName);
};

module.exports = Robot;
