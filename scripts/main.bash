#!/usr/bin/env bash

if [ $MAIN_BASH_INCLUDED ]; then return; fi;
MAIN_BASH_INCLUDED=true
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/bash-bear";
source "$SCRIPT_DIR/settings.bash";
source "$SCRIPT_DIR/sync.bash";

