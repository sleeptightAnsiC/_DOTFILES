
PATH="/opt/msvc/bin/x86:$PATH"
PATH="/home/korn/.local/bin:$PATH"


export SHELL="$(which bash)"
export HOSTNAME="$(uname -n)"
export EDITOR="$(which nvim)"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export ROOTPATH="$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT="1"


####  WARN: INTERACIVE CODE STARTS HERE
[[ $- != *i* ]] && return
set -o vi
source /usr/share/blesh/ble.sh --noattach


alias lynx="lynx -vikeys"
alias ucli="python $HOME/ue4cli";
alias ush="$HOME/UnrealEngine/Engine/Extras/ushell/ushell.sh";
alias vi="nvim --clean"
alias clone="git clone --single-branch --depth 1 --recursive --recurse-submodules --shallow-submodules";
alias als="ls -l --color=auto --almost-all --human-readable --group-directories-first --dereference --indicator-style=slash --hide-control-chars";
alias viralc="$HOME/dotfiles/scripts/main.bash"
alias lg="lazygit"


function fioa()
{
	script_path="/opt/intel/oneapi/setvars.sh"
	source $script_path $@
	echo "Reminder: the main compiler is invoked with 'icx'"
	echo
}


####  WARN: INTERACIVE CODE ENDS HERE
# (this must be at the end of the .bashrc)
[[ ${BLE_VERSION-} ]] && ble-attach

