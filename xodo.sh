#!/bin/sh

set -e

main() {
	if [[ "$1" == "" ]]; then
		echo "Missing arguments" >&2
		display_usage >&2
		return 1
	elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
		display_usage
	elif [[ "$1" == "--setup" ]]; then
		shift
		setup $@
	else
		execute $@
	fi
}

execute() {
	command=`which -- $1`
	basename=`basename $command`
	asuser=$USER-$basename

	shift

	if [[ "$1" == "--as" ]]; then
		if [[ "$2" == "" ]]; then
			echo "--as user not specified" >&2
			display_usage >&2
			return 1
		fi

		asuser=$2
	elif [[ "$1" != "" ]]; then
		echo "Invalid argument: $1" >&2
		display_usage
		return 1
	fi

	userinfo=`userinfo $asuser`
	otherhome=`echo "$userinfo" | grep ^dir | sed s/^dir//`
	authfile=$otherhome/.Xauthority

	touch $authfile
	xauth -f $authfile generate $DISPLAY . trusted
	chgrp $asuser $authfile
	chmod g+r $authfile

	cd $otherhome
	exec doas -u $asuser $command
}

setup() {
	if [[ "$1" == "" ]]; then
		echo "Command not specified" >&2
		display_usage >&2
		return 1
	fi

	command=`which -- $1`
	basename=`basename $command`

	shift

	while [[ "$1" != "" ]]; do
		if [[ "$1" == "--as" ]]; then
			if [[ "$2" == "" ]]; then
				echo "--as user not specified" >&2
				display_usage >&2
				return 1
			elif [[ "$asuser" != "" ]]; then
				echo "--as user specified twice" >&2
				display_usage >&2
				return 1
			fi

			asuser=$2
			shift
			shift
		elif [[ "$1" == "--for" ]]; then
			if [[ "$2" == "" ]]; then
				echo "--for user not specified" >&2
				display_usage >&2
				return 1
			elif [[ "$foruser" != "" ]]; then
				echo "--for user specified twice" >&2
				display_usage >&2
				return 1
			fi

			foruser=$2
			shift
			shift
		else
			echo "Invalid argument: $1" >&2
			display_usage
			return 1
		fi
	done

	asuser=${asuser-$USER-$basename}
	foruser=${foruser-$USER}

	echo "Setup $command as $asuser for $foruser" >&2
	echo "Not implemented yet" >&2
	return 1
}

display_usage() {
	echo "usage: xodo <command> [--as <user>]"
	echo "       xodo --setup <command> [--as <user>] [--for <user>]"
	echo "       xodo --help"
}

main $@
