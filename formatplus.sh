#!/bin/bash

#--------------------------------------------------#
# Script_Name: formatplus.sh	                               
#                                                   
# Author:  'dossantosjdf@gmail.com'                 
# Date: dim. 23 mai 2021 16:00:50                                             
# Version: 1.0                                      
# Bash_Version: 5.0.17(1)-release                                     
#--------------------------------------------------#
# Description:
#  Ce script permet de formater des disques USB en FAT 32.
#
#  Ce script peut fonctionner de deux manières :
#  1- En mode interactif (c'est le mode par défaut).
#  2- En mode non interactif (avec l'option -d <sdX>)
#  
#  Le script doit être lancé en tant que ROOT !                                                 
#                                                   
# Options:                                          
#     -h    : Aide.
#     -v    : Affiche la version du script.
#     -l    : Ajoute le formatage long du disque.
#  -d <sdX> : Permet de passer en argument le nom du disque exemple : sda, sdb...
#
# Usage: ./formatplus.sh -[l|h|v] -d <sdX>                                            
#                                                   
# Limits:                                           
#                                                   
# Licence:                                          
#--------------------------------------------------#

set -eu

### Includes ###

### Fonctions ###
usage() {
  cat << EOF
  
  ___ Script : $(basename ${0}) ___
  
  Paramètres passés : ${@}
  
  $(basename ${0}) -[l|h|v] -d <sdX>
  
  Ce script peut fonctionner de deux manières :
  1- En mode interactif (c'est le mode par défaut).
  2- En mode non interactif (avec l'option -d <sdX>)
  
  Le script doit être lancé en tant que ROOT !
  
  Rôle:                                          
  Ce script permet de formater des disques USB en FAT 32.

  Usage: ./$(basename ${0}) -[l|h|v] -d <sdX>
     -h    : Aide.
     -v    : Affiche la version du script.
     -l    : Ajoute le formatage long du disque.
  -d <sdX> : Permet de passer en argument le nom du disque exemple : sda, sdb...
EOF
}

version() {
  local ver='1'
  local dat='25/05/2021'
  cat << EOF
  
  ___ Script : $(basename ${0}) ___
  
  Version : ${ver}
  Date : ${dat}
EOF
}

fin()
{
  cat << "EOF"

   _____ _             _         ____            _       _
  |  ___(_)_ __     __| |_   _  / ___|  ___ _ __(_)_ __ | |_
  | |_  | | '_ \   / _` | | | | \___ \ / __| '__| | '_ \| __|
  |  _| | | | | | | (_| | |_| |  ___) | (__| |  | | |_) | |_
  |_|   |_|_| |_|  \__,_|\__,_| |____/ \___|_|  |_| .__/ \__|
                                                  |_|
EOF
}

user_is()
{
  if [[ $UID -ne 0 ]]
  then
    mesg_info "w" "Ce script doit être lancé en tant que root !"
    usage
    exit 1
  fi
}

mesg_info()
{
  mesg_progress="${2}"
  type_info="${1}" # w for warning and i for info

  #Colors
  RED="\033[0;31m"
  GREEN="\033[0;32m"
  NC="\033[0m" # Stop Color

  if [[ ${1} == 'w' ]]
  then
    echo -e "\n${RED}>>> ${2} ...${NC}"
  elif [[ ${1} == 'i' ]]
  then
    echo -e "\n${GREEN}>>> ${2} ...${NC}"
  else
    echo -e "\n>>> ${2} ..."
  fi
  echo
}
### CONSTANT
interactive="true"
format_long="false"

### Main ###
trap fin EXIT

#Banner
clear
cat  << "EOF"
 _____                          _               _     
|  ___|__  _ __ _ __ ___   __ _| |_   _   _ ___| |__  
| |_ / _ \| '__| '_ ` _ \ / _` | __| | | | / __| '_ \ 
|  _| (_) | |  | | | | | | (_| | |_  | |_| \__ \ |_) |
|_|  \___/|_|  |_| |_| |_|\__,_|\__|  \__,_|___/_.__/ 
                                                      
EOF

user_is

# GetOps
while getopts "lhvd:" arguments
do
  case "${arguments}" in
    h)
      usage
      exit 1
      ;;
    v)
      version
      exit 1
      ;;
    l)
      readonly format_long='true'
      ;;
    d)
      readonly disk="${OPTARG}"
      readonly interactive="false"
      ;;
   \?)
      usage
      exit 1    
      ;;
  esac
done

if [[ $interactive == "true" ]]
then
  mesg_info "i" "Merci de brancher la clé USB !"
  read -p '---> Taper sur entrée pour valider'
  echo

  clear

  menu='true'
  until [ $menu == 'false' ]
  do
    #Choix du disque USB
    lsblk -ld -I 8 -o NAME,TYPE,SIZE,MODEL

    PS3="Votre choix : "
    all_disks=($(lsblk -ldn -I 8 -o NAME))

    mesg_info "i" "Menu disque"
    select ITEM in "${all_disks[@]}" 'Relancer' 'Quitter'
    do
      if [[ $ITEM == 'Quitter' ]]
      then
        exit 1
      elif [[ "$ITEM" == 'Relancer' ]]
      then
        clear
        break
      else
        disk=${ITEM}
        menu='false'
        break
      fi
    done
  done
fi

#Regex
regex="^[s][d][a-z]$"

if [[ ! ${disk} =~ ${regex} ]]
then
  mesg_info "w" "Erreur de saisie !"
  usage
  exit 1
elif ! (dmesg | grep ${disk} > /dev/null)
then
  mesg_info "w" "Le disque ${disk} n'est pas connecté au système !"
  usage
  exit 1
elif (grep ${disk} /etc/fstab > /dev/null)
then
  mesg_info "w" "Attention le disque ${disk} est utilisé par le système !"
  exit 1
fi

if (mount | grep ${disk} > /dev/null)
then
  set +e
  mesg_info "i" "Démontage des partitions montées sur le disque USB /dev/${disk} !"
  umount /dev/${disk}* > /dev/null 2>&1 & 
  wait $!
  set -e
  
  if ! (mount | grep ${disk} > /dev/null)
  then
    echo -e "Démontage OK ! \n"
  else
    mesg_info "w" "Erreur du démontage des partitions sur le disque USB /dev/${disk} !"
    exit 1
  fi
fi

#data for remove disque
data_disk="$(lsblk -ldn -I 8 -o SIZE,MODEL /dev/sdb)"
  
if [[ $format_long == 'true' ]]
then
  if [[ $interactive == "true" ]]
  then
    mesg_info "i" "Effacement complet du disque /dev/${disk} de $data_disk ? (long)"
    read -p '---> Taper sur entrée pour valider (Ctrl+c pour quitter)'
    echo
  fi
  
  size_device=$(blockdev --getsize64 /dev/${disk}) # en octets
  size_block=$(stat -c "%o" /dev/${disk}) # en octets
  count_value=$((size_device / size_block))
  
  dd if=/dev/zero of=/dev/${disk} bs=$size_block count=$count_value status=progress conv=noerror,sync  
else
  if [[ $interactive == "true" ]]
  then
    mesg_info "i" "Effacement des métadonnées du disque /dev/${disk} de $data_disk ?"
    read -p '---> Taper sur entrée pour valider (Ctrl+c pour quitter)'
    echo
  fi
  
  dd if=/dev/zero of=/dev/${disk} bs=1M count=100 conv=noerror,sync &
  #too much speed for use status=progress
  pid_dd="$!"
  while (ps -q $pid_dd -o state --no-headers)
  do
    echo "Effacement en cours (PID: $pid_dd) !" 
    kill -USR1 $pid_dd
    sleep 1
  done
fi

#Create partition
mesg_info "i" "Création de la partition ${disk}1"
echo 'type=b' | sfdisk /dev/${disk} &
wait $!

#Format partition
mesg_info "i" "Formatage de la partition ${disk}1 en FAT32"
mkfs.fat -I -F 32 /dev/${disk}1 &
wait $!

#inform the operating system of partition table changes
partprobe

#Make USB label
mesg_info "i" "Création d'un nom de label pour la clé USB !"
label_usb="USB_${RANDOM}"
mlabel -i /dev/${disk}1 -s ::"$label_usb" > /dev/null && echo "USB renommée en $label_usb !"

echo
for i in {1..5}
do
  echo -en "-- Merci de patienter ${i}/5 secondes --\r"
  sleep 1
done
echo

eject /dev/${disk} && echo -e "\nDisque USB $label_usb éjecté !"

mesg_info "i" "Vous pouvez retirer la clé USB en toute sécurité !"
