
if [ $SYNC_BASH_INCLUDED ]; then return; fi;
SYNC_BASH_INCLUDED=true
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/settings.bash";
source "$SCRIPT_DIR/utils.bash";

log "WARNING: YOU'RE ABOUT TO DO LOTS OF ST00P1D SH1T!\n";
sudo --remove-timestamp
sudo printf ""

# BUG: I had a bug with following link: misc/neofetch_config.conf	~/.config/neofetch/config.conf
#     ^ this one might be already fixed
log "Ensuring that symlinks to configuration files exist...\n";
log "WARNING: This overwrites any existing files at symlinks' destinations!\n";
ensure_top_dir;
SYMLINKS=($(cat "./scripts/symlinks.txt"));
SYMLINKS_NUM=${#SYMLINKS[@]};
for ((i=0; i < $SYMLINKS_NUM; i+=2)); do
	src="${PWD}/${SYMLINKS[i]}";
	dest="$(eval echo "${SYMLINKS[i+1]}")";
	dest_dirname="$(dirname $dest)";
	num=$((i/2+1));
	log_verbose "Checking symlink $num: '$src -> $dest'\n";
	if [ "$(readlink $VERBOSE $dest_dirname )" = "$src" ]; then
		log_verbose "Symlink $num already exists\n";
		continue;
	fi;
	nuke_path $dest
	mkdir $VERBOSE --parents $dest_dirname;
	ln $VERBOSE --symbolic $src $dest;
	log_verbose "Symlink $num created\n";
done;


log "Ensuring that Pacman mirrors are up to date...\n";
MIRRORLIST_PATH="/etc/pacman.d/mirrorlist"
# allow mirrors to be 3 days old
DELAY_ALLOWED=$((60*60*24*3))
# FIXME: this should always be true, if not we should crash or throw error
if [ -f "$MIRRORLIST_PATH" ]; then
	date_lastm=$(date -r $MIRRORLIST_PATH +%s)
	date_current=$(date +%s)
	date_delta=$((date_current - date_lastm))
	if [ "$(($date_delta / $DELAY_ALLOWED))" == 0 ]; then
		b_mirrors_valid=true;
	fi;
fi;
if [ "$b_mirrors_valid" == true ]; then
	log_verbose "Pacman mirrors are up to date\n"
else
	log_verbose "Pacman mirrors are NOT up to date and will be refreshed with Reflector!\n"
	log "Ensuring that Reflector exists...\n";
	if [ $(which reflector) ]; then
		log_verbose "Reflector already exists\n";
	else
		log "Reflector does NOT exist. Bootstraping Reflector with Pacman.\n";
		sudo pacman "reflector" \
			$VERBOSE \
			--sync \
			--refresh \
			--noconfirm \
			--needed \
			;
	fi;
	log "Refreshing Pacman mirrors with Reflector...\n"
	sudo reflector \
		$VERBOSE \
		--country=Poland,Germany \
		--age 24 \
		--fastest 10 \
		--latest 30 \
		--sort rate \
		--save $MIRRORLIST_PATH \
		;
fi;


log "Ensuring that YAY is bootstraped...\n";
if [ $(which yay) ]; then
	log_verbose "YAY is already bootstraped.\n";
else
	log_verbose "Bootstraping YAY...\n";
	ensure_top_dir;
	mkdir $VERBOSE --parents $TEMP_DIR;
	change_dir $TEMP_DIR;
	nuke_path yay
	git clone "https://aur.archlinux.org/yay.git";
	change_dir yay;
	makepkg \
		--syncdeps \
		--install \
		--force \
		--check \
		--noconfirm \
		--needed \
	;
	log_verbose "Bootstraping YAY done\n";
	ensure_top_dir;
fi;
log_verbose "$(yay --version)\n";


log "Ensuring that packages are up to date via YAY...\n";
log "WARNING: AUR packages often break and need manual adjustments!\n";
PACKAGES_PACMAN=$(cat "./scripts/packages_pacman.txt");
PACKAGES_YAY=$(cat "./scripts/packages_yay.txt");
yay ${PACKAGES_PACMAN[@]} ${PACKAGES_YAY[@]}\
	--sync \
	--refresh \
	--refresh \
	--sysupgrade \
	--noconfirm \
	--needed \
	;


log "Ensuring that Neovim plugins and packages are up to date...\n";
if [ $VERBOSE ]; then NVIM_VERBOSE=-V1; fi;
nvim $NVIM_VERBOSE --headless +"qa!";
nvim $NVIM_VERBOSE --headless +"Lazy update" +"MasonUpdate" +"TSUpdateSync" +"qa!";
# HACK: +"TSUpdateSync" does not putchar the newline, so we try to workaround this with "echo"
echo ""


if [ $DISPLAY ]; then
	log "Sourcing ~/.xprofile\n";
	source ~/.xprofile
else
	log "Xorg server is not running. \"~/.xprofile\" will not be sourced.\n";
fi;

# WARN: INJECTION!
lxterm_desk="/usr/share/applications/lxterminal.desktop"
if ! grep -q 'NoDisplay' "$lxterm_desk"; then
	log "Shadowing desktop entry: '$lxterm_desk'...\n"
	sudo bash -c "echo 'NoDisplay=true' >> $lxterm_desk"
else
	log "Desktop entry already shadowed: '$lxterm_desk'\n"
fi;
sudo update-desktop-database

# systemd-related setup
if command -v systemctl &> /dev/null; then

	# FIXME: I think that systemd-network is only used in default arch
	# and there might be more network-related services that should be disabled/stopped
	# https://wiki.archlinux.org/title/NetworkManager
	log "Ensuring systemd-networkd is disabled...\n"
	strs=(
		systemd-networkd.service
		systemd-network-generator.service
		systemd-networkd-persistent-storage.service
		systemd-networkd.socket
	)
	for i in "${strs[@]}"; do
		sudo systemctl is-enabled "$i" --quiet && sudo systemctl disable "$i" --quiet || true
		sudo systemctl is-active "$i" --quiet && sudo systemctl stop "$i" --quiet || true
	done

	log "Ensuring NetworkManager and bluetooth services are enabled...\n"
	strs=(
		systemd-resolved.service
		NetworkManager.service
		bluetooth.service
	)
	for i in "${strs[@]}"; do
		sudo systemctl is-enabled "$i" --quiet || sudo systemctl enable "$i" --quiet
		sudo systemctl is-active "$i" --quiet || sudo systemctl start "$i" --quiet
	done

else
	log "systemctl not found! skipping related setup!\n"
fi;

if command -v modprobe &> /dev/null; then
	# FIXME: there should be probalby
	log "Ensuring Linux kernel modules are loaded...\n"
	strs=(
		btusb
	)
	for i in "${strs[@]}"; do
		sudo modprobe "$i"
	done
else
	log "modprobe not found! skipping related setup!\n"
fi;

log "Full resync finished!\n";

