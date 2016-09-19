xodo
====

Execute commands in Xorg as another user.

## Getting started

    $ ftp https://raw.githubusercontent.com/garotosopa/xodo/master/xodo.sh
    $ chmod +x xodo.sh
    $ doas mv -i xodo.sh /usr/local/bin/xodo

If you don't have `doas` privilege for this, become `root` and copy the file accordingly.

## Usage

    $ doas xodo --setup firefox
    $ xodo firefox

If you don't have `doas` privilege for the initial setup, become `root` and setup `xodo` with the `--for` option as described further below.

## Command-line options

    xodo <command> [--as <user>]
    xodo --setup <command> [--as <user>] [--for <user>]
    xodo --help

## Description

The `xodo` utility authorizes another user to connect to the active Xorg display, then executes the given command as this other user. It's been developed to ease the steps for running desktop programs with different privileges than your own, so that a vulnerability doesn't compromise anything other than the program itself.

Essentially, all `xodo` does is call `xauth` and `doas`, and it can also configure new users automatically with the `--setup` option.

Before using `xodo` for executing a program, another user must exist, preferably for the sole purpose of running said program. It can be created either manually or using the `--setup` option, and the main user that's going to execute `xodo` must be allowed in `doas.conf` to execute the given command as this other user. This is already taken care of when using `xodo`'s `--setup` option. Unless told otherwise, this other user defaults to `<user>-<command>`.

The command argument is mandatory and can either be an absolute or relative path, or just the command basename. In this latter case, the command is assumed to be in the current `PATH`. Arguments to the command being executed are not supported yet.

Supported options are as follows:

### --as <user>

When specified, this is the user as which the command is going to be executed, or the user that's going to be created when invoked with the `--setup` option.

When ommitted, the convention assumes `<user>-<command>`. During setup, the username part can be overriden with the `--for` option. Otherwrise, the `$USER` environment variable is used.

### --for <user>

When specified, this is the user that will be allowed to execute the command as another user.  This options is only used with `--setup` for adding an entry to `doas.conf`.

When ommitted, the current username in the `$USER` environment variable is used.

### --help<br>-h

Display basic usage syntax.

### --setup <command>

Adds a new user and authorizes the current user to execute the given command as this new user, by appending an entry to `doas.conf`. The current user is also added to the new user's own group, in order to have access to its files.

If the new user already exists, no user is added and the current user is not added to any group, but `doas.conf` still gets a new entry.

Options `--as` and `--for` overrides the username being created and the existing user that will be allowed to execute the command, respectively.

This option must be used as `root`, as it calls `useradd` and `usermod`, and writes to `/etc/doas.conf`.

## Examples

Configure a separate user for Mike to execute Firefox:

    mike$ doas xodo --setup firefox

This assumes that Mike is permitted in `doas.conf` to execute `xodo` as ` root`. If that's not so, `root` should be used directly for setting this up for Mike:

    root# xodo --setup firefox --for mike

Either way, now Mike can execute Firefox as the user **mike-firefox**, so
that any vulnerability in Firefox wouldn't compromise Mike's files:

    mike$ xodo firefox

To create a user different than the `<user>-<command>` convention, use the `--as` option during setup:

    root# xodo --setup firefox --for mike --as mike-web

Then specify this different user when executing `xodo`:

    mike$ xodo firefox --as mike-web

## See also

* [doas(1)](http://man.openbsd.org/OpenBSD-current/man1/doas.1)
* [doas.conf(5)](http://man.openbsd.org/OpenBSD-current/man5/doas.conf.5)
* [xauth(1)](http://man.openbsd.org/OpenBSD-current/man1/xauth.1)
