{EventEmitter} = require 'events'

User = require './user'
Q = require 'q'

class Brain extends EventEmitter
  # Represents somewhat persistent storage for the robot. Extend this.
  #
  # Returns a new Brain with no external storage.
  constructor: (robot) ->
    @data =
      users:    { }
      _private: { }

    @autoSave = true
    @ready = Q(@)

  # Public: Store key-value pair under the private namespace and extend
  # existing.
  #
  # Returns promise
  set: (key, value) ->
    if key is Object(key)
      pair = key
    else
      pair = {}
      pair[key] = value

    extend @data._private, pair
    Q(@)

  # Public: Get value by key from the private namespace in @data
  # or return null if not found.
  #
  # Returns promise
  get: (key) ->
    Q(@data._private[key] ? null)

  # Public: Remove value by key from the private namespace in @data
  # if it exists
  #
  # Returns promise
  remove: (key) ->
    delete @data._private[key] if @data._private[key]?
    Q(@)

  # Public: Emits the 'save' event so that 'brain' scripts can handle
  # persisting.
  #
  # Returns promise
  save: ->
    @emit 'save', @data
    Q(@)

  # Public: Emits the 'close' event so that 'brain' scripts can handle closing.
  #
  # Returns promise
  close: ->
    clearInterval @saveInterval
    @save()
    @emit 'close'
    Q(@)

  # Public: Enable or disable the automatic saving
  #
  # enabled - A boolean whether to autosave or not
  #
  # Returns nothing
  setAutoSave: (enabled) ->
    @autoSave = enabled

  # Public: Reset the interval between save function calls.
  #
  # seconds - An Integer of seconds between saves.
  #
  # Returns nothing.
  resetSaveInterval: (seconds) ->
    clearInterval @saveInterval if @saveInterval
    @saveInterval = setInterval =>
      @save() if @autoSave
    , seconds * 1000

  # Public: Merge keys against the in memory representation.
  #
  # Returns promise
  #
  # Caveats: Deeply nested structures don't merge well.
  mergeData: (data) ->
    for k of (data or { })
      @data[k] = data[k]

    Q(@)

  # Public: Get an Array of User objects stored in the brain.
  #
  # Returns promise for an Array of User objects.
  users: ->
    Q(@data.users)

  # Public: Get a User object given a unique identifier.
  #
  # Returns promise for a User instance of the specified user.
  userForId: (id, options) ->
    user = @data.users[id]
    unless user
      user = new User id, options
      @data.users[id] = user

    if options and options.room and (!user.room or user.room isnt options.room)
      user = new User id, options
      @data.users[id] = user

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

# Private: Extend obj with objects passed as additional args.
#
# Returns the original object with updated changes.
extend = (obj, sources...) ->
  for source in sources
    obj[key] = value for own key, value of source
  obj

module.exports = Brain
