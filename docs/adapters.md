# Brobbot Adapters

Adapters are the interface to the service you want your brobbot to run on.

## Official Adapters

Brobbot includes two official adapters:

* [Shell](adapters/shell.md), i.e. for use with development
* [Campfire](adapters/campfire.md)

## Third-party Adapters

Third-party adapters are available as `npm` packages. Here is a list of known
adapters, but please [submit an issue](https://github.com/github/brobbot/issues)
to have yours added to the list:

* [Flowdock](https://github.com/flowdock/brobbot-flowdock)
* [HipChat](https://github.com/hipchat/brobbot-hipchat)
* [IRC](https://github.com/nandub/brobbot-irc)
* [Partychat](https://github.com/iangreenleaf/brobbot-partychat-hooks)
* [Talker](https://github.com/unixcharles/brobbot-talker)
* [Twilio](https://github.com/jkarmel/brobbot-twilio)
* [Twitter](https://github.com/MathildeLemee/brobbot-twitter)
* [XMPP](https://github.com/markstory/brobbot-xmpp)
* [Gtalk](https://github.com/atmos/brobbot-gtalk)
* [Yammer](https://github.com/athieriot/brobbot-yammer)
* [Skype](https://github.com/netpro2k/brobbot-skype)
* [Jabbr](https://github.com/smoak/brobbot-jabbr)
* [iMessage](https://github.com/lazerwalker/brobbot-imessage)
* [Hall](https://github.com/Hall/brobbot-hall)
* [ChatWork](https://github.com/akiomik/brobbot-chatwork)
* [QQ](https://github.com/xhan/qqbot)
* [AIM](https://github.com/shaundubuque/brobbot-aim)
* [Slack](https://github.com/tinyspeck/brobbot-slack)
* [Lingr](https://github.com/miyagawa/brobbot-lingr)
* [Gitter](https://github.com/huafu/brobbot-gitter2)
* [Proxy](https://github.com/Hammertime38/brobbot-proxy) - This adapter allows the base application to observe, handle, and control events sent to the proxied adapter, all defined in a config object at the root of the module.
* [Visual Studio Online](https://github.com/scrumdod/brobbot-VSOnline)

## Writing Your Own adapter

The best place to start is `src/adapter.coffee`, and inheriting from `Adapter`.
There is not as much documentation as could exist (yet!), so it is worth
reviewing existing adapters as well as how brobbot internally uses an adapter.
