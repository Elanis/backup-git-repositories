#!/usr/bin/env bash
set -euo pipefail

# ==================================
# Load Configuration
# ==================================
DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$DIR/backup.cfg"

cd "$DIR"

# Download jq if not existing, not using apt as it's going to run on my TrueNAS scale server
if ! command -v jq &> /dev/null; then
	PATH="$PATH:$DIR"

	if ! command -v jq &> /dev/null; then
		wget "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -O jq
	fi
fi

for user in "${USERS_TO_BACKUP[@]}"; do
	userDirectory="$BACKUP_DESTINATION/$user"
	if [[ ! -d "$userDirectory/" ]]; then
		mkdir -p "$userDirectory";
	fi

	curl -s -u "$USER_PAT" "https://api.github.com/users/$user/repos" | jq -r '.[].clone_url' | while read repo; do
		repoDirectory=$(basename "$repo")
		relativeDirectory="$userDirectory/$repoDirectory"

		if [[ -d "$relativeDirectory" ]]; then
			echo "Updating $repoDirectory ..."

			cd "$relativeDirectory"
			git remote update

			echo "Done !"
		else
			echo "Cloning $repoDirectory ..."

			cd "$userDirectory"
			git clone --mirror "$repo" "$repoDirectory"

			echo "Done !"
		fi

		cd "$DIR"
	done
done