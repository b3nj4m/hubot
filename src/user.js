var _ = require('lodash');

/*
 * Represents a participating user in the chat.
 *
 * id      - A unique ID for the user.
 * options - An optional Hash of key, value pairs for this user.
 */
function User(id, options) {
  this.id = id;

  options = options || {};

  _.extend(this, options);

  this.name = this.name || this.id.toString();
}

module.exports = User;
