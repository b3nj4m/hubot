# Contributing

We love pull requests. Here's a quick guide:

1. Check for [existing issues](https://github.com/github/brobbot/issues) for duplicates and confirm that it hasn't been fixed already in the [master branch](https://github.com/github/brobbot/commits/master)
2. Fork the repo, and clone it locally
3. `npm link` to make your cloned repo available to npm
4. Follow [Getting Started](docs/README.md) to generate a testbot (no automated tests yet :sob:)
5. `npm link brobbot` in your newly created bot to use your brobbot fork
6. Create a new branch for your contribution
7. Push to your fork and submit a pull request

At this point you're waiting on us. We like to at least comment on, if not
accept, pull requests within a few days. We may suggest some changes or improvements or alternatives.

Some things that will increase the chance that your pull request is accepted:

* Update the documentation: code comments, example code, guides. Basically,
  update anything is affected by your contribution.
* Include any information that would be relevant to reproducing bugs, use cases for new features, etc.

* Discuss the impact on existing [brobbot installs](docs/README.md), [brobbot adapters](docs/adapters.md), and [brobbot scripts](docs/scripting.md) (e.g. backwards compatibility)
  * If the change does break compatibility, how can it be updated to become backwards compatible, while directing users to the new way of doing things?
* Your commits are associated with your GitHub user: https://help.github.com/articles/why-are-my-commits-linked-to-the-wrong-user/
* Make pull requests against a feature branch,
* Don't update the version in `package.json`, as the maintainers will manage that in a follow-up PR to release

Syntax:

  * Two spaces, no tabs.
  * No trailing whitespace. Blank lines should not have any space.
  * Prefer `and` and `or` over `&&` and `||`
  * Prefer single quotes over double quotes unless interpolating strings.
  * `MyClass.myMethod(my_arg)` not `myMethod( my_arg )` or `myMethod my_arg`.
  * `a = b` and not `a=b`.
  * Follow the conventions you see used in the source already.

# Releasing

This section is for maintainers of brobbot. Here's the current process for releasing:

* create a `release-vX.X.X` branch to release off of
* determine what version to release as:
  * bug fix? patch release
  * new functionality that is backwards compatible? minor version
  * breaking change? major release, but think about if it can be fixed to be a minor release instead
* update `package.json`
* summarize changes in `CHANGELOG.md`
* create a pull request, and cc pull requests included in this release, as well as their contributors
* merge pull request
* checkout master branch, and run `script/release`
