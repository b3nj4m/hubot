Brain = require '../brain'
Url = require "url"
Redis = require "redis"
Q = require "q"
User = require '../user'
_ = require "lodash"
msgpack = require "msgpack"

class RedisBrain extends Brain
  constructor: (@robot, @useMsgpack = true) ->
    super(@robot)

    redisUrl = if process.env.REDISTOGO_URL?
                 redisUrlEnv = "REDISTOGO_URL"
                 process.env.REDISTOGO_URL
               else if process.env.REDISCLOUD_URL?
                 redisUrlEnv = "REDISCLOUD_URL"
                 process.env.REDISCLOUD_URL
               else if process.env.BOXEN_REDIS_URL?
                 redisUrlEnv = "BOXEN_REDIS_URL"
                 process.env.BOXEN_REDIS_URL
               else if process.env.REDIS_URL?
                 redisUrlEnv = "REDIS_URL"
                 process.env.REDIS_URL
               else
                 'redis://localhost:6379'

    if redisUrlEnv?
      @robot.logger.info "Discovered redis from #{redisUrlEnv} environment variable"
    else
      @robot.logger.info "Using default redis on localhost:6379"

    @info   = Url.parse  redisUrl, true
    @client = Redis.createClient(@info.port, @info.hostname, return_buffers: true)
    @prefix = @info.path?.replace('/', '') or 'hubot'

    connectedDefer = Q.defer()
    @connected = connectedDefer.promise

    @client.on "connect", connectedDefer.resolve.bind(connectedDefer)

    @connected.then ->
      @robot.logger.info "Successfully connected to Redis"
    @connected.fail (err) ->
      @robot.logger.error "Failed to connect to Redis: " + err

    if @info.auth
      @authed = Q.ninvoke @client, "auth", @info.auth.split(":")[1]

      @authed.then ->
        @robot.logger.info "Successfully authenticated to Redis"
      @authed.fail ->
        @robot.logger.error "Failed to authenticate to Redis"
    else
      @authed = Q()

    @ready = Q.all [@connected, @authed]

  key: (key) ->
    "#{@prefix}:#{key}"

  get: (key) ->
    @ready.then =>
      Q.ninvoke(@client, "get", @key(key)).then(@deserialize.bind(@))

  set: (key, value) ->
    @ready.then =>
      Q.ninvoke(@client, "set", @key(key), @serialize(value))

  # Public: increment the value by num atomically
  #
  # Returns promise
  incrby: (key, num) ->
    Q.ninvoke(@client, 'incrby', @key(key), num)

  # Public: Get all the keys for the given hash table name
  #
  # Returns array.
  hkeys: (table) ->
    Q.ninvoke(@client, 'hkeys', @key(table))

  # Public: Get all the values for the given hash table name
  #
  # Returns array.
  hvals: (table) ->
    Q.ninvoke(@client, 'hvals', @key(table))

  # Public: Set a value in the specified hash table
  #
  # Returns the value.
  hset: (table, key, value) ->
    Q.ninvoke(@client, 'hset', @key(table), key, value)

  # Public: Get a value from the specified hash table.
  #
  # Returns: the value.
  hget: (table, key) ->
    Q.ninvoke(@client, 'hget', @key(table), key)

  # Public: Get the whole hash table as an object.
  #
  # Returns: object.
  hgetall: (table) ->
    Q.ninvoke(@client, 'hgetall', @key(table))

  # Public: increment the hash value by num atomically
  #
  # Returns promise
  hincrby: (table, key, num) ->
    Q.ninvoke(@client, 'hincrby', @key(table), key, num)

  close: ->
    @client.quit()

  # Public: Perform any necessary pre-set serialization on a value
  #
  # Returns serialized value
  serialize: (value) ->
    if @useMsgpack
      return msgpack.pack(value)

    JSON.stringify(value)

  # Public: Perform any necessary post-get deserialization on a value
  #
  # Returns deserialized value
  deserialize: (value) ->
    if @useMsgpack
      return msgpack.unpack(value)

    JSON.parse(value)

  # Public: Perform any necessary pre-set serialization on a user
  #
  # Returns serialized user
  serializeUser: (user) ->
    @serialize user

  # Public: Perform any necessary post-get deserializtion on a user
  #
  # Returns a User
  deserializeUser: (obj) ->
    obj = @deserialize obj

    if obj and obj.id
      return new User obj.id, obj

    null

  # Public: Get an Array of User objects stored in the brain.
  #
  # Returns promise for an Array of User objects.
  users: ->
    @ready.then =>
      Q.ninvoke(@client, 'hgetall', @key('users')).then (users) =>
        _.mapValues users, @deserializeUser.bind(@)

  # Public: Add a user to the data-store
  #
  # Returns promise for user
  addUser: (user) ->
    @ready.then =>
      Q.ninvoke(@client, 'hset', @key('users'), user.id, @serializeUser(user)).then -> user

  # Public: Get or create a User object given a unique identifier.
  #
  # Returns promise for a User instance of the specified user.
  userForId: (id, options) ->
    @ready.then =>
      Q.ninvoke(@client, 'hget', @key('users'), id).then (user) =>
        if user
          user = @deserializeUser user

        if !user or (options and options.room and (user.room isnt options.room))
          return @addUser(new User(id, options))

        return user

  # Public: Get a User object given a name.
  #
  # Returns promise for a User instance for the user with the specified name.
  userForName: (name) ->
    name = name.toLowerCase()

    @users.then (users) ->
      _.find users, (user) ->
        user.name and user.name.toString().toLowerCase() is name

  # Public: Get all users whose names match fuzzyName. Currently, match
  # means 'starts with', but this could be extended to match initials,
  # nicknames, etc.
  #
  # Returns promise an Array of User instances matching the fuzzy name.
  usersForRawFuzzyName: (fuzzyName) ->
    fuzzyName = fuzzyName.toLowerCase()

    @users.then (users) ->
      _.find users, (user) ->
        user.name and user.name.toString().toLowerCase().indexOf(fuzzyName) is 0

  # Public: If fuzzyName is an exact match for a user, returns an array with
  # just that user. Otherwise, returns an array of all users for which
  # fuzzyName is a raw fuzzy match (see usersForRawFuzzyName).
  #
  # Returns promise an Array of User instances matching the fuzzy name.
  usersForFuzzyName: (fuzzyName) ->
    fuzzyName = fuzzyName.toLowerCase()

    @usersForRawFuzzyName(fuzzyName).then (matchedUsers) ->
      exactMatch = _.find matchedUsers, (user) ->
        user.name.toLowerCase() is fuzzyName

      exactMatch or matchedUsers

module.exports = RedisBrain
