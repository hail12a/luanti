#!/usr/bin/env bash
#
# AkititoCraft dedicated server bootstrapper for Ubuntu / Debian.
#
# What it does (in one command):
#   1. Installs the build dependencies (first run only).
#   2. Fetches the AkititoCraft files from GitHub (clone, or pull if updating).
#   3. Builds the server (akititocraftserver) if the code changed.
#   4. Creates the world on first run.
#   5. Runs the server.
#
# It AUTO-UPDATES on every launch: it pulls the latest code and rebuilds only
# when there are changes, so restarting the server updates it.
#
# Usage:
#   ./akititocraft-server.sh                 # update + build if needed + run
#   ./akititocraft-server.sh --no-update     # skip the git pull, just run
#   ./akititocraft-server.sh --install-service   # install a systemd service
#                                                # (auto-start + auto-restart)
#
# Configuration (override with environment variables):
#   AKITITO_REPO    git URL to fetch from
#   AKITITO_BRANCH  branch to track
#   AKITITO_DIR     where to install (default: ~/akititocraft-server)
#   AKITITO_WORLD   world name (default: world1)
#   AKITITO_PORT    UDP port (default: 30000)
#
set -euo pipefail

REPO="${AKITITO_REPO:-https://github.com/hail12a/luanti.git}"
BRANCH="${AKITITO_BRANCH:-claude/akititocraft-launcher-lodh7k}"
DIR="${AKITITO_DIR:-$HOME/akititocraft-server}"
WORLD="${AKITITO_WORLD:-world1}"
PORT="${AKITITO_PORT:-30000}"
GAMEID="mineclonia"
JOBS="$(nproc 2>/dev/null || echo 2)"

log() { printf '\033[0;32m[akititocraft]\033[0m %s\n' "$*"; }
err() { printf '\033[0;31m[akititocraft] ERROR:\033[0m %s\n' "$*" >&2; }

install_deps() {
	# Only run the (slow) apt install once; leave a marker afterwards.
	local marker="$DIR/.deps-installed"
	[ -f "$marker" ] && return 0
	log "Installing build dependencies (first run only, needs sudo)..."
	sudo apt-get update
	sudo apt-get install -y --no-install-recommends \
		git build-essential cmake \
		libsqlite3-dev libcurl4-gnutls-dev libluajit-5.1-dev libjsoncpp-dev \
		libgmp-dev libzstd-dev zlib1g-dev libssl-dev gettext libncursesw5-dev
	mkdir -p "$DIR"
	touch "$marker"
}

fetch() {
	if [ -d "$DIR/.git" ]; then
		if [ "${1:-}" = "--no-update" ]; then
			log "Skipping update (--no-update)."
			return 0
		fi
		log "Checking for updates on branch '$BRANCH'..."
		git -C "$DIR" fetch --depth 1 origin "$BRANCH"
		local local_sha remote_sha
		local_sha="$(git -C "$DIR" rev-parse HEAD)"
		remote_sha="$(git -C "$DIR" rev-parse "origin/$BRANCH")"
		if [ "$local_sha" = "$remote_sha" ]; then
			log "Already up to date."
			NEEDS_BUILD=0
		else
			log "Update found; pulling..."
			git -C "$DIR" reset --hard "origin/$BRANCH"
			NEEDS_BUILD=1
		fi
	else
		log "Fetching AkititoCraft into $DIR ..."
		git clone --depth 1 --branch "$BRANCH" "$REPO" "$DIR"
		NEEDS_BUILD=1
	fi
}

build() {
	# Rebuild if the code changed or the binary is missing.
	if [ "${NEEDS_BUILD:-1}" = "0" ] && [ -x "$DIR/bin/akititocraftserver" ]; then
		log "Server binary is current; skipping build."
		return 0
	fi
	log "Building the server (this can take several minutes the first time)..."
	cmake -S "$DIR" -B "$DIR/build" \
		-DCMAKE_BUILD_TYPE=Release \
		-DRUN_IN_PLACE=TRUE \
		-DBUILD_SERVER=TRUE -DBUILD_CLIENT=FALSE \
		-DBUILD_UNITTESTS=FALSE \
		-DINSTALL_MINECLONIA=TRUE
	cmake --build "$DIR/build" -j"$JOBS"
	log "Build complete: $DIR/bin/akititocraftserver"
}

run() {
	local worldpath="$DIR/worlds/$WORLD"
	mkdir -p "$worldpath"
	log "Starting server on UDP port $PORT (game: $GAMEID, world: $WORLD)"
	log "Players connect with the machine's public IP and port $PORT."
	log "Remember: open the port ->  sudo ufw allow ${PORT}/udp"
	cd "$DIR"
	exec "$DIR/bin/akititocraftserver" \
		--gameid "$GAMEID" \
		--world "$worldpath" \
		--port "$PORT"
}

install_service() {
	# Create a systemd service that runs this script (so it auto-updates on
	# every (re)start) and restarts automatically if it ever crashes.
	local script_path unit
	script_path="$(readlink -f "$0")"
	unit="/etc/systemd/system/akititocraft.service"
	log "Installing systemd service at $unit (needs sudo)..."
	sudo tee "$unit" >/dev/null <<UNIT
[Unit]
Description=AkititoCraft dedicated server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=$script_path
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
	sudo systemctl daemon-reload
	sudo systemctl enable --now akititocraft.service
	log "Service installed. Manage it with:"
	log "  sudo systemctl status akititocraft     # see status/logs"
	log "  sudo systemctl restart akititocraft    # restart (auto-updates)"
	log "  journalctl -u akititocraft -f          # live logs"
}

main() {
	case "${1:-}" in
		--install-service)
			install_deps
			fetch
			build
			install_service
			;;
		--no-update)
			build
			run
			;;
		*)
			install_deps
			fetch
			build
			run
			;;
	esac
}

main "$@"
