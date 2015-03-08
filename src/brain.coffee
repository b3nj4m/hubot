{EventEmitter} = require 'events'

User = require './user'
BrainSegment = require './brain-segment'
Q = require 'q'
_ = require 'lodash'

class Brain extends EventEmitter
  # Represents somewhat persistent storage for the robot. Extend this.
  #
  # Returns a new Brain with no external storage.
  constructor: (@robot) ->
    @data =
      users: {}
      _private: {}

    @ready = Q(@)

  # Public: get the length of the list stored at `key`
  #
  # Returns int
  llen: (key) ->
    Q(@data._private[@key key]?.length)

  # Public: set the list value at the specified index
  #
  # Returns promise
  lset: (key, index, value) ->
    key = @key key

    if not @data._private[key]
      @data._private[key] = []

    @data._private[@key key][index] = @serialize value
    Q()

  # Public: insert a value into the list before or after the pivot element.
  #
  # Returns promise
  linsert: (key, placement, pivot, value) ->
    key = @key key
    if @data._private[key] is undefined
      @data._private[key] = []

    pivot = @serialize(pivot)

    index = _.findIndex(@data._private[key], (val) => val is pivot)

    if index > -1
      if placement is 'AFTER'
        index = index + 1
      @data._private[key].splice(index, 0, @serialize(value))

    Q()

  # Public: push a new value onto the left-side of the list
  #
  # Returns promise
  lpush: (key, value) ->
    key = @key key
    if @data._private[key] is undefined
      @data._private[key] = []

    @data._private[key].unshift(@serialize value)
    Q()

  # Public: push a new value onto the right-side of the list
  #
  # Returns promise
  rpush: (key, value) ->
    key = @key key
    if @data._private[key] is undefined
      @data._private[key] = []

    @data._private[key].push(@serialize value)
    Q()

  # Public: pop a value off of the left-side of the list
  #
  # Returns promise for list item
  lpop: (key) ->
    Q(@deserialize(@data._private[@key key]?.shift()))

  # Public: pop a value off of the right-side of the list
  #
  # Returns promise for list item
  rpop: (key) ->
    Q(@deserialize(@data._private[@key key]?.pop()))

  # Public: get a list item by index
  #
  # Returns promise for list item
  lindex: (key, index) ->
    Q(@deserialize(@data._private[@key key]?[index] or null))

  # Public: get an entire list
  #
  # Returns promise for array
  lgetall: (key) ->
    @lrange(key, 0, -1)

  # Public: get a slice of the list
  #
  # Returns promise for array
  lrange: (key, start, end) ->
    key = @key key

    if end < 0
      end = @data._private[key]?.length + end

    Q(_.map(@data._private[key]?.slice(start, end + 1), @deserialize.bind(@)))

  # Public: remove values from a list
  #
  # Returns promise
  lrem: (key, value) ->
    key = @key key
    @data._private[key] = _.without(@data._private[key], @serialize(value))
    Q()

  # Public: Add a member to the set specified by `key`
  #
  # Returns promise
  sadd: (key, value) ->
    key = @key key
    if @data._private[key] is undefined
      @data._private[key] = []

    value = @serialize(value)

    if not _.contains(@data._private[key], value)
      @data._private[key].push(value)

    Q()

  # Public: Test whether the member is in the set
  #
  # Returns promise for boolean
  sismember: (key, value) ->
    Q(_.contains(@data._private[key], @serialize(value)))

  # Public: Remove a member from the set
  #
  # Returns promise
  srem: (key, value) ->
    key = @key(key)
    value = @serialize(value)
    index = _.findIndex(@data._private[key], (val) -> val is value)
    if index > -1
      @data._private[key].splice(index, 1)

    Q()

  # Public: Get the size of the set
  #
  # Returns promise for int
  scard: (key) ->
    key = @key key

    if @data._private[key]
      Q(@data._private[key].length)
    else
      Q(0)

  # Public: Get and remove a random member from the set
  #
  # Returns promise for a set member
  spop: (key) ->
    key = @key key
    
    if @data._private[key] is undefined
      return Q(null)

    index = _.random(0, @data._private[key].length - 1)
    item = @data._private[key][index]

    @data._private[key].splice(index, 1)

    Q(@deserialize(item))

  # Public: Get a random member from the set
  #
  # Returns promise for a set member
  srandmember: (key) ->
    key = @key key
    if @data._private[key] is undefined or @data._private[key].length is 0
      return Q(null)

    Q(@deserialize(@data._private[key][_.random(0, @data._private[key].length - 1)]))

  # Public: Get all the members of the set
  #
  # Returns promise for array
  smembers: (key) ->
    Q(_.map(@data._private[@key key], @deserialize.bind(@)))

  # Public: get all the keys, optionally restricted to keys prefixed with `searchKey`
  #
  # Returns promise for array
  keys: (searchKey = '') ->
    searchKey = @key searchKey
    Q(_.map(_.filter(_.keys(@data._private), (key) -> key.indexOf(searchKey) is 0), @unkey.bind(@)))

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

  # Public: get the key for the users
  #
  # Returns string.
  usersKey: () ->
    'users'

  # Public: Store key-value pair under the private namespace and extend
  # existing.
  #
  # Returns promise
  set: (key, value) ->
    if value is undefined
      _.each key, (v, k) =>
        @set k, v
    else
      @data._private[@key key] = @serialize(value)

    Q()

  # Public: Get value by key from the private namespace in @data
  # or return null if not found.
  #
  # Returns promise
  get: (key) ->
    Q(@deserialize(@data._private[@key key] ? null))

  # Public: Check whether the given key has been set
  #
  # Return promise for boolean
  exists: (key) ->
    Q(@data._private[@key key] isnt undefined)

  # Public: increment the value by num atomically
  #
  # Returns promise
  incrby: (key, num) ->
    key = @key key
    @data._private[key] = (@data._private[key] or 0) + num
    Q(@data._private[key])

  # Public: Get all the keys for the given hash table name
  #
  # Returns promise for array.
  hkeys: (table) ->
    Q(_.keys(@data._private[@key table] or {}))

  # Public: Get all the values for the given hash table name
  #
  # Returns promise for array.
  hvals: (table) ->
    Q(_.map(@data._private[@key table] or {}, @deserialize.bind(@)))

  # Public: get the size of the hash table.
  #
  # Returns promise for int
  hlen: (table) ->
    Q(_.size(@data._private[@key table]))

  # Public: Set a value in the specified hash table
  #
  # Returns promise for the value.
  hset: (table, key, value) ->
    table = @key table
    @data._private[table] = @data._private[table] or {}
    @data._private[table][key] = @serialize value
    Q()

  # Public: Get a value from the specified hash table.
  #
  # Returns: promise for the value.
  hget: (table, key) ->
    Q(@deserialize @data._private[@key table]?[key])

  # Public: Delete a field from a hash table
  #
  # Returns promise
  hdel: (table, key) ->
    delete @data._private[@key table]?[key]
    Q()

  # Public: Get the whole hash table as an object.
  #
  # Returns: promise for object.
  hgetall: (table) ->
    Q(_.clone(_.mapValues(@data._private[@key table], @deserialize.bind @)))

  # Public: increment the hash value by num atomically
  #
  # Returns promise
  hincrby: (table, key, num) ->
    table = @key table
    @data._private[table] = @data._private[table] or {}
    @data._private[table][key] = (@data._private[table][key] or 0) + num
    Q(@data._private[table][key])

  # Public: Remove value by key from the private namespace in @data
  # if it exists
  #
  # Returns promise
  remove: (key) ->
    delete @data._private[@key key]
    Q()
  # alias for remove
  del: (key) ->
    @remove key

  # Public: nothin to close
  #
  # Returns promise
  close: ->
    Q()

  # Public: Perform any necessary pre-set serialization on a value
  #
  # Returns serialized value
  serialize: (value) ->
    JSON.stringify(value)

  # Public: Perform any necessary post-get deserialization on a value
  #
  # Returns deserialized value
  deserialize: (value) ->
    JSON.parse(value)

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
      userName = @data.users[k].name
      if userName and userName.toString().toLowerCase() is lowerName
        result = @data.users[k]
    Q(result)

  # Public: Get all users whose names match fuzzyName. Currently, match
  # means 'starts with', but this could be extended to match initials,
  # nicknames, etc.
  #
  # Returns promise an Array of User instances matching the fuzzy name.
  usersForRawFuzzyName: (fuzzyName) ->
    lowerFuzzyName = fuzzyName.toLowerCase()
    results = []
    for key, user of (@data.users or {})
      if user.name.toLowerCase().lastIndexOf(lowerFuzzyName, 0) is 0
        results.push user

    Q(results)

  # Public: If fuzzyName is an exact match for a user, returns an array with
  # just that user. Otherwise, returns an array of all users for which
  # fuzzyName is a raw fuzzy match (see usersForRawFuzzyName).
  #
  # Returns promise an Array of User instances matching the fuzzy name.
  usersForFuzzyName: (fuzzyName) ->
    @usersForRawFuzzyName(fuzzyName).then (matchedUsers) ->
      lowerFuzzyName = fuzzyName.toLowerCase()
      for user in matchedUsers
        return Q([user]) if user.name?.toLowerCase() is lowerFuzzyName

      Q(matchedUsers)

  # Public: Return a brain segment bound to the given key-prefix.
  #
  # Returns BrainSegment
  segment: (segment) ->
    new BrainSegment @, segment

module.exports = Brain
