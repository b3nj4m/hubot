process.env.EXPRESS_STATIC = 'test/static/'
Tests = require './tests'
assert = require 'assert'
helper = Tests.helper()

helper.adapter.cb = (msg) ->
    assert.equal(1, helper.sent.length)
    assert.equal("static\n", msg)
    helper.logger.info('passed!')
    helper.stop()

setTimeout( () ->
    helper.adapter.receive('static')
, 100)

