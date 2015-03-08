# Brains

Brobbot's brain is pretty cool. It implements a pretty generic key->value store interface, modeled after the redis api.
When a script is loaded, it's given a brain-segment which helps each script operate in a separete key-space.
It also provides hooks for serializing and deserializing data.
Most methods should return a promise.

## Available brains

- [dumb](../src/brains/dumb.coffee) (the default)
- [Redis](https://npmjs.org/package/brobbot-redis-brain)
- [PostgreSQL](https://npmjs.org/package/brobbot-pg-brain)

## API

### ready

A promise to be resolved when the brain is ready for use.

### reset()

Reset the datastore. Destroys all data.

Returns promise.

### llen(key)

Get the length of the list stored at `key`.

Returns promise for int.

### lset(key, index, value)

Set the list value at the specified index.

Returns promise.

### linsert(key, placement, pivot, value)

Insert a list value before/after pivot value.

Returns promise.

### lpush(key, value)

Push a value onto the left-side of the list.

Returns promise.

### rpush(key, value)

Push a value onto the right-side of the list.

Returns promise.

### lpop(key)

Pop a value off of the left-side of the list.

Returns promise for the list value.

### rpop(key)

Pop a value off of the right-side of the list.

Returns promise for the list value.

### lindex(key, index)

Get the value at the specified index in the list.

Returns promise for the list value.

### lrange(key, start, end)

Get the values between the `start` and `end` indeces.

Returns promise for array of list values.

### lgetall(key)

Get all the values in a list.

Returns promise for array of list values.

### lrem(key, value)

Remove all instances of `value` in the list.

Returns promise.

### sadd(key, value)

Add a member to the set specified by `key`.

Returns promise.

### sismember(key, value)

Test whether the member is in the set.

Returns promise for boolean.

### srem(key, value)

Remove a member from the set.

Returns promise.

### scard(key)

Get the size of the set.

Returns promise for int.

### spop(key)

Get and remove a random member from the set.

Returns promise for a set member.

### srandmember(key)

Get a random member from the set.

Returns promise for a set member.

### smembers(key)

Get all the members of the set.

Returns promise for array.

### keys(searchKey = '')

Get all the keys, optionally restricted to keys prefixed with `searchKey`.

Returns promise for array.

### key(key)

Transform the given key for internal use.

Returns string.

### unkey(key)

Transform the given key from internal use key to user-facing key.

Returns string.

### set(key, value)

Store key-value pair.

Returns promise.

### get(key)

Get value by key.

Returns promise.

### exists(key)

Check whether the key has been set.

Returns promise for boolean.

### incrby(key, num)

increment the value by `num` atomically.

Returns promise.

### hkeys(table)

Get all the keys for the given hash table name.

Returns promise for array.

### hvals(table)

Get all the values for the given hash table name.

Returns promise for array.

### hlen(table)

Get the size of the hash table.

Returns promise for int.

### hset(table, key, value)

Set a value in the specified hash table.

Returns promise for the value.

### hget(table, key)

Get a value from the specified hash table.

Returns promise for the value.

### hdel(table, key)

Remove a value from the specified hash table.

Returns promise.

### hgetall(table)

Get the whole hash table as an object.

Returns promise for object.

### hincrby(table, key, num)

increment the hash value by num atomically.

Returns promise.

### remove(key)

Alias: `del`

Remove value by key.

Returns promise.

### close

Override this in your brain module to perform any necessary cleanup (e.g. closing connections).

Returns promise.

### serialize(value)

Perform any necessary pre-set serialization on a value.

Returns serialized value.

### deserialize(value)

Perform any necessary post-get deserialization on a value.

Returns deserialized value.

### users

Get an Array of User objects stored in the brain.

Returns promise for an Array of User objects.

### addUser(user)

Add a user to the data-store.

Returns promise for user.

### userForId(id, userData)

Get or create a User object given a unique identifier.

Returns promise for a User instance of the specified user.

### userForName(name)

Get a User object given a name.

Returns promise for a User instance for the user with the specified name.

### usersForRawFuzzyName(fuzzyName)

Get all users whose names start with `fuzzyName` (case-insensitive).

Returns promise an Array of User instances matching the fuzzy name.

### usersForFuzzyName(fuzzyName)

If fuzzyName is an exact match for a user, returns an array with
just that user. Otherwise, returns an array of all users for which
fuzzyName is a raw fuzzy match (see `usersForRawFuzzyName`).

Returns promise an Array of User instances matching the fuzzy name.

### segment(segmentName)

Return a brain segment using `segmentName` as a key prefix.

Returns BrainSegment.

