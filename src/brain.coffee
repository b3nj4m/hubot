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
    @users = new Map()
    @data = new Map()
    @ready = Q(@)

  # Reset the datastore. destroys all data.
  #
  # returns promise
  reset: ->
    @users = new Map()
    @data = new Map()
    Q()

  # get the length of the list stored at `key`
  #
  # Returns promise for int
  llen: (key) ->
    list = @data.get(@key(key))

    if list is undefined
      Q(null)
    else
      Q(list.length)

  # set the list value at the specified index
  #
  # Returns promise
  lset: (key, index, value) ->
    key = @key(key)
    list = @data.get(key)

    if list is undefined
      list = []
      @data.set(key, list)

    list[index] = @serialize(value)
    Q()

  # insert a value into the list before or after the pivot element.
  #
  # Returns promise
  linsert: (key, placement, pivot, value) ->
    key = @key(key)
    list = @data.get(key)

    if list isnt undefined
      pivot = @serialize(pivot)

      index = _.findIndex(list, (val) => val is pivot)

      if index > -1
        if placement is 'AFTER'
          index = index + 1
        list.splice(index, 0, @serialize(value))

    Q()

  # push a new value onto the left-side of the list
  #
  # Returns promise
  lpush: (key, value) ->
    key = @key(key)
    list = @data.get(key)

    if list is undefined
      list = []
      @data.set(key, list)

    list.unshift(@serialize(value))
    Q()

  # push a new value onto the right-side of the list
  #
  # Returns promise
  rpush: (key, value) ->
    key = @key(key)
    list = @data.get(key)

    if list is undefined
      list = []
      @data.set(key, list)

    list.push(@serialize(value))
    Q()

  # pop a value off of the left-side of the list
  #
  # Returns promise for list item
  lpop: (key) ->
    Q(@deserialize(@data.get(@key(key))?.shift()))

  # pop a value off of the right-side of the list
  #
  # Returns promise for list item
  rpop: (key) ->
    Q(@deserialize(@data.get(@key(key))?.pop()))

  # get a list item by index
  #
  # Returns promise for list item
  lindex: (key, index) ->
    Q(@deserialize(@data.get(@key(key))?[index] or null))

  # get an entire list
  #
  # Returns promise for array
  lgetall: (key) ->
    @lrange(key, 0, -1)

  # get a slice of the list
  #
  # Returns promise for array
  lrange: (key, start, end) ->
    list = @data.get(@key(key))

    if list is undefined
      return Q(null)

    if end < 0
      end = list.length + end

    Q(_.map(list.slice(start, end + 1), @deserialize.bind(@)))

  # remove values from a list
  #
  # Returns promise
  lrem: (key, value) ->
    list = @data.get(@key(key))

    if list
      value = @serialize(value)
      index = _.findIndex(list, (val) -> val is value)
      if index > -1
        list.splice(index, 1)
    Q()

  # Add a member to the set specified by `key`
  #
  # Returns promise
  sadd: (key, value) ->
    key = @key(key)
    set = @data.get(key)

    if set is undefined
      set = new Set()
      @data.set(key, set)

    set.add(@serialize(value))

    Q()

  # Test whether the member is in the set
  #
  # Returns promise for boolean
  sismember: (key, value) ->
    set = @data.get(@key(key))
    if not set
      Q(null)
    else
      Q(set.has(@serialize(value)))

  # Remove a member from the set
  #
  # Returns promise
  srem: (key, value) ->
    set = @data.get(@key(key))

    if set
      set.delete(@serialize(value))

    Q()

  # Get the size of the set
  #
  # Returns promise for int
  scard: (key) ->
    set = @data.get(@key(key))
    if set is undefined
      Q(null)
    else
      Q(set.size)

  # Get and remove a random member from the set
  #
  # Returns promise for a set member
  spop: (key) ->
    set = @data.get(@key(key))
    
    if set is undefined
      return Q(null)

    index = _.random(0, set.size - 1)
    item = set.values()[index]

    set.delete(item)

    Q(@deserialize(item))

  # Get a random member from the set
  #
  # Returns promise for a set member
  srandmember: (key) ->
    set = @data.get(@key(key))
    if set is undefined or set.size is 0
      return Q(null)

    Q(@deserialize(set.values()[_.random(0, set.size - 1)]))

  # Get all the members of the set
  #
  # Returns promise for array
  smembers: (key) ->
    @data.get(@key(key))?.values() or null

  # get all the keys, optionally restricted to keys prefixed with `searchKey`
  #
  # Returns promise for array
  keys: (searchKey = '') ->
    searchKey = @key(searchKey)
    Q(_.map(_.filter(@data.keys(), (key) -> key.indexOf(searchKey) is 0), @unkey.bind(@)))

  # transform a key from internal brain key, to user-facing key
  #
  # Returns string
  unkey: (key) ->
    key

  # transform the key for internal use
  # overridden by brain-segment
  #
  # Returns string.
  key: (key) ->
    key

  # get the key for the users
  #
  # Returns string.
  usersKey: () ->
    'users'

  # Store key-value pair under the private namespace and extend
  # existing.
  #
  # Returns promise
  set: (key, value) ->
    @data.set(@key(key), @serialize(value))
    Q()

  # Get value by key from the private namespace in @data
  # or return null if not found.
  #
  # Returns promise
  get: (key) ->
    Q(@deserialize(@data.get(@key(key)) ? null))

  # Get the type of the value at `key`
  #
  # Returns promise
  type: (key) ->
    val = @deserialize(@data.get(@key(key)))

    if val is undefined
      null
    else if val instanceof Map
      'hash'
    else if val instanceof Set
      'set'
    else if _.isArray(val)
      'list'
    else
      'object'

  # Check whether the given key has been set
  #
  # Return promise for boolean
  exists: (key) ->
    Q(@data.has(@key(key)))

  # increment the value by num atomically
  #
  # Returns promise
  incrby: (key, num) ->
    key = @key(key)
    @data.set(key, (@data.get(key) or 0) + num)
    Q(@data.get(key))

  # Get all the keys for the given hash table name
  #
  # Returns promise for array.
  hkeys: (table) ->
    Q(@data.get(@key(table))?.keys() or null)

  # Get all the values for the given hash table name
  #
  # Returns promise for array.
  hvals: (table) ->
    val = @data.get(@key(table))
    if val is undefined
      Q(null)
    else
      Q(_.map(val.values(), @deserialize.bind(@)))

  # get the size of the hash table.
  #
  # Returns promise for int
  hlen: (table) ->
    val = @data.get(@key(table))
    if val is undefined
      Q(null)
    else
      Q(val.size)

  # Set a value in the specified hash table
  #
  # Returns promise for the value.
  hset: (table, key, value) ->
    table = @key(table)
    val = @data.get(table)

    if val is undefined
      val = new Map()
      @data.set(table, val)

    val.set(key, @serialize(value))

    Q()

  # Get a value from the specified hash table.
  #
  # Returns: promise for the value.
  hget: (table, key) ->
    val = @data.get(@key(table))
    if val is undefined
      Q(null)
    else
      Q(@deserialize(val.get(key)))

  # Delete a field from a hash table
  #
  # Returns promise
  hdel: (table, key) ->
    val = @data.get(@key(table))
    if val isnt undefined
      val.delete(key)
    Q()

  # Get the whole hash table as a Map.
  #
  # Returns: promise for Map.
  hgetall: (table) ->
    Q(new Map(@data.get(@key(table))?.entries() or null))

  # increment the hash value by num atomically
  #
  # Returns promise
  hincrby: (table, key, num) ->
    table = @key(table)
    val = @data.get(table)

    if val is undefined
      val = new Map()
      @data.set(table, val)

    val.set(key, (val.get(key) or 0) + num
    Q(val.get(key))

  # Remove value by key from the private namespace in @data
  # if it exists
  #
  # Returns promise
  remove: (key) ->
    @data.delete(@key(key))
    Q()
  # alias for remove
  del: (key) ->
    @remove(key)

  # nothin to close
  #
  # Returns promise
  close: ->
    Q()

  # Perform any necessary pre-set serialization on a value
  #
  # Returns serialized value
  serialize: (value) ->
    JSON.stringify(value)

  # Perform any necessary post-get deserialization on a value
  #
  # Returns deserialized value
  deserialize: (value) ->
    JSON.parse(value)

  # Get an Array of User objects stored in the brain.
  #
  # Returns promise for an Array of User objects.
  users: ->
    Q(@users)

  # Add a user to the data-store
  #
  # Returns promise for user
  addUser: (user) ->
    @users.set(user.id, user)
    Q(user)

  # Get or create a User object given a unique identifier.
  #
  # Returns promise for a User instance of the specified user.
  userForId: (id, options) ->
    user = @users.get(id)

    if user is undefined or (options and options.room and (user.room isnt options.room))
      return @addUser(new User(id, options))

    Q(user)

  # Get a User object given a name.
  #
  # Returns promise for a User instance for the user with the specified name.
  userForName: (name) ->
    lowerName = name.toLowerCase()
    user = _.find @users.values(), (user) ->
      user.name and user.name.toString().toLowerCase() is lowerName
    Q(user or null)

  # Get all users whose names match fuzzyName. Currently, match
  # means 'starts with', but this could be extended to match initials,
  # nicknames, etc.
  #
  # Returns promise an Array of User instances matching the fuzzy name.
  usersForRawFuzzyName: (fuzzyName) ->
    lowerFuzzyName = fuzzyName.toLowerCase()
    users = _.filter @users.values(), (user) ->
      user.name.toLowerCase().lastIndexOf(lowerFuzzyName, 0) is 0

    Q(users)

  # If fuzzyName is an exact match for a user, returns an array with
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

  # Return a brain segment bound to the given key-prefix.
  #
  # Returns BrainSegment
  segment: (segment) ->
    new BrainSegment @, segment

module.exports = Brain
