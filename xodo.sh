#!/bin/sh

main() {
	if [ -z "$1" ]; then
		echo "Missing arguments" >&2
		display_usage >&2
		return 1
	elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
		display_usage
	elif [ "$1" = "--setup" ]; then
		shift
		setup "$@"
	else
		execute "$@"
	fi
}

execute() {
	command=""
	asuser=""

	while [ -n "$1" ]; do
		if [ "$1" = "--as" ]; then
			if [ -z "$2" ]; then
				echo "--as user not specified" >&2
				display_usage >&2
				return 1
			elif [ -n "$asuser" ]; then
				echo "--as user specified twice" >&2
				display_usage >&2
				return 1
			fi

			asuser="$2"
			shift
			shift
		elif [ -z "$command" ]; then
			command="$1"
			shift
		elif [ "$1" = "--" ]; then
			shift
			break
		else
			break
		fi
	done

	if [ -z "$command" ]; then
		echo "Command not specified" >&2
		return 1
	fi

	cmdfullpath="`which -- $command`"
	if [ -z "$cmdfullpath" ]; then
		echo "Command not found: $command" >&2
		return 1
	fi

	if [ -z "$asuser" ]; then
		basename="`basename $cmdfullpath`"
		asuser="$USER-$basename"
	fi

	otherhome="`grep ^$asuser: /etc/passwd | head -n1 | cut -d: -f6`"
	if [ -z "$otherhome" ]; then
		echo "Could not find home of $asuser" >&2
		return 1
	fi

	authfile="$otherhome/.Xauthority"

	set -e
	touch $authfile
	xauth -f $authfile generate $DISPLAY . trusted
	chgrp $asuser $authfile
	chmod g+r $authfile

	cd $otherhome

	# Closes IO handlers to avoid tty manipulation
	# See: https://github.com/garotosopa/xodo/issues/1

	XAUTHORITY="$authfile" exec perl -e "
		use strict;
		use warnings;
		use POSIX qw(setsid uname);
		my (\$sysname) = uname();
		close STDIN; close STDOUT; close STDERR;
		fork and exit;
		setsid;
		if (\$sysname eq \"OpenBSD\") {
			exec 'doas', '-u', \$ARGV[0], \$ARGV[1], @ARGV[2 .. @ARGV-1];
		} else {
			exec 'sudo', '-u', \$ARGV[0], \$ARGV[1], (defined \$ARGV[2] ? @ARGV[2 .. @ARGV-1] : ());
		}
	" -- "$asuser" "$cmdfullpath" "$@"
}

setup() {
	if [ -z "$1" ]; then
		echo "Command not specified" >&2
		display_usage >&2
		return 1
	fi

	command="`which -- $1`"

	if [ -z "$command" ]; then
		echo "Command not found: $command" >&2
		return 1
	fi

	basename="`basename $command`"

	shift

	while [ -n "$1" ]; do
		if [ "$1" = "--as" ]; then
			if [ -z "$2" ]; then
				echo "--as user not specified" >&2
				display_usage >&2
				return 1
			elif [ -n "$asuser" ]; then
				echo "--as user specified twice" >&2
				display_usage >&2
				return 1
			fi

			asuser="$2"
			shift
			shift
		elif [ "$1" = "--for" ]; then
			if [ -z "$2" ]; then
				echo "--for user not specified" >&2
				display_usage >&2
				return 1
			elif [ -n "$foruser" ]; then
				echo "--for user specified twice" >&2
				display_usage >&2
				return 1
			fi

			foruser="$2"
			shift
			shift
		else
			echo "Invalid argument: $1" >&2
			display_usage
			return 1
		fi
	done

	foruser="${foruser-$USER}"
	asuser="${asuser-$foruser-$basename}"

	case "`uname`" in
		Linux)
			setup_function=setup_linux
			priv_file=/etc/sudoers.d/xodo
			;;
		OpenBSD)
			setup_function=setup_openbsd
			priv_file=/etc/doas.conf
			;;
		*)
			echo "Unsupported platform: `uname`" >&2
			return 1
			;;
	esac

	echo "The following steps will be executed:"
	echo " - add user $asuser if it doesn't exist;"
	echo " - make $asuser's home readable and writable by its group;"
	echo " - add group $asuser to user $foruser;"
	echo " - add an entry to $priv_file"
	echo "   allowing existing user $foruser"
	echo "   to execute $command"
	echo "   as new user $asuser with no password."

	echo -n "Proceed? [y/n] "
	read proceed
	if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
		echo "Aborted."
		return 1
	fi

	set -e

	$setup_function "$command" "$asuser" "$foruser"

	echo "Done."
	echo "If user $foruser is logged in, it must log out and in again before using xodo as $asuser, so that it gets added to the new group."
}

setup_linux() {
	command="$1"
	asuser="$2"
	foruser="$3"

	if [ -z "`grep "^$asuser:" /etc/passwd`" ]; then
		useradd --create-home --skel /dev/null --user-group --key UMASK=002 "$asuser"
	fi

	usermod -aG "$asuser" "$foruser"
	echo "$foruser ALL = ($asuser) NOPASSWD: $command" >> /etc/sudoers.d/xodo
}

setup_openbsd() {
	command="$1"
	asuser="$2"
	foruser="$3"

	if [ -z "`grep "^$asuser:" /etc/passwd`" ]; then
		useradd -m -k "" "$asuser"
	fi

	usermod -G "$asuser" "$foruser"

	otherhome="`grep "^$asuser:" /etc/passwd | head -n1 | cut -d: -f6`"
	if [ -z "$otherhome" ]; then
		echo "Could not find home of $asuser" >&2
		return 1
	fi

	chmod g+rwX "$otherhome"

	echo "\npermit nopass setenv { DISPLAY HOME=$otherhome USER=$asuser } $foruser as $asuser cmd $command" >> /etc/doas.conf
}

display_usage() {
	echo "usage: xodo <command> [--as <user>] [--] [args...]"
	echo "       xodo --setup <command> [--as <user>] [--for <user>]"
	echo "       xodo --help"
}

main "$@"
