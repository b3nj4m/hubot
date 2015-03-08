var User = require('../src/user');
var assert = require('assert');

describe('user', function() {
  it('should assign id, name, type', function() {
    var user = new User("Fake User", {name: 'fake', type: "groupchat"});
    assert.equal("Fake User", user.id);
    assert.equal("groupchat", user.type);
    assert.equal("fake", user.name);
  });

  it('should assign default name, id, room, type', function() {
    var user = new User("Fake User", {room: "chat@room.jabber", type: "groupchat"});
    assert.equal("Fake User", user.id);
    assert.equal("chat@room.jabber", user.room);
    assert.equal("groupchat", user.type);
    assert.equal("Fake User", user.name); // Make sure that if no name is given, we fallback to the ID
  });

  it('should assign default name as string', function() {
    var user = new User(12345);
    assert.strictEqual(12345, user.id);
    assert.strictEqual("12345", user.name);
  });
});
