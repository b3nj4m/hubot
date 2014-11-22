Brain = require './brain'

class RedisBrain extends Brain
  constructor: (robot, prefix, client) ->
    @prefix = prefix or ''
    @client = client

  get: (key) ->
    @client.get(prefix, key)

  set: (key, value) ->
    @client.set(prefix, key, value)

module.exports = RedisBrain
