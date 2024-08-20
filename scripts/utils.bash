#!/usr/bin/env bash

if [ $UTILS_BASH_INCLUDED ]; then return; fi;
UTILS_BASH_INCLUDED=true


function log () {
	local message="$1";
	printf "(viralc) $message";
}

function log_verbose () {
	local message="$1";
	if [ $VERBOSE ]; then
		log "$message";
	fi;
}

function change_dir() {
	local dest="$1";
	cd $dest
	log_verbose "CWD: '$(pwd)'\n"
}

function nuke_path() {
	local path="$1"
	# WARN: if deletion failed, whole script should fail
	false \
		|| unlink $path && log_verbose "unlinked '$path'\n" \
		|| rm $VERBOSE $path --force \
		|| rm $VERBOSE $path --force --recursive \
		;
}

function ensure_top_dir() {
	script_path=$(readlink $VERBOSE --canonicalize "$0");
	script_dir=$(dirname "$script_path");
	top_dir=$(dirname "$script_dir");
	change_dir "$top_dir";
}

