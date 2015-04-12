var Readline = require('readline');
var Robot = require('../robot');
var Adapter = require('../adapter');
var TextMessage = require('../message').TextMessage;
var Q = require('q');

function Shell(robot) {
  Adapter.apply(this, arguments);

  this.robot = robot;
  this.readyDefer = Q.defer();
  this.ready = this.readyDefer.promise;
}

Shell.prototype = Object.create(Adapter.prototype);
Shell.prototype.constructor = Shell;

Shell.prototype.send = function(envelope /*, *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  var str;
  var i;

  if (process.platform !== 'win32') {
    for (i = 0; i < strings.length; i++) {
      console.log("\x1b[01;32m" + strings[i] + "\x1b[0m");
    }
  }
  else {
    for (i = 0; i < strings.length; i++) {
      console.log(strings[i].toString());
    }
  }
  return this.repl.prompt();
};

Shell.prototype.emote = function(envelope /*, *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  var results = [];

  for (var i = 0; i < strings.length; i++) {
    results.push(this.send(envelope, "* " + strings[i]));
  }
  return results;
};

Shell.prototype.reply = function(envelope /*, *strings */) {
  var strings = 2 <= arguments.length ? Array.prototype.slice.call(arguments, 1) : [];
  strings = strings.map(function(s) {
    return envelope.user.name + ": " + s;
  });
  return this.send.apply(this, [envelope].concat(Array.prototype.slice.call(strings)));
};

Shell.prototype.run = function() {
  var self = this;
  var stdin = process.openStdin();
  var stdout = process.stdout;

  this.repl = Readline.createInterface(stdin, stdout, null);

  this.repl.on('close', function() {
    stdin.destroy();
    self.robot.shutdown();
    return process.exit(0);
  });

  this.repl.on('line', function(buffer) {
    if (buffer.toLowerCase() === 'exit') {
      self.repl.close();
    }

    self.repl.prompt();

    return self.robot.brain.userForId('1', {
      name: 'Shell',
      room: 'Shell'
    }).then(function(user) {
      return self.receive(new TextMessage(user, buffer, 'messageId'));
    });
  });

  this.readyDefer.resolve(this);
  this.repl.setPrompt(this.robot.name + "> ");

  return this.repl.prompt();
};

module.exports = Shell;
