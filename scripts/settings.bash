
if [ $SETTINGS_BASH_INCLUDED ]; then return; fi;
SETTINGS_BASH_INCLUDED=true

# always fail the script upon encountering command failure
set -o errexit
set -o errtrace

# Comment/uncomment these flags for less/more verbose output
#	and for worse/better debugging capabilities
#
# VERBOSE="--verbose"
# set -o xtrace
# set -o monitor
# set -o notify
# set -o verbose

TEMP_DIR="temp"

