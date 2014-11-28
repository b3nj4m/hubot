Q = require 'q'
{inspect} = require 'util'

{TextMessage} = require './message'

#TODO hooks for testing expected responses
class Listener
  queueSize: 100

  # Listeners receive every message from the chat source and decide if they
  # want to act on it.
  #
  # robot    - A Robot instance.
  # matcher  - A Function that determines if this listener should trigger the
  #            callback.
  # callback - A Function that is triggered if the incoming message matches.
  constructor: (@robot, @matcher, @callback) ->
    @queue = []
    @inProgress = Q()

  # Public: Determines if the listener likes the content of the message. If
  # so, a Response built from the given Message is queued for processing.
  #
  # message - A Message instance.
  #
  # Returns false or the result of queueing the response
  call: (message) ->
    if match = @matcher message
      @robot.logger.debug \
        "Message '#{message}' matched regex /#{inspect @regex}/" if @regex

      @enqueue new @robot.Response(@robot, message, match)
    else
      false

  # Public: queue a response for processing
  #
  # Returns result of exec or nothing.
  enqueue: (response) ->
    if @inProgress.isPending() or @queue.length > 0
      if @queue.length is @queueSize
        @queue.shift()

      @queue.push response
    else
      return @exec response

  # Public: process the reponse queue
  #
  # Returns: nothing.
  exec: (response) ->
    @inProgress = @callback response
    if not @inProgress or not Q.isPromise @inProgress
      @inProgress = Q(@inProgress)

    @inProgress.finally =>
      if @queue.length > 0
        @exec @queue.shift()

    @inProgress

class TextListener extends Listener
  # TextListeners receive every message from the chat source and decide if they
  # want to act on it.
  #
  # robot    - A Robot instance.
  # regex    - A Regex that determines if this listener should trigger the
  #            callback.
  # callback - A Function that is triggered if the incoming message matches.
  constructor: (@robot, @regex, @callback) ->
    super(@robot, @regex, @callback)

    @matcher = (message) =>
      if message instanceof TextMessage
        message.match @regex

module.exports = {
  Listener
  TextListener
}
