#!/bin/bash

#Colors
green="\e[0;32m\033[1m"
red="\e[0;31m\033[1m"
fincolor="\033[0m\e[0m"

function ctrl_c(){
    echo -e "\n ${red}[*] Exiting the program \n${fincolor}"
    rm ports.tmp
    exit 1
}

# Control+C
trap ctrl_c INT

# Checking arguments
    if ! [ $(id -u) = 0 ]; then 
	echo -e "\n ${red}[*] You must use sudo or be root \n${fincolor}"
	exit 1 
    fi
    if [ $# -eq 1 ]; then
    	if [[ "$1" =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
        	echo -e "\n ${green}[*] Initial port reconnaissance \n${fincolor}"
            	ip=$1
            	nmap -p- -sS --min-rate 5000 --open -Pn -v -n $ip -oG ports.tmp
    	else
            	echo -e "\n ${red}[*] Enter a correct IPv4 \n${fincolor}" 
	           	exit 1
        fi
    elif [ $# -eq 0 ]; then
	ip a | grep "tun0" &>/dev/null && echo -e "\n ${red}[*] You are under a VPN, Enter a correct IPv4 \n${fincolor}" && exit 1
	ip=$(sudo arp-scan -l | grep "PCS" | cut -f1 | tail -n1)
	if [[ $ip = "" ]]; then
		echo -e "\n ${red}[*] No IP of the victim machine has been detected ${fincolor}\n"
		exit 1
	fi
	echo -e "\n ${green}[*] The IP of the victim machine is $ip${fincolor}\n"
	nmap -p- -sS --min-rate 5000 --open -Pn -vvv -n $ip -oG ports.tmp
    else
        echo -e "\n ${red}[*] Enter only the IP to scan${fincolor}\n"
        exit 1
    fi

# Escaneo de puertos
    ports="$(cat ports.tmp | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    	if [[ $ports = "" ]]; then
		echo -e "\n ${red}[*] No open port detected on the victim machine \n${fincolor}"
		rm ports.tmp
		exit 1
		fi
    echo -e "\n ${green}[*] Advanced service scanning\n${fincolor}" 
    nmap -sCV -p$ports $ip -oN InfoPuertos
    sed -i '1,3d' InfoPuertos
    echo -e "\n \t[*] IP adress: $ip" >> InfoPuertos
    echo -e "\t[*] Open ports: $ports\n" >> InfoPuertos
    rm ports.tmp
    echo -e "\n ${green}[*] Scan completed, file has been generated InfoPuertos \n${fincolor}" 
    echo $ip | xclip -sel clip 