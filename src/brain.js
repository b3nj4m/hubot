var EventEmitter = require('events').EventEmitter;
var User = require('./user');
var BrainSegment = require('./brain-segment');
var Q = require('q');
var _ = require('lodash');

//convert es6 iterator to values array
function iterValues(iter) {
  var result = [];
  for (var item of iter) {
    result.push(item);
  }
  return result;
}

/*
 * Represents somewhat persistent storage for the robot. Extend this.
 *
 * Returns a new Brain with no external storage.
 */

function Brain(robot) {
  this.robot = robot;
  this._users = new Map();
  this._data = new Map();
  this.ready = Q(this);
}


/*
 * Reset the datastore. destroys all data.
 *
 * returns promise
 */

Brain.prototype.reset = function() {
  this._users = new Map();
  this._data = new Map();
  return Q();
};


/*
 * get the length of the list stored at `key`
 *
 * Returns promise for int
 */

Brain.prototype.llen = function(key) {
  var list = this._data.get(this.key(key));
  if (!list) {
    return Q(null);
  } else {
    return Q(list.length);
  }
};


/*
 * set the list value at the specified index
 *
 * Returns promise
 */

Brain.prototype.lset = function(key, index, value) {
  key = this.key(key);
  var list = this._data.get(key);
  if (!list) {
    list = [];
    this._data.set(key, list);
  }
  list[index] = this.serialize(value);
  return Q();
};


/*
 * insert a value into the list before or after the pivot element.
 *
 * Returns promise
 */

Brain.prototype.linsert = function(key, placement, pivot, value) {
  var key = this.key(key);
  var list = this._data.get(key);
  if (list) {
    pivot = this.serialize(pivot);
    index = _.findIndex(list, function(val) {
      return val === pivot;
    });
    if (index > -1) {
      if (placement === 'AFTER') {
        index = index + 1;
      }
      list.splice(index, 0, this.serialize(value));
    }
  }
  return Q();
};


/*
 * push a new value onto the left-side of the list
 *
 * Returns promise
 */

Brain.prototype.lpush = function(key, value) {
  var key = this.key(key);
  var list = this._data.get(key);
  if (!list) {
    list = [];
    this._data.set(key, list);
  }
  list.unshift(this.serialize(value));
  return Q();
};


/*
 * push a new value onto the right-side of the list
 *
 * Returns promise
 */

Brain.prototype.rpush = function(key, value) {
  var key = this.key(key);
  var list = this._data.get(key);
  if (!list) {
    list = [];
    this._data.set(key, list);
  }
  list.push(this.serialize(value));
  return Q();
};


/*
 * pop a value off of the left-side of the list
 *
 * Returns promise for list item
 */

Brain.prototype.lpop = function(key) {
  var list = this._data.get(this.key(key));
  return Q(this.deserialize(list ? list.shift() : null));
};


/*
 * pop a value off of the right-side of the list
 *
 * Returns promise for list item
 */

Brain.prototype.rpop = function(key) {
  var list = this._data.get(this.key(key));
  return Q(this.deserialize(list ? list.pop() : null));
};


/*
 * get a list item by index
 *
 * Returns promise for list item
 */

Brain.prototype.lindex = function(key, index) {
  var list = this._data.get(this.key(key));
  return Q(this.deserialize(list ? list[index] : null));
};


/*
 * get an entire list
 *
 * Returns promise for array
 */

Brain.prototype.lgetall = function(key) {
  return this.lrange(key, 0, -1);
};


/*
 * get a slice of the list
 *
 * Returns promise for array
 */

Brain.prototype.lrange = function(key, start, end) {
  var list = this._data.get(this.key(key));
  if (!list) {
    return Q(null);
  }
  if (end < 0) {
    end = list.length + end;
  }
  return Q(_.map(list.slice(start, end + 1), this.deserialize.bind(this)));
};


/*
 * remove values from a list
 *
 * Returns promise
 */

Brain.prototype.lrem = function(key, value) {
  var list = this._data.get(this.key(key));
  if (list) {
    value = this.serialize(value);
    var index = _.findIndex(list, function(val) {
      return _.isEqual(val, value);
    });
    if (index > -1) {
      list.splice(index, 1);
    }
  }
  return Q();
};


/*
 * Add a member to the set specified by `key`
 *
 * Returns promise
 */

Brain.prototype.sadd = function(key, value) {
  key = this.key(key);
  var set = this._data.get(key);
  if (!set) {
    set = new Set();
    this._data.set(key, set);
  }
  set.add(this.serialize(value));
  return Q();
};


/*
 * Test whether the member is in the set
 *
 * Returns promise for boolean
 */

Brain.prototype.sismember = function(key, value) {
  var set = this._data.get(this.key(key));
  if (!set) {
    return Q(null);
  } else {
    return Q(set.has(this.serialize(value)));
  }
};


/*
 * Remove a member from the set
 *
 * Returns promise
 */

Brain.prototype.srem = function(key, value) {
  var set = this._data.get(this.key(key));
  if (set) {
    set.delete(this.serialize(value));
  }
  return Q();
};


/*
 * Get the size of the set
 *
 * Returns promise for int
 */

Brain.prototype.scard = function(key) {
  var set = this._data.get(this.key(key));
  if (!set) {
    return Q(null);
  } else {
    return Q(set.size);
  }
};


/*
 * Get and remove a random member from the set
 *
 * Returns promise for a set member
 */

Brain.prototype.spop = function(key) {
  var set = this._data.get(this.key(key));
  if (!set) {
    return Q(null);
  }
  var index = _.random(0, set.size - 1);
  var item = iterValues(set.values())[index];
  set.delete(item);
  return Q(this.deserialize(item));
};


/*
 * Get a random member from the set
 *
 * Returns promise for a set member
 */

Brain.prototype.srandmember = function(key) {
  var set = this._data.get(this.key(key));
  if (!set || set.size === 0) {
    return Q(null);
  }
  return Q(this.deserialize(iterValues(set.values())[_.random(0, set.size - 1)]));
};


/*
 * Get all the members of the set
 *
 * Returns promise for array
 */

Brain.prototype.smembers = function(key) {
  var set = this._data.get(this.key(key));
  return Q(set ? iterValues(set.values()) : null);
};


/*
 * get all the keys, optionally restricted to keys prefixed with `searchKey`
 *
 * Returns promise for array
 */

Brain.prototype.keys = function(searchKey) {
  if (searchKey === undefined) {
    searchKey = '';
  }
  searchKey = this.key(searchKey);
  return Q(_.map(_.filter(iterValues(this._data.keys()), function(key) {
    return key.indexOf(searchKey) === 0;
  }), this.unkey.bind(this)));
};


/*
 * transform a key from internal brain key, to user-facing key
 *
 * Returns string
 */

Brain.prototype.unkey = function(key) {
  return key;
};


/*
 * transform the key for internal use
 * overridden by brain-segment
 *
 * Returns string.
 */

Brain.prototype.key = function(key) {
  return key;
};


/*
 * get the key for the users
 *
 * Returns string.
 */

Brain.prototype.usersKey = function() {
  return 'users';
};


/*
 * Store key-value pair under the private namespace and extend
 * existing.
 *
 * Returns promise
 */

Brain.prototype.set = function(key, value) {
  this._data.set(this.key(key), this.serialize(value));
  return Q();
};


/*
 * Get value by key from the private namespace in @_data
 * or return null if not found.
 *
 * Returns promise
 */

Brain.prototype.get = function(key) {
  return Q(this.deserialize(this._data.get(this.key(key)) || null));
};


/*
 * Get the type of the value at `key`
 *
 * Returns promise
 */

Brain.prototype.type = function(key) {
  var val = this.deserialize(this._data.get(this.key(key)));
  if (val === undefined) {
    return null;
  } else if (val instanceof Map) {
    return 'hash';
  } else if (val instanceof Set) {
    return 'set';
  } else if (val instanceof Array) {
    return 'list';
  } else {
    return 'object';
  }
};


/*
 * Check whether the given key has been set
 *
 * Return promise for boolean
 */

Brain.prototype.exists = function(key) {
  return Q(this._data.has(this.key(key)));
};


/*
 * increment the value by num atomically
 *
 * Returns promise
 */

Brain.prototype.incrby = function(key, num) {
  key = this.key(key);
  this._data.set(key, (this._data.get(key) || 0) + num);
  return Q(this._data.get(key));
};


/*
 * Get all the keys for the given hash table name
 *
 * Returns promise for array.
 */

Brain.prototype.hkeys = function(table) {
  var hash = this._data.get(this.key(table));
  if (hash) {
    return Q(iterValues(hash.keys()));
  } else {
    return Q(null);
  }
};


/*
 * Get all the values for the given hash table name
 *
 * Returns promise for array.
 */

Brain.prototype.hvals = function(table) {
  var val = this._data.get(this.key(table));
  if (!val) {
    return Q(null);
  } else {
    return Q(_.map(iterValues(val.values()), this.deserialize.bind(this)));
  }
};


/*
 * get the size of the hash table.
 *
 * Returns promise for int
 */

Brain.prototype.hlen = function(table) {
  var val = this._data.get(this.key(table));
  if (!val) {
    return Q(null);
  } else {
    return Q(val.size);
  }
};


/*
 * Set a value in the specified hash table
 *
 * Returns promise for the value.
 */

Brain.prototype.hset = function(table, key, value) {
  table = this.key(table);
  var val = this._data.get(table);
  if (!val) {
    val = new Map();
    this._data.set(table, val);
  }
  val.set(key, this.serialize(value));
  return Q();
};


/*
 * Get a value from the specified hash table.
 *
 * Returns: promise for the value.
 */

Brain.prototype.hget = function(table, key) {
  var val = this._data.get(this.key(table));
  if (!val) {
    return Q(null);
  } else {
    return Q(this.deserialize(val.get(key)));
  }
};


/*
 * Delete a field from a hash table
 *
 * Returns promise
 */

Brain.prototype.hdel = function(table, key) {
  var val = this._data.get(this.key(table));
  if (val) {
    val.delete(key);
  }
  return Q();
};


/*
 * Get the whole hash table as a Map.
 *
 * Returns: promise for Map.
 */

Brain.prototype.hgetall = function(table) {
  var hash = this._data.get(this.key(table));
  return Q(new Map(hash ? hash.entries() : null));
};


/*
 * increment the hash value by num atomically
 *
 * Returns promise
 */

Brain.prototype.hincrby = function(table, key, num) {
  table = this.key(table);
  var val = this._data.get(table);
  if (!val) {
    val = new Map();
    this._data.set(table, val);
  }
  val.set(key, (val.get(key) || 0) + num);
  return Q(val.get(key));
};


/*
 * delete the value at `key`
 *
 * Returns promise
 */

Brain.prototype.remove = function(key) {
  this._data.delete(this.key(key));
  return Q();
};


/*
 * alias for remove
 */

Brain.prototype.del = function(key) {
  return this.remove(key);
};


/*
 * nothin to close
 *
 * Returns promise
 */

Brain.prototype.close = function() {
  return Q();
};


/*
 * Perform any necessary pre-set serialization on a value
 *
 * Returns serialized value
 */

Brain.prototype.serialize = function(value) {
  return value;
};


/*
 * Perform any necessary post-get deserialization on a value
 *
 * Returns deserialized value
 */

Brain.prototype.deserialize = function(value) {
  return value;
};


/*
 * Get an Array of User objects stored in the brain.
 *
 * Returns promise for an Array of User objects.
 */

Brain.prototype.users = function() {
  return Q(iterValues(this._users.values()));
};


/*
 * Add a user to the data-store
 *
 * Returns promise for user
 */

Brain.prototype.addUser = function(user) {
  this._users.set(user.id, user);
  return Q(user);
};


/*
 * Get or create a User object given a unique identifier.
 *
 * Returns promise for a User instance of the specified user.
 */

Brain.prototype.userForId = function(id, options) {
  var user = this._users.get(id);
  if (!user || (options && options.room && (user.room !== options.room))) {
    return this.addUser(new User(id, options));
  }
  return Q(user);
};


/*
 * Get a User object given a name.
 *
 * Returns promise for a User instance for the user with the specified name.
 */

Brain.prototype.userForName = function(name) {
  var lowerName = name.toLowerCase();
  var user = _.find(iterValues(this._users.values()), function(user) {
    return user.name && user.name.toString().toLowerCase() === lowerName;
  });
  return Q(user || null);
};


/*
 * Get all users whose names match fuzzyName. Currently, match
 * means 'starts with', but this could be extended to match initials,
 * nicknames, etc.
 *
 * Returns promise an Array of User instances matching the fuzzy name.
 */

Brain.prototype.usersForRawFuzzyName = function(fuzzyName) {
  var lowerFuzzyName = fuzzyName.toLowerCase();
  var users = _.filter(iterValues(this._users.values()), function(user) {
    return user.name.toLowerCase().lastIndexOf(lowerFuzzyName, 0) === 0;
  });
  return Q(users);
};


/*
 * If fuzzyName is an exact match for a user, returns an array with
 * just that user. Otherwise, returns an array of all users for which
 * fuzzyName is a raw fuzzy match (see usersForRawFuzzyName).
 *
 * Returns promise an Array of User instances matching the fuzzy name.
 */

Brain.prototype.usersForFuzzyName = function(fuzzyName) {
  return this.usersForRawFuzzyName(fuzzyName).then(function(matchedUsers) {
    var user;
    var lowerFuzzyName = fuzzyName.toLowerCase();
    for (var i = 0; i < matchedUsers.length; i++) {
      user = matchedUsers[i];
      if (user.name && user.name.toLowerCase() === lowerFuzzyName) {
        return Q([user]);
      }
    }
    return Q(matchedUsers);
  });
};


/*
 * Return a brain segment bound to the given key-prefix.
 *
 * Returns BrainSegment
 */

Brain.prototype.segment = function(segment) {
  return new BrainSegment(this, segment);
};

module.exports = Brain;
