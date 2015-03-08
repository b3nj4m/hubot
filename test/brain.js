var assert = require('assert');
var Q = require('q');
var User = require('../src/user');

module.exports = function(name, brain) {
  describe(name + ' brain', function() {
    describe('users', function() {
      it('should add users', function() {
        return Q.all([
          brain.addUser(new User(42, {name: 'bob'})),
          brain.addUser(new User(13, {name: 'alice'})),
          brain.addUser(new User(17, {name: 'alicexXx'}))
        ]);
      });

      it('should find user by ID', function() {
        return brain.userForId(13).then(function(user) {
          assert.equal(user.id, 13);
          assert.equal(user.name, 'alice');
        });
      });

      it('should find users by raw fuzzy name', function() {
        return brain.usersForRawFuzzyName('Alice').then(function(users) {
          assert.equal(users.length, 2);

          var user = users[0];
          assert.equal(user.id, 13);
          assert.equal(user.name, 'alice');

          user = users[1];
          assert.equal(user.id, 17);
          assert.equal(user.name, 'alicexXx');
        });
      });

      it('should find user by fuzzy name', function() {
        return brain.usersForFuzzyName('Alice').then(function(users) {
          var user = users[0];
          assert.equal(users.length, 1);
          assert.equal(user.id, 13);
          assert.equal(user.name, 'alice');
        });
      });
    });

    describe('plain values', function() {
      it('should set', function() {
        return brain.set('somekey', {somevalue: 12});
      });

      it('should exist', function() {
        return brain.exists('somekey').then(function(exists) {
          assert.strictEqual(exists, true);
        });
      });

      it('should get', function() {
        return brain.get('somekey').then(function(val) {
          assert.strictEqual(val.somevalue, 12);
        });
      });

      it('should return null for non-existant key', function() {
        return brain.get('beans').then(function(val) {
          assert.strictEqual(val, null);
        });
      });

      it('should not exist', function() {
        return brain.exists('beans').then(function(exists) {
          assert.strictEqual(exists, false);
        });
      });

      it('should get all keys', function() {
        return brain.keys().then(function(keys) {
          assert.strictEqual(keys.length, 1);
          assert.strictEqual(keys[0], 'somekey');
        });
      });

      it('should increment', function() {
        return brain.incrby('somenumber', 2).then(function(val) {
          assert.strictEqual(val, 2);
        });
      });

      it('should increment again', function() {
        return brain.incrby('somenumber', 1).then(function(val) {
          assert.strictEqual(val, 3);
        });
      });
    });

    describe('lists', function() {
      var listName = 'test-list';
      var listValue = {somevalue: 42};

      it('should lpush', function() {
        return brain.lpush(listName, listValue).then(function() {
          return brain.lindex(listName, 0).then(function(val) {
            assert.strictEqual(val.somevalue, listValue.somevalue);
          });
        });
      });

      it('should rpush', function() {
        return brain.rpush(listName, {someothervalue: 13}).then(function() {
          return brain.lindex(listName, 1).then(function(val) {
            assert.strictEqual(val.someothervalue, 13);
          });
        });
      });

      it('should get entire list', function() {
        return brain.lgetall(listName).then(function(values) {
          assert.strictEqual(values.length, 2);
          assert.strictEqual(values[0].somevalue, listValue.somevalue);
          assert.strictEqual(values[1].someothervalue, 13);
        });
      });

      it('should get by index', function() {
        return brain.lindex(listName, 1).then(function(val) {
          assert.strictEqual(val.someothervalue, 13);
        });
      });

      it('should insert after value', function() {
        return brain.linsert(listName, 'AFTER', listValue, {cheese: 'beans'}).then(function() {
          return brain.lindex(listName, 1).then(function(val) {
            assert.strictEqual(val.cheese, 'beans');
          });
        });
      });

      it('should insert before value', function() {
        return brain.linsert(listName, 'BEFORE', listValue, {salsa: 'taco'}).then(function() {
          return brain.lindex(listName, 0).then(function(val) {
            assert.strictEqual(val.salsa, 'taco');
          });
        });
      });

      it('should get length', function() {
        return brain.llen(listName).then(function(length) {
          assert.strictEqual(length, 4);
        });
      });

      it('should set value at index', function() {
        return brain.lset(listName, 1, {tortilla: 'flour'}).then(function() {
          return Q.all([
            brain.lindex(listName, 1).then(function(val) {
              assert.strictEqual(val.tortilla, 'flour');
            }),
            brain.llen(listName).then(function(length) {
              assert.strictEqual(length, 4);
            })
          ]);
        });
      });

      it('should return null for non-existant index', function() {
        return brain.lindex(listName, 5).then(function(val) {
          assert.strictEqual(val, null);
        });
      });

      it('should get list range', function() {
        return brain.lrange(listName, 1, 2).then(function(values) {
          assert.strictEqual(values.length, 2);
          assert.strictEqual(values[0].tortilla, 'flour');
          assert.strictEqual(values[1].cheese, 'beans');
        });
      });

      it('should remove value', function() {
        return brain.lrem(listName, {tortilla: 'flour'}).then(function() {
          return brain.llen(listName).then(function(length) {
            assert.strictEqual(length, 3);
          });
        });
      });
    });

    describe('sets', function() {
      var setName = 'test-set';
      var setValue = {tacos: 'delicious'};
      var setValue2 = {beans: 'cheese'};

      it('should add', function() {
        return brain.sadd(setName, setValue).then(function() {
          return Q.all([
            brain.sismember(setName, setValue).then(function(isMember) {
              assert.strictEqual(isMember, true);
            }),
            brain.scard(setName).then(function(length) {
              assert.strictEqual(length, 1);
            })
          ]);
        });
      });

      it('should try to add again', function() {
        return brain.sadd(setName, setValue).then(function() {
          return Q.all([
            brain.sismember(setName, setValue).then(function(isMember) {
              assert.strictEqual(isMember, true);
            }),
            brain.scard(setName).then(function(length) {
              assert.strictEqual(length, 1);
            })
          ]);
        });
      });

      it('should add a different value', function() {
        return brain.sadd(setName, setValue2).then(function() {
          return Q.all([
            brain.sismember(setName, setValue2).then(function(isMember) {
              assert.strictEqual(isMember, true);
            }),
            brain.scard(setName).then(function(length) {
              assert.strictEqual(length, 2);
            })
          ]);
        });
      });

      it('should test membership (positive)', function() {
        return brain.sismember(setName, setValue).then(function(isMember) {
          assert.strictEqual(isMember, true);
        });
      });

      it('should test membership (negative)', function() {
        return brain.sismember(setName, {taco: 'cup'}).then(function(isMember) {
          assert.strictEqual(isMember, false);
        });
      });

      it('should test cardinality', function() {
        return brain.scard(setName).then(function(length) {
          assert.strictEqual(length, 2);
        })
      });

      it('should remove', function() {
        return brain.srem(setName, setValue).then(function() {
          return Q.all([
            brain.sismember(setName, setValue).then(function(isMember) {
              assert.strictEqual(isMember, false);
            }),
            brain.scard(setName).then(function(length) {
              assert.strictEqual(length, 1);
            })
          ]);
        });
      });

      it('should get all members', function() {
        return brain.smembers(setName).then(function(values) {
          assert.strictEqual(values.length, 1);
          assert.strictEqual(values[0].beans, 'cheese');
        });
      });

      it('should get random member', function() {
        return brain.srandmember(setName).then(function(val) {
          assert.strictEqual(val.beans, 'cheese');
        });
      });

      it('should pop', function() {
        return brain.spop(setName).then(function(val) {
          assert.strictEqual(val.beans, 'cheese');

          return Q.all([
            brain.scard(setName).then(function(length) {
              assert.strictEqual(length, 0);
            }),
            brain.sismember(setName, setValue2).then(function(isMember) {
              assert.strictEqual(isMember, false);
            })
          ]);
        });
      });

      it('should get null instead of random member', function() {
        return brain.srandmember(setName).then(function(val) {
          assert.strictEqual(val, null);
        });
      });
    });

    describe('hash table', function() {
      //TODO
    });
  });
};
