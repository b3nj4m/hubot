# Scripting

Brobbot out of the box doesn't do too much, but it is an extensible, scriptable robot friend.

## Anatomy of a script

Scripts are loaded from external __npm packages__ and specified using the `-s` option:

```bash
npm install brobbot-quote --save
./index.sh -s quote
```

Your `package.json` should specify `brobbot` as a peer-dependency, not a regular dependency. It should also specify a `main` file, which exports a function:

#### package.json
```json
{
  "name": "brobbot-quote",
  "main": "index.js",
  "peerDependecies": {
    "brobbot": "4.x"
  }
  ...
}
```
#### index.js
```javascript
module.exports = function (robot) {
  //your code here
};
```

The `robot` parameter is an instance of your robot friend. At this point, we can start scripting up some awesomeness.

## Hearing and responding

Since this is a chat bot, the most common interactions are based on messages. Brobbot can `hear` messages said in a room or `respond` to messages directly addressed at it. Both methods take a regular expression and a callback function as parameters. For example:

```javascript
module.exports = function(robot) {
  robot.hear(/badger/i, function(msg) {
    //your code here
  });

  robot.respond(/^open the pod bay doors/i, function(msg) {
    //your code here
  });
};
```

The `robot.hear(/badger/)` callback is called anytime a message's text matches. For example:

* Stop badgering the witness
* badger me
* what exactly is a badger anyways

The `robot.respond(/^open the pod bay doors/i)` callback is only called for messages that are immediately preceded by the robot's name or alias. If the robot's name is HAL and alias is /, then this callback would be triggered for:

*  hal open the pod bay doors
* HAL: open the pod bay doors
* @HAL open the pod bay doors
* /open the pod bay doors

It wouldn't be called for:

* HAL: please open the pod bay doors
   *  because its `respond` is bound to the text immediately following the robot name
*  has anyone ever mentioned how lovely you are when you open the pod bay doors?
   * because it lacks the robot's name

## Send & reply

The `msg` parameter is, despite the name, an instance of [Response](../src/response.js). With it, you can `send` a message back to the room the `msg` came from, `emote` a message to a room (If the given adapter supports it), or `reply` to the person that sent the message. For example:

```javascript
module.exports = function(robot) {
  robot.hear(/badger/i, function(msg) {
    msg.send("Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS");
  });

  robot.respond(/^open the pod bay doors/i, function(msg) {
    msg.reply("I'm afraid I can't let you do that.");
  });

  robot.hear(/I like pie/i, function(msg) {
    msg.emote("makes a freshly baked pie");
  });
};
```

The `robot.hear(/badgers/)` callback sends a message exactly as specified regardless of who said it, "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS".

The `msg.message` object has a property, `isAddressedToBrobbot`, which you can use to differentiate messages addressed to brobbot from those that aren't.

If a user Dave says "HAL: open the pod bay doors", `robot.respond(/^open the pod bay doors/i)` callback sends a message "Dave: I'm afraid I can't let you do that."

## Capturing data

So far, our scripts have had static responses, which while amusing, are boring functionality-wise. `msg.match` has the result of `match`ing the incoming message against the regular expression. This is just a [JavaScript thing](http://www.w3schools.com/jsref/jsref_match.asp), which ends up being an array with index 0 being the full text matching the expression. If you include capture groups, those will be populated `msg.match`. For example, if we update a script like:

```javascript
  robot.respond(/^open the (.*) doors/i, function(msg) {
    //your code here
  });
```

If Dave says "HAL: open the pod bay doors", then `msg.match[0]` is "open the pod bay doors", and `msg.match[1]` is just "pod bay". Now we can start doing more dynamic things:

```javascript
  robot.respond(/^open the (.*) doors/i, function(msg) {
    var doorType = msg.match[1];
    if (doorType === "pod bay") {
      msg.reply("I'm afraid I can't let you do that.");
    }
    else {
      msg.reply("Opening " + doorType + " doors");
    }
  });
```

## Making HTTP calls

Brobbot can make HTTP calls on your behalf to integrate & consume third party APIs. This can be through an instance of [node-scoped-http-client](https://github.com/technoweenie/node-scoped-http-client) available at `robot.http`. The simplest case looks like:


```javascript
  robot.http("https://midnight-train")
    .get()(function(err, res, body) {
      //your code here
    });
```

A post looks like:

```javascript
  var data = JSON.stringify({
    foo: 'bar'
  });
  robot.http("https://midnight-train")
    .post(data)(function(err, res, body) {
      //your code here
    });
```


`err` is an error encountered on the way, if one was encountered. You'll generally want to check for this and handle accordingly:

```javascript
  robot.http("https://midnight-train")
    .get()(function(err, res, body) {
      if (err) {
        msg.send("Encountered an error :( " + err);
        return;
      }
      //your code here, knowing it was successful
    });
```

`res` is an instance of node's [http.ServerResponse](http://nodejs.org/api/http.html#http_class_http_serverresponse). Most of the methods don't matter as much when using node-scoped-http-client, but of interest are `statusCode` and `getHeader`. Use `statusCode` to check for the HTTP status code, where usually non-200 means something bad happened. Use `getHeader` for peeking at the header, for example to check for rate limiting:

```javascript
  robot.http("https://midnight-train")
    .get()(function(err, res, body) {
      //pretend there's error checking code here
      if (res.statusCode !== 200) {
        msg.send("Request didn't come back HTTP 200 :(");
        return;
      }

      var rateLimitRemaining = res.getHeader('X-RateLimit-Limit');
      if (typeof rateLimitRemaining !== 'undefined' && parseInt(rateLimitRemaining) < 1) {
        msg.send("Rate Limit hit, stop believing for awhile");
      }

      //rest of your code
    });
```

`body` is the response's body as a string, the thing you probably care about the most:

```javascript
  robot.http("https://midnight-train")
    .get()(function(err, res, body) {
      //error checking code here
      msg.send("Got back " + body);
    });
```

### JSON

If you are talking to APIs, the easiest way is going to be JSON because it doesn't require any extra dependencies. When making the `robot.http` call, you should usually set the  `Accept` header to give the API a clue that's what you are expecting back. Once you get the `body` back, you can parse it with `JSON.parse`:

```javascript
  robot.http("https://midnight-train")
    .header('Accept', 'application/json')
    .get()(function(err, res, body) {
      //error checking code here
      var data = JSON.parse(body);
      msg.send(data.passenger + " taking midnight train going " + data.destination);
    });
```

It's possible to get non-JSON back, like if the API hit an error and it tries to render a normal HTML error instead of JSON. To be on the safe side, you should check the `Content-Type`, and catch any errors while parsing.

```javascript
  robot.http("https://midnight-train")
    .header('Accept', 'application/json')
    .get()(function(err, res, body) {
      //err & response status checking code here
      if (response.getHeader('Content-Type') !== 'application/json') {
        msg.send("Didn't get back JSON :(");
        return;
      }

      var data = null;
      try {
        data = JSON.parse(body);
      }
      catch (error) {
        msg.send("Ran into an error parsing JSON :(");
        return;
      }
      //your code here
    });
```

### XML

XML APIs are harder because there's not a bundled XML parsing library. It's beyond the scope of this documentation to go into detail, but here are a few libraries to check out:

* [xml2json](https://github.com/buglabs/node-xml2json) (simplest to use, but has some limitations)
* [jsdom](https://github.com/tmpvar/jsdom) (JavaScript implementation of the W3C DOM)
* [xml2js](https://github.com/Leonidas-from-XIV/node-xml2js)

### Screen scraping

For those times that there isn't an API, there's always the possibility of screen-scraping. It's beyond the scope of this documentation to go into detail, but here's a few libraries to check out:

* [cheerio](https://github.com/MatthewMueller/cheerio) (familiar syntax and API to jQuery)
* [jsdom](https://github.com/tmpvar/jsdom) (JavaScript implementation of the W3C DOM)

## Random

A common pattern is to hear or respond to commands, and send with a random funny image or line of text from an array of possibilities. It's annoying to do this in JavaScript out of the box, so Brobbot includes a convenience method:

```javascript
var lulz = ['lol', 'rofl', 'lmao'];
msg.send(msg.random(lulz));
```

## Topic

Brobbot can react to a room's topic changing, assuming that the adapter supports it.

```javascript
module.exports = function(robot) {
  robot.topic(function(msg) {
    msg.send(msg.message.text + "? That's a Paddlin'");
  });
};
```

## Entering and leaving

Brobbot can see users entering and leaving, assuming that the adapter supports it.

```javascript
var enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you'];
var leaveReplies = ['Are you still there?', 'Target lost', 'Searching'];

module.exports = function(robot) {
  robot.enter(function(msg) {
    msg.send(msg.random(enterReplies));
  });
  robot.leave(function(msg) {
    msg.send(msg.random(leaveReplies));
  });
};
```

## Environment variables

Brobbot can access the environment he's running in, just like any other node program, using [`process.env`](http://nodejs.org/api/process.html#process_process_env). This can be used to configure how scripts are run, with the convention being to use the `BROBBOT_` prefix.

```javascript
var answer = process.env.BROBBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING;

module.exports = function(robot) {
  robot.respond(/^what is the answer to the ultimate question of life/, function(msg) {
    msg.send(answer + ", but what is the question?");
  });
};
```

Take care to make sure the script can load if it's not defined, give the Brobbot developer notes on how to define it, or default to something. It's up to the script writer to decide if that should be a fatal error (e.g. brobbot exits), or not (make any script that relies on it to say it needs to be configured. When possible and when it makes sense to, having a script work without any other configuration is preferred.

Here we can default to something:

```javascript
var answer = process.env.BROBBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING || 42;

module.exports = function(robot) {
  robot.respond(/^what is the answer to the ultimate question of life/, function(msg) {
    msg.send(answer + ", but what is the question?");
  });
};
```

Here we exit if it's not defined:

```javascript
var answer = process.env.BROBBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING;
if (!answer) {
  console.log("Missing BROBBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again");
  process.exit(1);
}

module.exports = function(robot) {
  robot.respond(/^what is the answer to the ultimate question of life/, function(msg) {
    msg.send(answer + ", but what is the question?");
  });
};
```

And lastly, we update the `robot.respond` to check it:

```javascript
var answer = process.env.BROBBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING;

module.exports = function(robot) {
  robot.respond(/^what is the answer to the ultimate question of life/, function(msg) {
    if (!answer) {
      msg.send("Missing BROBBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again");
      return;
    }
    msg.send(answer + ", but what is the question?");
  });
};
```

## Timeouts and Intervals

Brobbot can run code later using JavaScript's built-in [setTimeout](http://nodejs.org/api/timers.html#timers_settimeout_callback_delay_arg). It takes a callback method, and the amount of time to wait before calling it:

```javascript
module.exports = function(robot) {
  robot.respond(/^you are a little slow/, function(msg) {
    setTimeout(function() {
      msg.send("Who you calling 'slow'?");
    }, 60 * 1000);
  });
};
```

Additionally, Brobbot can run code on an interval using [setInterval](http://nodejs.org/api/timers.html#timers_setinterval_callback_delay_arg). It takes a callback method, and the amount of time to wait between calls:

```javascript
module.exports = function(robot) {
  robot.respond(/^annoy me/, function(msg) {
    msg.send("Hey, want to hear the most annoying sound in the world?");
    setInterval(function() {
      msg.send("AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH");
    }, 1000);
  });
};
```

Both `setTimeout` and `setInterval` return the ID of the timeout or interval it created. This can be used to to `clearTimeout` and `clearInterval`.

```javascript
module.exports = function(robot) {
  var annoyIntervalId = null;

  robot.respond(/^annoy me/, function(msg) {
    if (annoyIntervalId) {
      msg.send("AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH");
      return;
    }

    msg.send("Hey, want to hear the most annoying sound in the world?");
    annoyIntervalId = setInterval(function() {
      msg.send("AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH");
    }, 1000);
  });

  robot.respond(/^unannoy me/, function(msg) {
    if (annoyIntervalId) {
      msg.send("GUYS, GUYS, GUYS!");
      clearInterval(annoyIntervalId);
      annoyIntervalId = null;
    }
    else {
      msg.send("Not annoying you right now, am I?");
    }
  });
};
```

## HTTP Listener

Brobbot includes support for the [express](http://expressjs.com/guide.html) web framework to serve up HTTP requests. It listens on the port specified by the `PORT` environment variable, and defaults to 8080. An instance of an express application is available at `robot.router`. It can be protected with username and password by specifying `EXPRESS_USER` and `EXPRESS_PASSWORD`. It can automatically serve static files by setting `EXPRESS_STATIC`.

The most common use of this is for providing HTTP end points for services with webhooks to push to, and have those show up in chat.


```javascript
module.exports = function(robot) {
  robot.router.post('/brobbot/chatsecrets/:room', function(req, res) {
    var room = req.params.room;
    var data = JSON.parse(req.body.payload);
    var secret = data.secret;

    robot.messageRoom(room, "I have a secret: " + secret);
    res.send('OK');
  });
};
```

## Events

Brobbot can also respond to events which can be used to pass data between scripts. This is done by encapsulating node.js's [EventEmitter](http://nodejs.org/api/events.html#events_class_events_eventemitter) with `robot.emit` and `robot.on`.

One use case for this would be to have one script for handling interactions with a service, and then emitting events as they come up. For example, we could have a script that receives data from a GitHub post-commit hook, make that emit commits as they come in, and then have another script act on those commits.

```javascript
//src/scripts/github-commits.js
module.exports = function(robot) {
  robot.router.post("/brobbot/gh-commits", function(req, res) {
    robot.emit("commit", {
      user: {}, //brobbot user object
      repo: 'https://github.com/github/brobbot',
      hash: '2e1951c089bd865839328592ff673d2f08153643'
    });
  });
};
```

```javascript
//src/scripts/heroku.js
module.exports = function(robot) {
  robot.on("commit", function(commit) {
    robot.send(commit.user, "Will now deploy " + commit.hash + " from " + commit.repo + "!");
    //deploy code goes here
  });
};
```

If you provide an event, it's highly recommended to include a brobbot user or room object in its data. This would allow for brobbot to notify a user or room in chat.

## Error Handling

No code is perfect, and errors and exceptions are to be expected. Previously, an uncaught exceptions would crash your brobbot instance. Brobbot now includes an `uncaughtException` handler, which provides hooks for scripts to do something about exceptions.

```javascript
# src/scripts/does-not-compute.js
module.exports = function(robot) {
  robot.error(function(err, msg) {
    robot.logger.error("DOES NOT COMPUTE")

    if (msg) {
      msg.reply("DOES NOT COMPUTE");
    }
  });
};
```

You can do anything you want here, but you will want to take extra precaution of rescuing and logging errors, particularly with asynchronous code. Otherwise, you might find yourself with recursive errors and not know what is going on.

Under the hood, there is an 'error' event emitted, with the error handlers consuming that event. The uncaughtException handler [technically leaves the process in an unknown state](http://nodejs.org/api/process.html#process_event_uncaughtexception). Therefore, you should rescue your own exceptions whenever possible, and emit them yourself. The first argument is the error emitted, and the second argument is an optional message that generated the error.

Using previous examples:

```javascript
  robot.router.post('/brobbot/chatsecrets/:room', function(req, res) {
    var room = req.params.room;
    var data = null;
    try {
      data = JSON.parse(req.body.payload);
    }
    catch (err) {
      robot.emit('error', error);
    }
    //rest of the code here
  });

  robot.hear(/midnight train/i, function(msg) {
    robot.http("https://midnight-train")
      .get()(function(err, res, body) {
        if (err) {
          msg.reply("Had problems taking the midnight train");
          robot.emit('error', err, msg);
          return;
        }
        //rest of code here
      });
  });
```

For the second example, it's worth thinking about what messages the user would see. If you have an error handler that replies to the user, you may not need to add a custom

## Documenting Scripts

Brobbot scripts can be documented with comments at the top of their file, for example:

```javascript
// Description:
//   <description of the scripts functionality>
//
// Dependencies:
//   "<module name>": "<module version>"
//
// Configuration:
//   LIST_OF_ENV_VARS_TO_SET
//
// Notes:
//   <optional notes required for the script>
//
// Author:
//   <github username of the original script author>
```

## Help Commands

Define a command to be shown in the `brobbot help` output (`'brobbot'` will be replaced with the actual name of your robot):

```javascript
robot.helpCommand('brobbot <trigger>', '<what the respond trigger does>');
robot.helpCommand('<trigger>', '<what the hear trigger does>');
```

When documenting commands, here are some best practices:

* Refer to the Brobbot as brobbot, even if your brobbot is named something else. It will automatically be replaced with the correct name. This makes it easier to share scripts without having to update docs.
* For `robot.respond` documentation, always prefix with `brobbot`. Brobbot will automatically replace this with your robot's name, or the robot's alias if it has one
* Check out how man pages document themselves. In particular, brackets indicate optional parts, '...' for any number of arguments, etc.

## Persistence

Brobbot supports loadable brain modules for persisting data. The default module is just an in-memory Javascript object.
The API is based on the Redis api; indeed you can even install a Redis-backed brobbot brain (https://npmjs.org/package/brobbot-redis-brain).

```javascript
robot.respond(/^have a soda/i, function(msg) {
  //Get number of sodas had (coerced to a number).
  return robot.brain.get('totalSodas').then(function(sodasHad) {
    if (sodasHad > 4) {
      msg.reply("I'm too fizzy..");
    }
    else {
      msg.reply('Sure!');
    }
    return robot.brain.set('totalSodas', sodasHad + 1);
  });
});

robot.respond(/^sleep it off/i, function(msg) {
  return robot.brain.set('totalSodas', 0).then(function() {
    msg.send('zzzzz');
  });
});
```

If the script needs to lookup user data, there are methods on `robot.brain` for looking up one or many users by id, name, or 'fuzzy' matching of name: `userForName`, `userForId`, `userForFuzzyName`, and `usersForFuzzyName`.

```javascript
module.exports = function(robot) {

  robot.respond(/^who is @?([\w .\-]+)\?*$/i, function(msg) {
    var name = msg.match[1].trim();

    return robot.brain.usersForFuzzyName(name).then(function(users) {
      if (users.length === 1) {
        var user = users[0];
        //Do something interesting here..
        msg.send(name + " is user - " + user);
      }
    });
  });
};
```
