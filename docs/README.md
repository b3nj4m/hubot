# Brobbot

## Getting Started With Brobbot

You will need [node.js](http://nodejs.org/) and [npm](https://npmjs.org/). Joyent has
an [excellent blog post on how to get those installed](http://joyent.com/blog/installing-node-and-npm), so we'll omit those details here.

Once you have node installed, you can clone brobbot using git or download a release package, and install dependencies.

    % curl https://codeload.github.com/b3nj4m/hubot/tar.gz/3.5.2 | tar -xz
    % mv hubot-3.5.2 mybrobbot
    % cd mybrobbot
    % npm install

You now have your own functional brobbot! There's a `bin/brobbot`
command for convenience, to handle launching your brobbot.

    % bin/brobbot
    Brobbot>

This starts brobbot using the [shell adapter](adapters/shell.md), which
is mostly useful for development. Make note of  `Brobbot>`; this is the name he'll
`respond` to with commands. For example, to list available commands:

    % bin/brobbot
    Brobbot> brobbot: help
    brobbot <keyword> tweet - Returns a link to a tweet about <keyword>
    brobbot <user> is a badass guitarist - assign a role to a user
    brobbot <user> is not a badass guitarist - remove a role from a user
    brobbot animate me <query> - The same thing as `image me`, except adds a few parameters to try to return an animated GIF instead.
    brobbot convert me <expression> to <units> - Convert expression to given units.
    brobbot die - End brobbot process
    brobbot echo <text> - Reply back with <text>
    brobbot fake event <event> - Triggers the <event> event for debugging reasons
    brobbot help - Displays all of the help commands that Brobbot knows about.
    brobbot help <query> - Displays all help commands that match <query>.
    brobbot image me <query> - The Original. Queries Google Images for <query> and returns a random top result.
    brobbot map me <query> - Returns a map view of the area returned by `query`.
    brobbot mustache me <query> - Searches Google Images for the specified query and mustaches it.
    brobbot mustache me <url> - Adds a mustache to the specified URL.
    brobbot ping - Reply with pong
    brobbot show storage - Display the contents that are persisted in the brain
    brobbot show users - Display all users that brobbot knows about
    brobbot the rules - Make sure brobbot still knows the rules.
    brobbot time - Reply with current time
    brobbot translate me <phrase> - Searches for a translation for the <phrase> and then prints that bad boy out.
    brobbot translate me from <source> into <target> <phrase> - Translates <phrase> from <source> into <target>. Both <source> and <target> are optional
    brobbot who is <user> - see what roles a user has
    brobbot youtube me <query> - Searches YouTube for the query and returns the video embed link.
    brobbot pug bomb N - get N pugs
    brobbot pug me - Receive a pug
    brobbot ship it - Display a motivation squirrel

You almost definitely will want to change his name to give him some more character. bin/brobbot takes a `--name`:

    % bin/brobbot --name mybrobbot
    mybrobbot>

Your brobbot will now respond as `mybrobbot`. This is
case-insensitive, and can be prefixed with `@` or suffixed with `:`. These are equivalent:

    MYBROBBOT help
    mybrobbot help
    @mybrobbot help
    mybrobbot: help

## Scripting

Brobbot's power comes through scripting. Read [docs/scripting.md](scripting.md) for the deal on bending brobbot to your will using code.

There are scripts released as npm packages. If you find one you want to use:

    npm install brobbot-packagename --save

You can specify which scripts to load using the `-s` option (brobbot will prepend `'brobbot-'` for you):

    bin/brobbot -s packagename,packagename2

## Adapters

Brobbot uses the adapter pattern to support multiple chat-backends. Read available adapters in [docs/adapters.md](adapters.md), along with how to configure them.
You can specify which adapter to use with the `-a` option:

    bin/brobbot -a slack

## Brains

Brobbot can support multiple brain adapters. See [docs/brains.md](brains.md). You can specify which brain to use with the `-b` option:

    bin/brobbot -b redis

## Deploying

You can deploy brobbot to Heroku, which is the officially supported method.
Additionally you are able to deploy brobbot to a UNIX-like system or Windows.
Please note the support for deploying to Windows isn't officially supported.

* [Deploying Brobbot onto Heroku](deploying/heroku.md)
* [Deploying Brobbot onto UNIX](deploying/unix.md)
* [Deploying Brobbot onto Windows](deploying/windows.md)

## Patterns

Using custom scripts, you can quickly customize Brobbot to be the most life embettering robot he can be. Read [docs/patterns.md](patterns.md) for some nifty tricks that may come in handy as you teach him new skills.
