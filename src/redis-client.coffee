Url = require "url"
Redis = require "redis"
Q = require "q"

class RedisClient
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

    @client.on "connect", ->
      connectedDefer.resolve()
    @client.once "error", (err) =>
      if @connected.isPending()
        connectedDefer.reject err

    @connected.then ->
      robot.logger.info "Successfully connected to Redis"
    @connected.fail (err) ->
      robot.logger.error "Failed to connect to Redis: " + err

    if @info.auth
      @authed = Q.ninvoke @client, "auth", @info.auth.split(":")[1]
    else
      @authed = Q()

    @authed.then ->
      robot.logger.info "Successfully authenticated to Redis"
    @authed.fail ->
      robot.logger.error "Failed to authenticate to Redis"

    @ready = Q.all [@connected, @authed]

  get: (prefix, key) ->
    @ready.then(Q.ninvoke(@client, "get", "#{key}:#{prefix}:#{@prefix}:storage"))

  set: (prefix, key, value) ->
    @ready.then(Q.ninvoke(@client, "set", "#{key}:#{prefix}:#{@prefix}:storage", value))

  close: ->
    @client.quit()

module.exports = RedisClient
