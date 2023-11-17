#!/bin/bash
clear

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

space() {
    printf "%-70s\n"
}

echo -e "${GREEN}"
cat << "EOF" 
             __         ____               _       __ 
       _____/ /_  ___  / / /______________(_)___  / /_
      / ___/ __ \/ _ \/ / / ___/ ___/ ___/ / __ \/ __/
     (__  ) / / /  __/ / (__  ) /__/ /  / / /_/ / /_  
    /____/_/ /_/\___/_/_/____/\___/_/  /_/ .___/\__/  
                     by: dede sundara /_/     
           FLUTTER VERSION SWITCHER
EOF
echo -e "${PLAIN}"

# HOW TO
# prepare flutter folder list with prefix "flutter_${version} on same directory"
# for last version stored on file "flutter_sdk_version.txt" with version string example "3.10.6"
# on .zshrc add "export PATH="$PATH:$HOME/development/sdk/flutter/bin""

# CHANGE SDK PATH
rootdir=~/development
dirsdk=$rootdir/sdk
dirversion=$dirsdk/flutter_sdk_version.txt
if [ ! -f $dirversion ]; then 
    touch $dirversion
fi
_version=$(awk '{print $1}' "$dirversion")
current_version=${_version#"flutter_"}

enterdata() {
    folders=$(find $dirsdk -maxdepth 1 -type d -name 'flutter_*')
    versions=()
    while IFS= read -r line; do
        version_check=$(basename "$line" | cut -d'_' -f2)
        versions+=("$version_check")
    done <<< "$folders"

    available_version=$(printf "%s | " "${versions[@]}" | sed 's/ | $//')

    printf "${GREEN}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
    printf "Current version: %s\n" "$current_version"
    printf "Available version: %s\n" "$available_version"

    read -p "Enter target version: " target_version
    dirtarget=flutter_$target_version
    if [[ -d "$dirsdk/$dirtarget" ]]; then
        if [[ -d "$dirsdk/flutter" ]]; then
            mv "$dirsdk/flutter" "$dirsdk/flutter_$current_version"
        fi
        mv "$dirsdk/$dirtarget" "$dirsdk/flutter"

        space
        flutter --version
        space

        echo "$target_version" > $dirversion

        printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"
        printf "${YELLOW}%-14s${PLAIN}\n" "Switch flutter success      : $target_version"
        printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"
    else
        printf "${RED}Version folder not found ${BLUE}$dirtarget ${PLAIN}\n"
        enterdata
    fi

}
enterdata
