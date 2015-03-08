var assert = require('assert');
var helper = require('./helper');

describe('httpd', function() {
  var msg;

  before(function(done) {
    helper.adapter.cb = function(result) {
      msg = result;
      helper.ready.then(function() {
        done();
      });
    };

    setTimeout(function() {
      helper.adapter.receive('static');
    }, 100);
  });

  after(function() {
    helper.reset();
  });

  it('should have sent "static" via http server', function() {
    assert.equal(1, helper.sent.length);
    assert.equal("static", msg);
  });
});
