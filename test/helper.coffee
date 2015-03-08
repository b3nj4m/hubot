Url           = require 'url'
Path          = require 'path'

Robot         = require '../src/robot'
Adapter       = require '../src/adapter'
User          = require '../src/user'
Response      = require '../src/response'
{TextMessage} = require '../src/message'


class Helper extends Robot
  constructor: (scripts) ->
    super scripts, Danger, null, true, 'helper'
    @id = 1
    @Response = Helper.Response
    @sent = []
    @recipients = []
    @alias = 'alias'

  stop: ->
    process.exit(0)

  run: ->
    super().then =>
      @server = require('http').createServer((req, res) => res.end('static'))
      @server.listen(9001)
      @server.on('close', => @close())

  reset: ->
    @sent = []
    @recipients = []

class Danger extends Adapter
  send: (user, strings...) ->
    @robot.sent.push.apply(@robot.sent, strings)
    for string in strings
      @robot.recipients.push(user)
    @cb?(strings...)

  reply: (user, strings...) ->
    @send user, "#{@robot.name}: #{str}" for str in strings

  receive: (text) ->
    if typeof text is 'string'
      user = new User 1, name: 'helper'
      super new TextMessage user, text
    else
      super text

if not process.env.BROBBOT_LIVE
  class Helper.Response extends Response
    # This changes ever HTTP request to hit the danger server above
    http: (url) ->
      super(url).host('127.0.0.1').port(9001)

module.exports = new Helper(['../test/scripts/test'])
module.exports.run()
