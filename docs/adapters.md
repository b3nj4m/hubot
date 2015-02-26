# Brobbot Adapters

Adapters are the interface to the service you want your brobbot to run on.

## Official Adapters

Brobbot includes one official adapter:

* [Shell](adapters/shell.md), i.e. for use with development

## Third-party Adapters

Third-party adapters are available as `npm` packages. Here is a list of known
adapters, but please [submit an issue](https://github.com/b3nj4m/hubot/issues)
to have yours added to the list:

* [Slack](https://github.com/b3nj4m/hubot-slack)

## Writing Your Own adapter

The best place to start is `src/adapter.coffee`, and inheriting from `Adapter`.
There is not as much documentation as could exist (yet!), so it is worth
reviewing existing adapters as well as how brobbot internally uses an adapter.

There are a few primary methods you should implement:

### run()

This is where you initialize your adapter and establish a connection to the chat service. Your adapter should emit `connected` when it is ready to start accepting messages.

### message(msg)

This is where you receive messages from the chat service and do any transforming necessary before handing them off to brobbot. A typical message brobbot might expect looks like:

```javascript
{
  text: 'some message text',
  room: '#general',
  user: {
    id: 42,
    name: 'some user'
  }
}
```

When you finish transforming, you should call `robot.receive(msg)`.

### send(envelope, messages...)

This is where you take messages from brobbot and send them off to the chat service.

### reply(envelope, messages...)

Similar to `send`, but used to reply to a particular user (`envelope.user`).
