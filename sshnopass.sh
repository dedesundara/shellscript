#!/bin/sh

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
    by: dede sundara | bogorwebhost.com /_/     
           ssh no password tool
EOF
echo -e "${PLAIN}"

dirssh=~/.ssh
configfile=$dirssh/config
knownfile=$dirssh/known_hosts

if [ ! -f $configfile ]; then 
    touch $configfile
fi

removeknownhost(){
  printf "${GREEN}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  printf "Remove Known Host SSH\n"
  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"

  printf "${GREEN}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  read -p "Enter host: " host
  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"

  cat $knownfile | grep -in "$host" | awk -F" " '{print $1}' | while IFS= read listknownhost;
  # cat $knownfile | grep -in "$host" | while IFS= read listknownhost;
  do
  if [ ! -z "$listknownhost" ]
  then
  printf "${RED}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  printf "${RED}Line number ${BLUE}$listknownhost ${PLAIN}\n"
  printf "${RED}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  fi
  done

  read -p "Enter line number: " linenumber
  printf "${RED}%-14s${PLAIN}\n" "#----------------------------------------------------------#"
  removedlinehost=$(sed -ne ${linenumber}p $knownfile | awk -F" " '{print $1}')
  printf "${GREEN}Removed known_hosts ${BLUE}$removedlinehost ${PLAIN}\n"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "${linenumber}d" $knownfile
  else
    sed -i "${linenumber}d" $knownfile
  fi

  space
  exit
}

removeconfig(){
  printf "${GREEN}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  printf "Remove Config SSH\n"
  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"

  printf "${GREEN}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  read -p "Enter hostname: " targethostname
  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"

  if [ -f $dirssh/id_rsa_$targethostname ]; then 
    printf "${RED}File exist & removed ${BLUE}$dirssh/id_rsa_$targethostname ${PLAIN}\n"

    if [ -f $dirssh/id_rsa_$targethostname ]; then 
    rm "$dirssh/id_rsa_$targethostname"
    fi
    if [ -f $dirssh/id_rsa_$targethostname.pub ]; then 
        rm "$dirssh/id_rsa_$targethostname.pub"
    fi
    else
    printf "${RED}File not exist ${BLUE}$dirssh/id_rsa_$targethostname ${PLAIN}\n"
  fi

  arrayrm=()
  for rmconfig in $(cat -n $configfile | grep -A 5 "####### ${targethostname} #######" | awk -F" " '{print $1}')
  do
    arrayrm+=($rmconfig)
  done

  if [ ! -z "$rmconfig" ]
  then
  printf "${RED}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  printf "${GREEN}Removed config ${BLUE}$targethostname ${PLAIN}\n"
  printf "${RED}%-14s${YELLOW}\n" "#----------------------------------------------------------#"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' -e "${arrayrm[0]},${arrayrm[5]}d" $configfile
  else
    sed -i -e "${arrayrm[0]},${arrayrm[5]}d" $configfile
  fi

  fi

  space
  exit
}


enterdata() {
  printf "${GREEN}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  read -p "Enter name: " name
  checkfile

  read -p "Enter host: " host
  hostcheck=$(ping -c1 $host)
  if test -z "$hostcheck" 
  then printf "${RED}No connection to url ${BLUE}$host ${PLAIN}\n"
  exit
  enterdata
  fi

  read -p "Enter port: " port
  read -p "Enter user: " user
  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"
  space
}

checkfile(){
  if [ -f $dirssh/id_rsa_$name ]; then 
    printf "${RED}File exist ${BLUE}$dirssh/id_rsa_$name ${PLAIN}\n"
    read -p "Remove? [y = yes / no = n]: " exist
    
    if [ $exist == "y" ]
    then 
      if [ -f $dirssh/id_rsa_$name ]; then 
      rm "$dirssh/id_rsa_$name"
      fi
      if [ -f $dirssh/id_rsa_$name.pub ]; then 
          rm "$dirssh/id_rsa_$name.pub"
      fi

    checkconfig

    else [ $exist == "n" ] then
    enterdata
    fi

  fi
}

checkconfig(){
  arrayrm=()
  for rmconfig in $(cat -n $configfile | grep -A 5 "####### ${name} #######" | awk -F" " '{print $1}')
  do
    arrayrm+=($rmconfig)
  done

  if [ ! -z "$rmconfig" ]
  then
  printf "${RED}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  printf "${GREEN}Removed config ${BLUE}$name ${PLAIN}\n"
  printf "${RED}%-14s${YELLOW}\n" "#----------------------------------------------------------#"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' -e "${arrayrm[0]},${arrayrm[5]}d" $configfile
  else
    sed -i -e "${arrayrm[0]},${arrayrm[5]}d" $configfile
  fi

  fi
}

createkeygen() {
  printf "${GREEN}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
  ssh-keygen -t rsa -N '' -f $dirssh/id_rsa_$name <<< y
  printf "${GREEN}%-14s${YELLOW}\n" "#----------------------------------------------------------#"
#   echo "ssh-copy-id -i $dirssh/id_rsa_$name.pub $user@$host -p $port"
  echo "ssh-copy-id -p $port -i $dirssh/id_rsa_$name.pub $user@$host"

  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"

#   ssh-copy-id -i $dirssh/id_rsa_$name.pub $user@$host -p $port
  ssh-copy-id -p $port -i $dirssh/id_rsa_$name.pub $user@$host 


  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"
  space
}

createconfig(){
  echo "####### $name #######" >> $configfile
  echo "Host           $name" >> $configfile
  echo "HostName       $host" >> $configfile
  echo "Port           $port" >> $configfile
  echo "User           $user" >> $configfile
  echo "IdentityFile   ~/.ssh/id_rsa_$name" >> $configfile
  echo "" >> $configfile
}

readyconnect(){
  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"
  printf "${YELLOW}%-14s${PLAIN}\n" "Command          : ssh $name"
  printf "${GREEN}%-14s${PLAIN}\n" "#----------------------------------------------------------#"
}

if [ "$1" == "rmknownhost" ]; then
removeknownhost
fi

if [ "$1" == "rmconfig" ]; then
removeconfig
fi

enterdata
createkeygen
createconfig
readyconnect