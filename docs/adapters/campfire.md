# Adapter: Campfire

[Campfire](http://campfirenow.com/) is a web based chat application built by
[37signals](http://37signals.com). The Campfire adapter is one of the original
adapters in Brobbot.

## Getting Started

You will need a Campfire account to start, which you can
[sign up for free](https://signup.37signals.com/campfire/free/signup/new).

Next, you will need to create a user on your Campfire account for your Brobbot,
then give it access so it can join to your rooms. You will need to create a room
if you haven't already.

Brobbot defaults to using its [shell](shell.md), so to use Campfire instead, you
can run brobbot with `-a campfire`:

    % bin/brobbot -a campfire

If you are deploying to Heroku or using foreman, you need to make
sure the brobbot is called with `-a campfire` in the `Procfile`:

    web: bin/brobbot -a campfire -n Brobbot

## Configuring

The adapter requires the following environment variables.

* `BROBBOT_CAMPFIRE_ACCOUNT`
* `BROBBOT_CAMPFIRE_TOKEN`
* `BROBBOT_CAMPFIRE_ROOMS`

### Campfire API Token

This can be found by logging in with your brobbot's account click the **My Info**
link and make a note of the API token.

### Campfire Room IDs

If you join the rooms you want your brobbot to join will see notice a numerical
ID for the room in the URL. Make a note of each ID for the rooms you want your
brobbot to join.

### Campfire Account

This is simply the first part of the domain you visit for your Campfire
account. For example if your Campfire was at `brobbot.campfirenow.com` your
subdomain is `brobbot`. Make a note of the subdomain.

### Configuring the variables on Heroku

    % heroku config:set BROBBOT_CAMPFIRE_TOKEN="..."

    % heroku config:set BROBBOT_CAMPFIRE_ROOMS="123,321"

    % heroku config:set BROBBOT_CAMPFIRE_ACCOUNT="..."

### Configuring the variables on UNIX

    % export BROBBOT_CAMPFIRE_TOKEN="..."

    % export BROBBOT_CAMPFIRE_ROOMS="123,321"

    % export BROBBOT_CAMPFIRE_ACCOUNT="..."

### Configuring the variables on Windows

Using PowerShell:

    setx BROBBOT_CAMPFIRE_TOKEN "..." /m

    setx BROBBOT_CAMPFIRE_ROOMS "123,321" /m 

    setx BROBBOT_CAMPFIRE_ACCOUNT "..." /m
