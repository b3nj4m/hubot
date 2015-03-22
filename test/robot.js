var assert = require('assert');
var helper = require('./helper');

describe('robot', function() {
  before(function() {
    return helper.ready;
  });

  after(function() {
    helper.reset();
  });

  it('should have correct number of listeners', function() {
    assert.equal(4, helper.listeners.text.length);
    assert.equal(1, helper.listeners.respond.length);
    assert.equal(0, helper.sent.length);
  });

  it('should receive "test"', function() {
    return helper.adapter.receive('test').then(function() {
      assert.equal(1, helper.sent.length);
      assert.equal('OK', helper.sent[0]);
    });
  });

  it('should receive "reply"', function() {
    return helper.adapter.receive('reply').then(function() {
      assert.equal(2, helper.sent.length);
      assert.equal('helper: OK', helper.sent[1]);
    });
  });

  it('should receive "random"', function() {
    return helper.adapter.receive('random').then(function() {
      assert.equal(3, helper.sent.length);
      assert.ok(helper.sent[2].match(/^(1|2)$/));
    });
  });

  it('should send to room', function() {
    //Test that when we message a room, the 'recipient' is the robot user and the room attribute is set properly
    helper.messageRoom("chat@example.com", "Hello room");
    assert.equal(4, helper.sent.length);
    assert.equal("chat@example.com", helper.recipients[3].room);
    assert.equal("Hello room", helper.sent[3]);
  });

  it('should send to room again', function() {
    helper.messageRoom("chat2@example.com", "Hello to another room");
    assert.equal(5, helper.sent.length);
    assert.equal("chat2@example.com", helper.recipients[4].room);
    assert.equal("Hello to another room", helper.sent[4]);
  });

  it('should receive "foobar" as catch-all', function() {
    return helper.adapter.receive('foobar').then(function() {
      assert.equal(6, helper.sent.length);
      assert.equal('catch-all', helper.sent[5]);
    });
  });

  // Testing replies
  it('should reply to "rsvp"', function() {
    return helper.adapter.receive(helper.name + " rsvp").then(function() {
      assert.equal(7, helper.sent.length);
      assert.equal("responding", helper.sent[6]);
    });
  });

  it('should reply to "rsvp" with @', function() {
    // Using name with @ form
    return helper.adapter.receive("@" + helper.name + " rsvp").then(function() {
      assert.equal(8, helper.sent.length);
      assert.equal("responding", helper.sent[7]);
    });
  });

  it('should reply to "rsvp" with alias', function() {
    // Using just the alias
    return helper.adapter.receive(helper.alias + " rsvp").then(function() {
      assert.equal(9, helper.sent.length);
      assert.equal("responding", helper.sent[8]);
    });
  });

  it('should reply to "rsvp" with @alias', function() {
    // Using alias with @ form
    return helper.adapter.receive("@" + helper.alias + " rsvp").then(function() {
      assert.equal(10, helper.sent.length);
      assert.equal("responding", helper.sent[9]);
    });
  });
});
