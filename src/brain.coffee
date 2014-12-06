{EventEmitter} = require 'events'

User = require './user'
BrainSegment = require './brain-segment'
Q = require 'q'
_ = require 'lodash'

class Brain extends EventEmitter
  # Represents somewhat persistent storage for the robot. Extend this.
  #
  # Returns a new Brain with no external storage.
  constructor: (robot) ->
    @data =
      users: {}
      _private: {}
      _hprivate: {}

    @autoSave = true
    @ready = Q(@)

  # Take a dump
  #
  # Returns promise for object
  dump: ->
    Q(_.transform(@data._private, (result, key, val) => result[@unkey key] = value))

  # Public: get all the keys
  #
  # Returns promise for array
  keys: ->
    Q(_.map(_.keys(@data._private), @unkey.bind(@)))

  # Public: transform a key from internal brain key, to user-facing key
  #
  # Returns string
  unkey: (key) ->
    key

  # Public: transform the key for internal use
  # overridden by brain-segment
  #
  # Returns string.
  key: (key) ->
    key

  # Public: Store key-value pair under the private namespace and extend
  # existing.
  #
  # Returns promise
  set: (key, value) ->
    if value is undefined
      _.each key, (v, k) =>
        @set k, v
    else
      @data._private[@key key] = @serialize value

    Q(@)

  # Public: Get value by key from the private namespace in @data
  # or return null if not found.
  #
  # Returns promise
  get: (key) ->
    Q(@deserialize(@data._private[@key(key)] ? null))

  # Public: increment the value by num atomically
  #
  # Returns promise
  incrby: (key, num) ->
    @get(key).then (val) =>
      @set key, val + num

  # Public: Get all the keys for the given hash table name
  #
  # Returns promise for array.
  hkeys: (table) ->
    Q(_.keys(@_hprivate[@key table] or {}))

  # Public: Get all the values for the given hash table name
  #
  # Returns promise for array.
  hvals: (table) ->
    Q(_.mapValues(@_hprivate[@key table] or {}, @deserialize.bind(@)))

  # Public: Set a value in the specified hash table
  #
  # Returns promise for the value.
  hset: (table, key, value) ->
    table = @key table
    @_hprivate[table] = @_hprivate[table] or {}
    @_hprivate[table][key] = @serialize value
    Q(@)

  # Public: Get a value from the specified hash table.
  #
  # Returns: promise for the value.
  hget: (table, key) ->
    Q(@deserialize @_hprivate[@key table][key])

  # Public: Delete a field from a hash table
  #
  # Returns promise
  hdel: (table, key) ->
    delete @_hprivate[@key table][key]
    Q(@)

  # Public: Get the whole hash table as an object.
  #
  # Returns: promise for object.
  hgetall: (table) ->
    Q(_.clone(_.mapValues(@_hprivate[@key table], @deserialize.bind @)))

  # Public: increment the hash value by num atomically
  #
  # Returns promise
  hincrby: (table, key, num) ->
    table = @key table
    @hget(table, key).then (val) =>
      @hset table, key, val + num

  # Public: Remove value by key from the private namespace in @data
  # if it exists
  #
  # Returns promise
  remove: (key) ->
    delete @data._private[@key key]
    Q(@)
  # alias for remove
  del: (key) ->
    @remove key

  # Public: nothin to close
  #
  # Returns promise
  close: ->
    Q(@)

  # Public: Merge keys against the in memory representation.
  #
  # Returns promise
  #
  # Caveats: Deeply nested structures don't merge well.
  mergeData: (data) ->
    @set data

  # Public: Perform any necessary pre-set serialization on a value
  #
  # Returns serialized value
  serialize: (value) ->
    value

  # Public: Perform any necessary post-get deserialization on a value
  #
  # Returns deserialized value
  deserialize: (value) ->
    value

  # Public: Get an Array of User objects stored in the brain.
  #
  # Returns promise for an Array of User objects.
  users: ->
    Q(@data.users)

  # Public: Add a user to the data-store
  #
  # Returns promise for user
  addUser: (user) ->
    @data.users[user.id] = user
    Q(user)

  # Public: Get or create a User object given a unique identifier.
  #
  # Returns promise for a User instance of the specified user.
  userForId: (id, options) ->
    user = @data.users[id]

    if !user or (options and options.room and (user.room isnt options.room))
      return @addUser(new User(id, options))

    Q(user)

  # Public: Get a User object given a name.
  #
  # Returns promise for a User instance for the user with the specified name.
  userForName: (name) ->
    result = null
    lowerName = name.toLowerCase()
    for k of (@data.users or { })
      userName = @data.users[k]['name']
      if userName? and userName.toString().toLowerCase() is lowerName
        result = @data.users[k]
    Q(result)

  # Public: Get all users whose names match fuzzyName. Currently, match
  # means 'starts with', but this could be extended to match initials,
  # nicknames, etc.
  #
  # Returns promise an Array of User instances matching the fuzzy name.
  usersForRawFuzzyName: (fuzzyName) ->
    lowerFuzzyName = fuzzyName.toLowerCase()
    Q(user) for key, user of (@data.users or {}) when (
      user.name.toLowerCase().lastIndexOf(lowerFuzzyName, 0) is 0
    )

  # Public: If fuzzyName is an exact match for a user, returns an array with
  # just that user. Otherwise, returns an array of all users for which
  # fuzzyName is a raw fuzzy match (see usersForRawFuzzyName).
  #
  # Returns promise an Array of User instances matching the fuzzy name.
  usersForFuzzyName: (fuzzyName) ->
    matchedUsers = @usersForRawFuzzyName(fuzzyName)
    lowerFuzzyName = fuzzyName.toLowerCase()
    for user in matchedUsers
      return [user] if user.name.toLowerCase() is lowerFuzzyName

    Q(matchedUsers)

  # Public: Return a brain segment bound to the given key-prefix.
  #
  # Returns BrainSegment
  segment: (segment) ->
    new BrainSegment @, segment

module.exports = Brain
