#!/bin/sh
# source: https://www.domoticz.com/forum/viewtopic.php?t=18637
# modified by Dede Sundara from bogorwebhost.com

##########################################################
##           __         ____               _       __   ##
##     _____/ /_  ___  / / /______________(_)___  / /_  ##
##    / ___/ __ \/ _ \/ / / ___/ ___/ ___/ / __ \/ __/  ##
##   (__  ) / / /  __/ / (__  ) /__/ /  / / /_/ / /_    ##
##  /____/_/ /_/\___/_/_/____/\___/_/  /_/ .___/\__/    ##
##  by: dede sundara | bogorwebhost.com /_/             ##
##                                                      ##
##########################################################

clear
if [ ! -f speedtest-cli ]; then
echo && echo "Downloading speedtest-cli..." && echo
wget -q -O speedtest-cli https://raw.githubusercontent.com/dedesundara/shellscript/master/speedtest-cli
chmod +x speedtest-cli
clear
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

next() {
    printf "%-88s\n" "-" | sed 's/\s/-/g'
}

echo -e "${GREEN}"
cat << "EOF" 
             __         ____               _       __ 
       _____/ /_  ___  / / /______________(_)___  / /_
      / ___/ __ \/ _ \/ / / ___/ ___/ ___/ / __ \/ __/
     (__  ) / / /  __/ / (__  ) /__/ /  / / /_/ / /_  
    /____/_/ /_/\___/_/_/____/\___/_/  /_/ .___/\__/  
    by: dede sundara | bogorwebhost.com /_/     

            speedtest benchmark server tool
EOF
echo -e "${PLAIN}"
next

while true; do

read -p "Please enter keyword server:" keywordserver
read -p "Please enter number of test:" numberoftest

serverlist=$(python speedtest-cli --list | awk "/$keywordserver/"' {print}' | tail -n +2)
filter=$(echo "$serverlist" | cut -d' ' -f2- | awk '{print $1}' | sed 's/[^0-9]*//g')

randomserver=$(echo "$filter" | sort -bus | sed '/^$/d')
random=$(echo "$randomserver" | sort -Rbus | head -n "$numberoftest")

next
printf "%-16s%-15s%-14s%-14s%-18s%-14s\n" "Download" "Upload" "Ping" "Distance" "IP Address" "Server Name"

echo "$random" | while read -r line; do
test=$(python speedtest-cli --server "$line")
dl=$(echo "$test" | grep 'Download:' | awk '{print $2}')
up=$(echo "$test" | grep 'Upload:' | awk '{print $2}')
cekdns=$(echo "$test" | grep 'From:' | awk -F ":" '{print $2}')
cekip=$(dig +short ${cekdns})

if [ "$dl" > "0" ]; then
dlunit=$(echo "$test" | grep 'Download:' | awk '{print $3}')
if [ "$up" > "0" ]; then
upunit=$(echo "$test" | grep 'Upload:' | awk '{print $3}')
if [[ "$dlunit" == "Mbit/s" ]]; then
if [[ "$upunit" == "Mbit/s" ]]; then
servername0=$(echo "$serverlist" | grep -w "$line" | awk '{$1= ""; print $0}' | cut -d' ' -f2-)

servername=${servername0%%[*}
cekping=$(echo "$test" | grep 'Hosted' | awk -F "km]: " '{print $2}')
cekjarak=$(echo "$test" | grep 'Hosted' | sed 's/.*)//' | sed 's/]:.*//' | sed 's/^..//')
download=$(echo "$dl" "$dlunit")
upload=$(echo "$up" "$upunit")

printf "${GREEN}%-16s${RED}%-15s${YELLOW}%-14s${BLUE}%-14s${RED}%-18s${RED}%-14s${PLAIN}\n" "${download}" "${upload}" "${cekping}" "${cekjarak}" "${cekip}" "${servername}"

fi
fi
fi
fi
done

next
done