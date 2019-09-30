#!/usr/bin/env bash
#
# Description: Auto test download & I/O speed script
#
# Copyright (C) 2015 - 2019 Teddysun <i@teddysun.com>
#
# Thanks: LookBack <admin@dwhd.org>
#
# URL: https://teddysun.com/444.html
# source: https://github.com/teddysun/across

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

if  [ ! -e '/usr/bin/wget' ]; then
    echo "Error: wget command not found. You must be install wget command at first."
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

io_test() {
    (LANG=C dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

speed_test_v4() {
    local servertarget=$(printf $1 | sed -r 's/.{1}//' | sed -r 's/.{1}$//')
    local servername=$(echo ${line#$1} | sed -r 's/.{1}//' | sed -r 's/.{1}$//')
    local output=$(LANG=C wget -4O /dev/null -T300 $servertarget 2>&1)
    local speedtest=$(printf '%s' "$output" | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
    local cekspeed=$(printf '%s' "$output" | awk '/\/dev\/null/ {speed=$4} END {gsub(/\(|\)/,"",speed); print speed}')
    local ipaddress=$(printf '%s' "$output" | awk -F'|' '/Connecting to .*\|([^\|]+)\|/ {print $2}')
    local ping=$(printf '%s' "$output" | ping -qc1 ${ipaddress} 2>&1 | awk -F/ '/^rtt/ { printf "%.2fms\n", $5;}')
    if [ "$cekspeed" = "MB/s" ]
    then
    local speedmbps=$(printf '%s' "$output" | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed*8}')
    else
    local speedmbps=$(printf '%s' "$output" | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed/125}')
    fi
    local nodeName=$2
    printf "${YELLOW}%-18s${GREEN}%-10s${GREEN}%-14s${GREEN}%-14s${RED}%-14s${PLAIN}\n" "${ipaddress}" "${speedtest}" "${speedmbps}Mbps" "${ping}" "${servername}"
}


cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
freq=$( awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo )
tram=$( free -m | awk '/Mem/ {print $2}' )
uram=$( free -m | awk '/Mem/ {print $3}' )
swap=$( free -m | awk '/Swap/ {print $2}' )
uswap=$( free -m | awk '/Swap/ {print $3}' )
up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
opsy=$( get_opsy )
arch=$( uname -m )
lbit=$( getconf LONG_BIT )
kern=$( uname -r )
disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker' | awk '{print $2}' ))
disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker' | awk '{print $3}' ))
disk_total_size=$( calc_disk "${disk_size1[@]}" )
disk_used_size=$( calc_disk "${disk_size2[@]}" )

clear
echo -e "${GREEN}"
cat << "EOF" 
             __         ____               _       __ 
       _____/ /_  ___  / / /______________(_)___  / /_
      / ___/ __ \/ _ \/ / / ___/ ___/ ___/ / __ \/ __/
     (__  ) / / /  __/ / (__  ) /__/ /  / / /_/ / /_  
    /____/_/ /_/\___/_/_/____/\___/_/  /_/ .___/\__/  
    by: dede sundara | bogorwebhost.com /_/   

             benchmark linux server tool
EOF
echo -e "${PLAIN}"
next
echo -e "CPU model            : ${BLUE}$cname${PLAIN}"
echo -e "Number of cores      : ${BLUE}$cores${PLAIN}"
echo -e "CPU frequency        : ${BLUE}$freq MHz${PLAIN}"
echo -e "Total size of Disk   : ${BLUE}$disk_total_size GB ($disk_used_size GB Used)${PLAIN}"
echo -e "Total amount of Mem  : ${BLUE}$tram MB ($uram MB Used)${PLAIN}"
echo -e "Total amount of Swap : ${BLUE}$swap MB ($uswap MB Used)${PLAIN}"
echo -e "System uptime        : ${BLUE}$up${PLAIN}"
echo -e "Load average         : ${BLUE}$load${PLAIN}"
echo -e "OS                   : ${BLUE}$opsy${PLAIN}"
echo -e "Arch                 : ${BLUE}$arch ($lbit Bit)${PLAIN}"
echo -e "Kernel               : ${BLUE}$kern${PLAIN}"
next
io1=$( io_test )
echo -e "I/O speed(1st run)   : ${YELLOW}$io1${PLAIN}"
io2=$( io_test )
echo -e "I/O speed(2nd run)   : ${YELLOW}$io2${PLAIN}"
io3=$( io_test )
echo -e "I/O speed(3rd run)   : ${YELLOW}$io3${PLAIN}"
ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
echo -e "Average I/O speed    : ${YELLOW}$ioavg MB/s${PLAIN}"
next

list_server=list-server.txt
list2=target-server.txt
list3=target-server2.txt

if [ ! -f "$list_server" ];
then
#----------------------------------------------------------#
# Linode
#----------------------------------------------------------#
echo "'http://speedtest.newark.linode.com/100MB-newark.bin' 'Linode, Newark, US East'" >> $list_server
echo "'http://speedtest.atlanta.linode.com/100MB-atlanta.bin' 'Linode, Atlanta, US Southeast'" >> $list_server
echo "'http://speedtest.dallas.linode.com/100MB-dallas.bin' 'Linode, Dallas, US Central'" >> $list_server
echo "'http://speedtest.fremont.linode.com/100MB-fremont.bin' 'Linode, Fremont, US West'" >> $list_server
echo "'http://speedtest.toronto1.linode.com/100MB-toronto.bin' 'Linode, Toronto, CA Central'" >> $list_server
echo "'http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin' 'Linode, Frankfurt, EU Central'" >> $list_server
echo "'http://speedtest.london.linode.com/100MB-london.bin' 'Linode, London, EU West'" >> $list_server
echo "'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode, Singapore, AP South'" >> $list_server
echo "'http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin' 'Linode, Tokyo, AP Northeast'" >> $list_server
echo "'http://speedtest.mumbai1.linode.com/100MB-mumbai.bin' 'Linode, Mumbai, AP West'" >> $list_server
#----------------------------------------------------------#
# Digitalocean
#----------------------------------------------------------#
echo "'http://speedtest-nyc1.digitalocean.com/100mb.test' 'Digitalocean, Newyork, NYC'" >> $list_server
echo "'http://speedtest-ams2.digitalocean.com/100mb.test' 'Digitalocean, Amsterdam, AMS'" >> $list_server
echo "'http://speedtest-sfo1.digitalocean.com/100mb.test' 'Digitalocean, Sanfrancisco, SFO'" >> $list_server
echo "'http://speedtest-sgp1.digitalocean.com/100mb.test' 'Digitalocean, Singapore, SGP'" >> $list_server
echo "'http://speedtest-lon1.digitalocean.com/100mb.test' 'Digitalocean, London, LON'" >> $list_server
echo "'http://speedtest-fra1.digitalocean.com/100mb.test' 'Digitalocean, Frankfurt, FRA'" >> $list_server
echo "'http://speedtest-tor1.digitalocean.com/100mb.test' 'Digitalocean, Toronto, TOR'" >> $list_server
echo "'http://speedtest-blr1.digitalocean.com/100mb.test' 'Digitalocean, Bangalore, BLR'" >> $list_server
#----------------------------------------------------------#
# Vultr
#----------------------------------------------------------#
echo "'http://ga-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Atlanta, North America'" >> $list_server
echo "'http://il-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Chicago, North America'" >> $list_server
echo "'http://tx-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Dallas, North America'" >> $list_server
echo "'http://lax-ca-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Losangeles, North America'" >> $list_server
echo "'http://fl-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Miami, North America'" >> $list_server
echo "'http://nj-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Newjersey, North America'" >> $list_server
echo "'http://wa-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Seattle, North America'" >> $list_server
echo "'http://sjo-ca-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Siliconvalley, North America'" >> $list_server
echo "'http://tor-ca-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Toronto, North America'" >> $list_server
echo "'http://ams-nl-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Amsterdam, Europe'" >> $list_server
echo "'http://fra-de-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Frankfurt, Europe'" >> $list_server
echo "'http://lon-gb-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, London, Europe'" >> $list_server
echo "'http://par-fr-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Paris, Europe'" >> $list_server
echo "'http://sgp-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Singapore, Asia'" >> $list_server
echo "'http://hnd-jp-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Tokyo, Asia'" >> $list_server
echo "'http://syd-au-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Sydney, Australia'" >> $list_server
#----------------------------------------------------------#
# OVH
#----------------------------------------------------------#
echo "'http://sbg.proof.ovh.net/files/100Mb.dat' 'OVH, France'" >> $list_server
echo "'http://gra.proof.ovh.net/files/100Mb.dat' 'OVH, France'" >> $list_server
echo "'http://rbx.proof.ovh.net/files/100Mb.dat' 'OVH, France'" >> $list_server
echo "'http://bhs.proof.ovh.net/files/100Mb.dat' 'OVH, Canada'" >> $list_server
#----------------------------------------------------------#
# Hetzner OVH
#----------------------------------------------------------#
echo "'https://speed.hetzner.de/100MB.bin' 'Hetzner, Germany'" >> $list_server

else
    sed -i 's/\r$//' $list_server
fi


if [ -f "$list2" ];
then
   rm $list2
fi

if [ -f "$list3" ];
then
   rm $list3
fi

read -p "Please enter keyword server:" keywordserver
read -p "Please enter number of test:" numberoftest
next
printf "%-18s%-10s%-14s%-14s%-14s\n" "IPv4 address" "Download" "Speed" "Ping" "Node Name"

while IFS= read -r line
do
  satu=$(echo "$line" | grep "$keywordserver")

echo $satu >> target-server.txt
sed -i '/^$/d' target-server.txt

done < "$list_server"

cat $list2 | head -n "$numberoftest" >> $list3

cat $list3 | while read -r line; do

speed_test_v4 $line

done

next

if [ -f "$list_server" ];
then
   rm $list_server
fi

if [ -f "$list2" ];
then
   rm $list2
fi

if [ -f "$list3" ];
then
   rm $list3
fi