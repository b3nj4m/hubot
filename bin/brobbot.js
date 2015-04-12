#!/usr/bin/env node

var Q = require('q');
var Brobbot = require('..');
var Fs = require('fs');
var OptParse = require('optparse');
var Path = require('path');

var Switches = [
  ["-b", "--brain BRAIN", "The Brain to use"],
  ["-a", "--adapter ADAPTER", "The Adapter to use"],
  ["-s", "--scripts SCRIPTS", "comma-separated list of scripts to load"],
  ["-c", "--create PATH", "Create a deployable brobbot"],
  ["-d", "--disable-httpd", "Disable the HTTP server"],
  ["-h", "--help", "Display the help information"],
  ["-l", "--alias ALIAS", "Enable replacing the robot's name with alias"],
  ["-n", "--name NAME", "The name of the robot in chat"],
  ["-t", "--config-check", "Test brobbot's config to make sure it won't fail at startup"],
  ["-v", "--version", "Displays the version of brobbot installed"]
];

var Options = {
  brain: process.env.BROBBOT_BRAIN || "dumb",
  adapter: process.env.BROBBOT_ADAPTER || "shell",
  alias: process.env.BROBBOT_ALIAS || false,
  create: process.env.BROBBOT_CREATE || false,
  enableHttpd: process.env.BROBBOT_HTTPD || true,
  scripts: process.env.BROBBOT_SCRIPTS || "",
  name: process.env.BROBBOT_NAME || "Brobbot",
  path: process.env.BROBBOT_PATH || ".",
  configCheck: false
};

if (Options.scripts) {
  Options.scripts = Options.scripts.split(',');
} else {
  Options.scripts = [];
}

Options.scripts.push('./scripts/help');

var Parser = new OptParse.OptionParser(Switches);
Parser.banner = "Usage brobbot [options]";

Parser.on("brain", function(opt, value) {
  return Options.brain = value;
});

Parser.on("adapter", function(opt, value) {
  return Options.adapter = value;
});

Parser.on("create", function(opt, value) {
  Options.path = value;
  return Options.create = true;
});

Parser.on("disable-httpd", function(opt) {
  return Options.enableHttpd = false;
});

Parser.on("help", function(opt, value) {
  console.log(Parser.toString());
  return process.exit(0);
});

Parser.on("alias", function(opt, value) {
  value = value || '/';
  return Options.alias = value;
});

Parser.on("name", function(opt, value) {
  return Options.name = value;
});

Parser.on("scripts", function(opt, value) {
  return Options.scripts = Options.scripts.concat(value.split(','));
});

Parser.on("config-check", function(opt) {
  return Options.configCheck = true;
});

Parser.on("version", function(opt, value) {
  return Options.version = true;
});

Parser.parse(process.argv);

if (process.platform !== "win32") {
  process.on('SIGTERM', function() {
    return process.exit(0);
  });
}

if (Options.version) {
  console.log(require('../package.json').version);
  process.exit(0);
}

var robot = Brobbot.loadBot(Options.scripts, Options.adapter, Options.brain, Options.enableHttpd, Options.name);
robot.alias = Options.alias;

robot.run().fail(function(err) {
  return robot.shutdown(1);
});
