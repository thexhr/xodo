xodo
====

Execute commands in Xorg as another user.

## Getting started

    $ ftp https://raw.githubusercontent.com/garotosopa/xodo/master/xodo.sh
    $ chmod +x xodo.sh
    $ doas mv -i xodo.sh /usr/local/bin/xodo

If your user doesn't have `doas` privileges, become `root` and copy the file accordingly.

## Usage

    $ doas xodo --setup firefox
    $ xodo firefox

If your user doesn't have `doas` privileges, become `root` and setup `xodo` with the `--for` option as described further below.

## Command-line options

    xodo <command> [--as <user>]
    xodo --setup <command> [--as <user>] [--for <user>]
    xodo --help

## Description

The `xodo` utility authorizes a conventioned user in the form of `$user-$command` to connect to the active Xorg display, then executes the given command as this other user.

This script has been developed to avoid a potential vulnerability in a desktop program to compromise anything else other than the program itself. To accomplish this, each program is executed as a different user that connects to the active Xorg display, using an Xauthority cookie file that's setup automatically by `xodo`.

Before using `xodo` to execute commands, the unprivileged user must be created first, either manually or using the `--setup` option. Besides adding the new user, the main user that's going to execute `xodo` must be allowed in `doas.conf` to execute the given command as the other user. This is already taken care of when using `xodo`'s `--setup` option.

The command argument is mandatory and can either be an absolute or relative path, or just the command basename. In this latter case, the command is assumed to be in the current `PATH`. Arguments to the command being executed are not supported yet.

The options are as follows:

### --as <user>

When specified, this is the unprivileged user as which the command is going to be executed, or the user that's going to be created when invoked with the `--setup` option.

When ommitted, the convention assumes `$user-$command` instead. In this case, `$USER` environment variable is assumed. During setup, this can be overridden with the `--for` option.

### --for <user>

When specified, this is the user that will be allowed to execute the command as another user.  This options is only used with `--setup`.

When ommitted, the `$USER` environment variable is used.

### --help<br>-h

Display basic usage syntax.

### --setup <command>

Adds a new user and authorizes the current user in `doas.conf` to execute the given command as the new unprivileged user. The current user is also added to the new user's group.

If the new user already exists, no user is added and the current user is not added to any group, but `doas.conf` still gets a new entry.

Options `--as` and `--for` overrides the username being created, and the existing user that will be allowed to execute the command, respectively.

This option must be used as `root`, as it calls `useradd` and `usermod`, and also appends an entry to `doas.conf`.

## Examples

Configure an unprivileged user for Mike to execute Firefox:

    mike$ doas xodo --setup firefox

This assumes that Mike is permitted in `doas.conf` to execute `xodo` as ` root`. Otherwise, `root` should be used directly for setting this up for Mike:

    root# xodo --setup firefox --for mike

Either way, now Mike can execute Firefox as the user **mike-firefox**, so
that any vulnerability in Firefox wouldn't compromise Mike's files:

    mike$ xodo firefox

To create an unprivileged user different than the `$user-$command` convetion, use the `--as` option during setup:

    root# xodo --setup firefox --for mike --as mike-work

Then specify this different user when executing `xodo`:

    mike$ xodo firefox --as mike-work

## See also

* [doas(1)](http://man.openbsd.org/OpenBSD-current/man1/doas.1)
* [doas.conf(5)](http://man.openbsd.org/OpenBSD-current/man5/doas.conf.5)
* [xauth(1)](http://man.openbsd.org/OpenBSD-current/man1/xauth.1)
