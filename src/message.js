/*
 * Represents an incoming message from the chat.
 *
 * user - A User instance that sent the message.
 */
function Message(user, done) {
  this.user = user;
  this.done = done || false;
  this.room = this.user.room;
}

Message.prototype._type = 'message';

/*
 * Indicates that no other Listener should be called on this object
 *
 * Returns nothing.
 */
Message.prototype.finish = function() {
  return this.done = true;
};

/*
 * Represents an incoming message from the chat.
 *
 * user - A User instance that sent the message.
 * text - A String message.
 * id   - A String of the message ID.
 */
function TextMessage(user, text, id) {
  Message.call(this, user);

  this.user = user;
  this.text = text;
  this.id = id;
}

TextMessage.prototype = Object.create(Message.prototype);
TextMessage.prototype.constructor = TextMessage;

TextMessage.prototype._type = 'text';

/*
 * Determines if the message matches the given regex.
 *
 * regex - A Regex to check.
 *
 * Returns a Match object or null.
 */
TextMessage.prototype.match = function(regex) {
  return this.text.match(regex);
};

/*
 * String representation of a TextMessage
 *
 * Returns the message text
 */
TextMessage.prototype.toString = function() {
  return this.text;
};

/*
 * Represents an incoming user entrance notification.
 *
 * user - A User instance for the user who entered.
 * text - Always null.
 * id   - A String of the message ID.
 */

function EnterMessage(user) {
  Message.call(this, user);
}

EnterMessage.prototype = Object.create(Message.prototype);
EnterMessage.prototype.constructor = EnterMessage;

EnterMessage.prototype._type = 'enter';

/*
 * Represents an incoming user exit notification.
 *
 * user - A User instance for the user who left.
 * text - Always null.
 * id   - A String of the message ID.
 */
function LeaveMessage(user) {
  Message.call(this, user);
}

LeaveMessage.prototype = Object.create(Message.prototype);
LeaveMessage.prototype.constructor = LeaveMessage;

LeaveMessage.prototype._type = 'leave';

/*
 * Represents an incoming topic change notification.
 *
 * user - A User instance for the user who changed the topic.
 * text - A String of the new topic
 * id   - A String of the message ID.
 */
function TopicMessage(user) {
  Message.call(this, user);
}

TopicMessage.prototype = Object.create(Message.prototype);
TopicMessage.prototype.constructor = TopicMessage;

TopicMessage.prototype._type = 'topic';

module.exports = {
  Message: Message,
  TextMessage: TextMessage,
  EnterMessage: EnterMessage,
  LeaveMessage: LeaveMessage,
  TopicMessage: TopicMessage
};
