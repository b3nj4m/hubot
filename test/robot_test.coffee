Tests  = require './tests'
assert = require 'assert'
helper = Tests.helper()

server = require('http').createServer (req, res) ->
  res.writeHead 200
  res.end "fetched"

server.listen 9001, ->
  test = helper.ready.then ->
    assert.equal(6, helper.listeners.length)
    assert.equal(1, helper.respondListeners.length)
    assert.equal(0, helper.sent.length)

    sent = helper.adapter.receive('test').then ->
      assert.equal(1, helper.sent.length)
      assert.equal('OK', helper.sent[0])

    sent = sent.then ->
      helper.adapter.receive('reply').then ->
        assert.equal(2, helper.sent.length)
        assert.equal('helper: OK', helper.sent[1])

    sent = sent.then ->
      helper.adapter.receive('random').then ->
        assert.equal(3, helper.sent.length)
        assert.ok(helper.sent[2].match(/^(1|2)$/))

    sent = sent.then ->
      # Test that when we message a room, the 'recipient' is the robot user and the room attribute is set properly
      helper.messageRoom("chat@example.com", "Hello room")
      assert.equal(4, helper.sent.length)
      assert.equal("chat@example.com", helper.recipients[3].room)
      assert.equal("Hello room", helper.sent[3])

    sent = sent.then ->
      helper.messageRoom("chat2@example.com", "Hello to another room")
      assert.equal(5, helper.sent.length)
      assert.equal("chat2@example.com", helper.recipients[4].room)
      assert.equal("Hello to another room", helper.sent[4])

    sent = sent.then ->
      helper.adapter.receive('foobar').then ->
        assert.equal(6, helper.sent.length)
        assert.equal('catch-all', helper.sent[5])

    sent = sent.then ->
      # Testing replies
      # ============================
      # Using just the name
      helper.adapter.receive("#{helper.name} rsvp").then ->
        assert.equal(7, helper.sent.length)
        assert.equal("responding", helper.sent[6])

    sent = sent.then ->
      # Using name with @ form
      helper.adapter.receive("@#{helper.name} rsvp").then ->
        assert.equal(8, helper.sent.length)
        assert.equal("responding", helper.sent[7])

    sent = sent.then ->
      # Using just the alias
      helper.adapter.receive("#{helper.alias} rsvp").then ->
        assert.equal(9, helper.sent.length)
        assert.equal("responding", helper.sent[8])

    sent = sent.then ->
      # Using alias with @ form
      helper.adapter.receive("@#{helper.alias} rsvp").then ->
        assert.equal(10, helper.sent.length)
        assert.equal("responding", helper.sent[9])


    # set a callback for when the next message is replied to
    helper.cb = (msg) ->
      assert.equal 7, helper.sent.length
      assert.equal 'fetched', msg
      helper.close()
      server.close()

    helper.adapter.receive('http')
    sent

  test.then ->
    helper.logger.info('passed!')
    helper.stop()

  test.fail (err) ->
    helper.logger.error(err.stack)
    helper.stop()

