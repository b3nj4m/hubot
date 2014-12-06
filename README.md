# Brobbot

Brobbot is a chat bot, modeled after GitHub's Campfire bot, hubot. He's pretty
cool. He's extendable with scripts, and can work on [many different chat services](docs/adapters.md).

This repository provides a library that's distributed by `npm` that you
use for building your own bots.  See the [docs/README.md](docs/README.md)
for details on getting up and running with your very own robot friend.

## Forked from Hubot

Brobbot was forked from Hubot. The main motivation being better support for scripts with persistent storage.

### Key differences

#### Loadable brain modules

Brobbot's brain can be a simple Javascript object held in-memory (the deafult `dumb` brain), but you can also load a different brain module to enable a large, fast, persistent brain.
Brobbot's brain operations return promises to make your async code nice and clean.
Brain modules can also provide a `ready` promise in order to signal that the brain is connected/authenticated/whatever it needs to do before it's ready.
Check out [the brain docs](docs/brains.md) for more info.

To load a brain module, use the `-b` switch when running `bin/brobbot`. e.g.

```bash
bin/brobbot -b redis
```

- [Redis brain](https://npmjs.org/package/brobbot-redis-brain)
- More to come soon!

#### Message queues

Brobbot maintains a message queue for each message handler, which means your handler can opt to process one message at a time with no concurrency.

#### Improved listener regex matching

Brobbot removes its name from the beginning of messages addressed to it before testing regexen against the message. This means that you can safely use anchors (`^`) at the beginning of your `respond` regex, which helps reduce false-positives.

