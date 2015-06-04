var Url = require('url');
var Path = require('path');
var Robot = require('../src/robot');
var Adapter = require('../src/adapter');
var User = require('../src/user');
var Response = require('../src/response');
var TextMessage = require('../src/message').TextMessage;

function Helper(scripts) {
  Robot.call(this, scripts, Danger, null, true, 'helper');
  this.id = 1;
  this.Response = Helper.Response;
  this.sent = [];
  this.recipients = [];
  this.alias = 'alias';
}

Helper.prototype = Object.create(Robot.prototype);
Helper.prototype.constructor = Helper;

Helper.prototype.stop = function() {
  return process.exit(0);
};

Helper.prototype.run = function() {
  var self = this;

  return Robot.prototype.run.call(this).then(function() {
    self.server = require('http').createServer(function(req, res) {
      return res.end('static');
    });

    self.server.listen(9001);

    return self.server.on('close', function() {
      return self.close();
    });
  });
};

Helper.prototype.reset = function() {
  this.sent = [];
  return this.recipients = [];
};

function Danger() {
  Adapter.apply(this, arguments);
}

Danger.prototype = Object.create(Adapter.prototype);
Danger.prototype.constructor = Danger;

Danger.prototype.send = function(user /* *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];

  this.robot.sent = this.robot.sent.concat(strings);

  for (var i = 0; i < strings.length; i++) {
    this.robot.recipients.push(user);
  }
  return typeof this.cb === "function" ? this.cb.apply(this, strings) : null;
};

Danger.prototype.reply = function(user /*, *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  var results = [];

  for (var i = 0; i < strings.length; i++) {
    results.push(this.send(user, this.robot.name + ": " + strings[i]));
  }
  return results;
};

Danger.prototype.receive = function(text) {
  var user;
  if (typeof text === 'string') {
    return Adapter.prototype.receive.call(this, new TextMessage(new User(1, {name: 'helper'}), text));
  }
  else {
    return Adapter.prototype.receive.call(this, text);
  }
};

if (!process.env.BROBBOT_LIVE) {
  Helper.Response = function() {
    Response.apply(this, arguments);
  }

  Helper.Response.prototype = Object.create(Response.prototype);
  Helper.Response.prototype.constructor = Helper.Response;

  //This changes ever HTTP request to hit the danger server above
  Helper.Response.prototype.http = function(url) {
    return Response.prototype.http.call(this, url).host('127.0.0.1').port(9001);
  };
}

module.exports = new Helper(['../test/scripts/test']);

module.exports.run();
