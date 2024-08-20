
# https://unix.stackexchange.com/a/94492

# If .bash_profile exists, bash doesn't read .profile
if [[ -f ~/.profile ]]; then
	source ~/.profile
fi

# If the shell is interactive and .bashrc exists, get the aliases and functions
if [[ $- == *i* && -f ~/.bashrc ]]; then
	source ~/.bashrc
fi
