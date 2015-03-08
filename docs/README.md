# Brobbot

## Getting Started With Brobbot

You will need [node.js](http://nodejs.org/) and [npm](https://npmjs.org/). Joyent has
an [excellent blog post on how to get those installed](http://joyent.com/blog/installing-node-and-npm), so we'll omit those details here.

Once you have node installed, you can clone [brobbot-instance](https://github.com/b3nj4m/brobbot-instance) using git or download a release package, and install dependencies.

```bash
% curl https://codeload.github.com/b3nj4m/brobbot-instance/tar.gz/1.0.1 | tar -xz
% cd brobbot-instance-1.0.1
% npm install
```

You now have your own functional brobbot! There's a `index.sh` script
for your convenience, to handle launching your brobbot.

```bash
% ./index.sh
Brobbot>
```

This starts brobbot using the [shell adapter](adapters/shell.md), which
is mostly useful for development. Make note of  `Brobbot>`; this is the name he'll
`respond` to with commands. For example, to list available commands:

```bash
% ./index.sh
Brobbot> brobbot help
brobbot animate me <query> - The same thing as `image me`, except adds a few parameters to try to return an animated GIF instead.
brobbot help - Displays all of the help commands that Brobbot knows about.
brobbot help <query> - Displays all help commands that match <query>.
brobbot image me <query> - The Original. Queries Google Images for <query> and returns a random top result.
brobbot youtube me <query> - Searches YouTube for the query and returns the video embed link.
```

You almost definitely will want to change his name to give him some more character. ./index.sh takes a `--name`:

```bash
% ./index.sh --name mybrobbot
mybrobbot>
```

Your brobbot will now respond as `mybrobbot`. This is
case-insensitive, and can be prefixed with `@` or suffixed with `:`. These are equivalent:

```
MYBROBBOT help
mybrobbot help
@mybrobbot help
mybrobbot: help
```

## Scripting

Brobbot's power comes through scripting. Read [docs/scripting.md](scripting.md) for the deal on bending brobbot to your will using code.

There are scripts released as npm packages. If you find one you want to use:

```bash
npm install brobbot-packagename --save
```

You can specify which scripts to load using the `-s` option (brobbot will prepend `'brobbot-'` for you):

```bash
./index.sh -s packagename,packagename2
```

## Adapters

Brobbot uses the adapter pattern to support multiple chat-backends. Read available adapters in [docs/adapters.md](adapters.md), along with how to configure them.
You can specify which adapter to use with the `-a` option:

```bash
./index.sh -a slack
```

## Brains

Brobbot can use one of multiple brain adapters. See [docs/brains.md](brains.md). You can specify which brain to use with the `-b` option:

```bash
./index.sh -b redis
```

## Deploying

You can deploy brobbot to Heroku, which is the officially supported method.
Additionally you are able to deploy brobbot to a UNIX-like system or Windows.
Please note the support for deploying to Windows isn't officially supported.

* [Deploying Brobbot onto Heroku](deploying/heroku.md)
* [Deploying Brobbot onto UNIX](deploying/unix.md)
* [Deploying Brobbot onto Windows](deploying/windows.md)
