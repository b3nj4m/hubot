_ = require 'lodash'
Q              = require 'q'
Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require 'scoped-http-client'
{EventEmitter} = require 'events'

User = require './user'
RobotSegment = require './robot-segment'
Response = require './response'
{Listener,TextListener} = require './listener'
{EnterMessage,LeaveMessage,TopicMessage,CatchAllMessage,TextMessage} = require './message'

BROBBOT_DEFAULT_ADAPTERS = [
  'campfire'
  'shell'
]

BROBBOT_DEFAULT_BRAINS = [
  'dumb'
]

BROBBOT_DOCUMENTATION_SECTIONS = [
  'description'
  'dependencies'
  'configuration'
  'commands'
  'notes'
  'author'
  'authors'
  'examples'
  'tags'
  'urls'
]

class Robot
  # Robots receive messages from a chat source (Campfire, irc, etc), and
  # dispatch them to matching listeners.
  #
  # scripts     - An array of modules to load
  # adapterPath - A String of the path to local adapters.
  # adapter     - A String of the adapter name.
  # brainPath - A String of the path to local brains.
  # brain     - A String of the brain name.
  # httpd       - A Boolean whether to enable the HTTP daemon.
  # name        - A String of the robot name, defaults to Brobbot.
  #
  # Returns nothing.
  constructor: (scripts, adapterPath, adapter, brainPath, brain, httpd, name = 'Brobbot') ->
    @name      = name
    @nameRegex = new RegExp "^\\s*#{name}:?\\s+", 'i'
    @events    = new EventEmitter
    @alias     = false
    @adapter   = null
    @Response  = Response
    @commands  = []
    @listeners = []
    @respondListeners = []
    #TODO namespaced logger per-script
    @logger    = new Log process.env.BROBBOT_LOG_LEVEL or 'info'
    @pingIntervalId = null

    @parseVersion()
    if httpd
      @setupExpress()
    else
      @setupNullRouter()

    @brainReady = @loadBrain brainPath, brain
    @scriptsReady = @loadScripts scripts
    @adapterReady = @loadAdapter adapterPath, adapter

    @ready = Q.all [@brainReady, @scriptsReady]
    @connected = @adapterReady

    @adapterName = adapter
    @errorHandlers = []

    @on 'error', (err, msg) =>
      @invokeErrorHandlers(err, msg)
    process.on 'uncaughtException', (err) =>
      @logger.error err.stack
      @emit 'error', err


  # Public: Adds a Listener that attempts to match incoming messages based on
  # a Regex.
  #
  # regex    - A Regex that determines if the callback should be called.
  # callback - A Function that is called with a Response object.
  #
  # Returns nothing.
  hear: (regex, callback) ->
    @listeners.push new TextListener(@, regex, callback)

  # Public: Adds a Listener that attempts to match incoming messages directed
  # at the robot based on a Regex. All regexes treat patterns like they begin
  # with a '^'
  #
  # regex    - A Regex that determines if the callback should be called.
  # callback - A Function that is called with a Response object.
  #
  # Returns nothing.
  respond: (regex, callback) ->
    @respondListeners.push new TextListener(@, regex, callback)

  # Public: Adds a Listener that triggers when anyone enters the room.
  #
  # callback - A Function that is called with a Response object.
  #
  # Returns nothing.
  enter: (callback) ->
    @listeners.push new Listener(
      @,
      ((msg) -> msg instanceof EnterMessage),
      callback
    )

  # Public: Adds a Listener that triggers when anyone leaves the room.
  #
  # callback - A Function that is called with a Response object.
  #
  # Returns nothing.
  leave: (callback) ->
    @listeners.push new Listener(
      @,
      ((msg) -> msg instanceof LeaveMessage),
      callback
    )

  # Public: Adds a Listener that triggers when anyone changes the topic.
  #
  # callback - A Function that is called with a Response object.
  #
  # Returns nothing.
  topic: (callback) ->
    @listeners.push new Listener(
      @,
      ((msg) -> msg instanceof TopicMessage),
      callback
    )

  # Public: Adds an error handler when an uncaught exception or user emitted
  # error event occurs.
  #
  # callback - A Function that is called with the error object.
  #
  # Returns nothing.
  error: (callback) ->
    @errorHandlers.push callback

  # Calls and passes any registered error handlers for unhandled exceptions or
  # user emitted error events.
  #
  # err - An Error object.
  # msg - An optional Response object that generated the error
  #
  # Returns nothing.
  invokeErrorHandlers: (err, msg) ->
    @logger.error err.stack
    for errorHandler in @errorHandlers
     try
       errorHandler(err, msg)
     catch errErr
       @logger.error "while invoking error handler: #{errErr}\n#{errErr.stack}"

  # Public: Adds a Listener that triggers when no other text matchers match.
  #
  # callback - A Function that is called with a Response object.
  #
  # Returns nothing.
  catchAll: (callback) ->
    @listeners.push new Listener(
      @,
      ((msg) -> msg instanceof CatchAllMessage),
      ((msg) -> msg.message = msg.message.message; callback msg)
    )

  messageIsToMe: (message) ->
    if @alias
      @aliasRegex = new RegExp "^\\s*#{@alias}:?\\s+", 'i'
    else
      @aliasRegex = false

    @nameRegex.test message.text or (@aliasRegex and @aliasRegex.test message.text)

  # Public: Passes the given message to any interested Listeners.
  #
  # message - A Message instance. Listeners can flag this message as 'done' to
  #           prevent further execution.
  #
  # Returns nothing.
  receive: (message) ->
    @connected.then =>
      matched = false

      message.isAddressedToBrobbot = @messageIsToMe message

      for listener in @listeners
        try
          matched = listener.call(message) or matched
          break if message.done
        catch error
          @emit('error', error, new @Response(@, message, []))

      if message.isAddressedToBrobbot
        #for respond listeners, chop off the brobbot's name/alias
        respondText = message.text.replace @nameRegex, ''

        if @aliasRegex
          respondText = respondText.replace @aliasRegex, ''

        respondMessage = new TextMessage message.user, respondText, message.id
        respondMessage.isAddressedToBrobbot = message.isAddressedToBrobbot

        for listener in @respondListeners
          try
            matched = listener.call(respondMessage) or matched
            break if respondMessage.done
          catch error
            @emit('error', error, new @Response(@, respondMessage, []))

      if message not instanceof CatchAllMessage and not matched
        @receive new CatchAllMessage(message)

  loadScripts: (scripts) ->
    @brainReady.then =>
      Q.all _.map scripts, (script) =>
        Q(require("brobbot-#{script}")(@segment(script)))

  # Setup the Express server's defaults.
  #
  # Returns nothing.
  setupExpress: ->
    user    = process.env.EXPRESS_USER
    pass    = process.env.EXPRESS_PASSWORD
    stat    = process.env.EXPRESS_STATIC

    express = require 'express'

    app = express()

    app.use (req, res, next) =>
      res.setHeader "X-Powered-By", "brobbot/#{@name}"
      next()

    app.use express.basicAuth user, pass if user and pass
    app.use express.query()
    app.use express.bodyParser()
    app.use express.static stat if stat

    try
      @server = app.listen(process.env.PORT || 8080, process.env.BIND_ADDRESS || '0.0.0.0')
      @router = app
    catch err
      @logger.error "Error trying to start HTTP server: #{err}\n#{err.stack}"
      process.exit(1)

    herokuUrl = process.env.HEROKU_URL

    if herokuUrl
      herokuUrl += '/' unless /\/$/.test herokuUrl
      @pingIntervalId = setInterval =>
        HttpClient.create("#{herokuUrl}brobbot/ping").post() (err, res, body) =>
          @logger.info 'keep alive ping!'
      , 5 * 60 * 1000

  # Setup an empty router object
  #
  # returns nothing
  setupNullRouter: ->
    msg = "A script has tried registering a HTTP route while the HTTP server is disabled with --disabled-httpd."
    @router =
      get: ()=> @logger.warning msg
      post: ()=> @logger.warning msg
      put: ()=> @logger.warning msg
      delete: ()=> @logger.warning msg


  # Load the brain Brobbot is going to use.
  #
  # path    - A String of the path to brain if local.
  # brain - A String of the brain name to use.
  #
  # Returns promise.
  loadBrain: (path, brain) ->
    @logger.debug "Loading brain #{brain}"

    try
      path = if brain in BROBBOT_DEFAULT_BRAINS
        "#{path}/#{brain}"
      else
        "brobbot-#{brain}-brain"

      @brain = new (require(path)) @
      return @brain.ready or Q(@brain)
    catch err
      @logger.error "Cannot load brain #{brain} - #{err.stack}"
      process.exit(1)

  # Load the adapter Brobbot is going to use.
  #
  # path    - A String of the path to adapter if local.
  # adapter - A String of the adapter name to use.
  #
  # Returns promise.
  loadAdapter: (path, adapter) ->
    @logger.debug "Loading adapter #{adapter}"

    try
      path = if adapter in BROBBOT_DEFAULT_ADAPTERS
        "#{path}/#{adapter}"
      else
        "brobbot-#{adapter}"

      @adapter = require(path).use @
      return @adapter.ready or Q(@adapter)
    catch err
      @logger.error "Cannot load adapter #{adapter} - #{err.stack}"
      process.exit(1)

  # Public: Help Commands for Running Scripts.
  #
  # Returns an Array of help commands for running scripts.
  helpCommands: ->
    commands = _.map @commands, (command) ->
      command.command + ' - ' + command.description
    commands.sort()

  # Public: add a help command
  helpCommand: (command, description) ->
    @commands.push command: command, description: description

  # Public: A helper send function which delegates to the adapter's send
  # function.
  #
  # user    - A User instance.
  # strings - One or more Strings for each message to send.
  #
  # Returns nothing.
  send: (user, strings...) ->
    @adapter.send user, strings...

  # Public: A helper reply function which delegates to the adapter's reply
  # function.
  #
  # user    - A User instance.
  # strings - One or more Strings for each message to send.
  #
  # Returns nothing.
  reply: (user, strings...) ->
    @adapter.reply user, strings...

  # Public: A helper send function to message a room that the robot is in.
  #
  # room    - String designating the room to message.
  # strings - One or more Strings for each message to send.
  #
  # Returns nothing.
  messageRoom: (room, strings...) ->
    user = { room: room }
    @adapter.send user, strings...

  # Public: A wrapper around the EventEmitter API to make usage
  # semanticly better.
  #
  # event    - The event name.
  # listener - A Function that is called with the event parameter
  #            when event happens.
  #
  # Returns nothing.
  on: (event, args...) ->
    @events.on event, args...

  # Public: A wrapper around the EventEmitter API to make usage
  # semanticly better.
  #
  # event   - The event name.
  # args...  - Arguments emitted by the event
  #
  # Returns nothing.
  emit: (event, args...) ->
    @events.emit event, args...

  # Public: Kick off the event loop for the adapter
  #
  # Returns nothing.
  run: ->
    require('./scripts/help') @
    @emit "running"
    @adapter.run()

  # Public: Gracefully shutdown the robot process
  #
  # Returns nothing.
  shutdown: ->
    clearInterval @pingIntervalId if @pingIntervalId?
    @adapter.close()
    @brain.close()
    
    if @redisClient
      @redisClient.close()

  # Public: The version of Brobbot from npm
  #
  # Returns a String of the version number.
  parseVersion: ->
    pkg = require Path.join __dirname, '..', 'package.json'
    @version = pkg.version

  # Public: Creates a scoped http client with chainable methods for
  # modifying the request. This doesn't actually make a request though.
  # Once your request is assembled, you can call `get()`/`post()`/etc to
  # send the request.
  #
  # url - String URL to access.
  #
  # Examples:
  #
  #     res.http("http://example.com")
  #       # set a single header
  #       .header('Authorization', 'bearer abcdef')
  #
  #       # set multiple headers
  #       .headers(Authorization: 'bearer abcdef', Accept: 'application/json')
  #
  #       # add URI query parameters
  #       .query(a: 1, b: 'foo & bar')
  #
  #       # make the actual request
  #       .get() (err, res, body) ->
  #         console.log body
  #
  #       # or, you can POST data
  #       .post(data) (err, res, body) ->
  #         console.log body
  #
  # Returns a ScopedClient instance.
  http: (url) ->
    HttpClient.create(url)
      .header('User-Agent', "Brobbot/#{@version}")

  segment: (segmentName) ->
    new RobotSegment @, segmentName

module.exports = Robot
