Brain = require '../brain'
Url = require "url"
Redis = require "redis"
Q = require "q"

class RedisBrain extends Brain
  constructor: (robot) ->
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
      robot.logger.info "Discovered redis from #{redisUrlEnv} environment variable"
    else
      robot.logger.info "Using default redis on localhost:6379"

    @info   = Url.parse  redisUrl, true
    @client = Redis.createClient(@info.port, @info.hostname)
    @prefix = @info.path?.replace('/', '') or 'hubot'

    connectedDefer = Q.defer()
    @connected = connectedDefer.promise

    @client.on "connect", connectedDefer.resolve.bind(connectedDefer)

    @connected.then ->
      robot.logger.info "Successfully connected to Redis"
    @connected.fail (err) ->
      robot.logger.error "Failed to connect to Redis: " + err

    if @info.auth
      @authed = Q.ninvoke @client, "auth", @info.auth.split(":")[1]

      @authed.then ->
        robot.logger.info "Successfully authenticated to Redis"
      @authed.fail ->
        robot.logger.error "Failed to authenticate to Redis"
    else
      @authed = Q()

    @ready = Q.all [@connected, @authed]

  get: (prefix, key) ->
    @ready.then(Q.ninvoke(@client, "get", "#{key}:#{prefix}:#{@prefix}:storage"))

  set: (prefix, key, value) ->
    @ready.then(Q.ninvoke(@client, "set", "#{key}:#{prefix}:#{@prefix}:storage", value))

  close: ->
    @client.quit()

  segment: (prefix) ->
    new RedisBrainSegment @, prefix

class RedisBrainSegment extends Brain
  constructor: (@brain, @prefix = '') ->
    @get = @get.bind(@, prefix)
    @set = @set.bind(@, prefix)

  get: (prefix, key) ->
    @brain.get(prefix, key)

  set: (prefix, key, value) ->
    @brain.set(prefix, key, value)

module.exports = RedisBrain
