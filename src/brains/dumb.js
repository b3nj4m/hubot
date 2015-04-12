var Brain = require('../brain');

function Dumb() {
  Brain.apply(this, arguments);
}

Dumb.prototype = Object.create(Brain.prototype);
Dumb.prototype.constructor = Dumb;

module.exports = Dumb;
