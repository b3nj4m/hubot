# Patterns

Shared patterns for dealing with common Brobbot scenarios.

## Renaming the Brobbot instance

When you rename Brobbot, he will no longer respond to his former name. In order to train your users on the new name, you may choose to add a deprecation notice when they try to say the old name. The pattern logic is:

* listen to all messages that start with the old name
* reply to the user letting them know about the new name

Setting this up is very easy:

1. Create a [bundled script](scripting.md) in the `scripts/` directory of your Brobbot instance called `rename-brobbot.coffee`
2. Add the following code, modified for your needs:

```coffeescript
# Description:
#   Tell people brobbot's new name if they use the old one
#
# Commands:
#   None
#
module.exports = (robot) ->
  robot.hear /^brobbot:? (.+)/i, (msg) ->
    response = "Sorry, I'm a diva and only respond to #{robot.name}"
    response += " or #{robot.alias}" if robot.alias
    msg.reply response
    return

```

In the above pattern, modify both the brobbot listener and the response message to suit your needs.

Also, it's important to note that the listener should be based on what brobbot actually hears, instead of what is typed into the chat program before the Brobbot Adapter has processed it. For example, the [HipChat Adapter](https://github.com/hipchat/brobbot-hipchat) converts `@brobbot` into `brobbot:` before passing it to Brobbot.

## Deprecating or Renaming Listeners

If you remove a script or change the commands for a script, it can be useful to let your users know about the change. One way is to just tell them in chat or let them discover the change by attempting to use a command that no longer exists. Another way is to have Brobbot let people know when they've used a command that no longer works.

This pattern is similar to the Renaming the Brobbot Instance pattern above:

* listen to all messages that match the old command
* reply to the user letting them know that it's been deprecated

Here is the setup:

1. Create a [bundled script](scripting.md) in the `scripts/` directory of your Brobbot instance called `deprecations.coffee`
2. Copy any old command listeners and add them to that file. For example, if you were to rename the help command for some silly reason:

```coffeescript
# Description:
#   Tell users when they have used commands that are deprecated or renamed
#
# Commands:
#   None
#
module.exports = (robot) ->
  robot.respond /help\s*(.*)?$/i, (msg) ->
    msg.reply "That means nothing to me anymore. Perhaps you meant `docs` instead?"
    return

```
