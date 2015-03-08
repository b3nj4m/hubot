var Robot = require('../src/robot');
var brainTests = require('./brain');
var DumbBrain = require('../src/brains/dumb');

brainTests('dumb', new DumbBrain(new Robot()));
