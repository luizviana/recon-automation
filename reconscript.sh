#!/bin/bash
#By Luiz Viana   github.com/luizviana

if [ $# -gt 2 ]; then 
	echo "Usage: ./reconscript.sh <domain> <out of scope domains file>"
	echo "Example: ./reconscript.sh google.com out-of-scope.txt"
	exit 1
fi

if [ ! -d "thirdlevels" ]; then 
	mkdir thirdlevels
fi

if [ ! -d "scans" ]; then
       mkdir scans	
fi

if [ ! -d "eyewitness" ]; then
       mkdir eyewitness	
fi

pwd=$(pwd)

echo "Subdomain Gathering - Sublist3r"
sublist3r -d $1 -o subdomainsout.txt

echo $1 >> subdomainsout.txt

if [ $# -eq 2 ];
then
	echo "Out of scope Domains Exclusion"
	grep -vFf $2 subdomainsout.txt > subdomains.txt
	rm subdomainsout.txt
else
	mv subdomainsout.txt subdomains.txt
fi

echo "Third-level domains"
cat subdomains.txt | grep -Po "(\w+\.\w+\.\w+)$" | sort -u >> third-level.txt

echo "Third-level domains Gathering - Sublist3r"
for domain in $(cat third-level.txt); do sublist3r -d $domain -o thirdlevels/$domain.txt; test -f thirdlevels/$domain.txt && cat thirdlevels/$domain.txt | sort -u >> subdomains.txt; done

echo "Probing for alive third-levels"
cat subdomains.txt | sort -u | httprobe | sed 's/https\?:\/\///' | tr -d ":443" > probed.txt

echo "Port Scanning - Nmap"
nmap -iL probed.txt -oA scans/scanned.txt

echo "Scanning - Eyewitness"
eyewitness -f $pwd/probed.txt -d $1 --all-protocols
mv /usr/share/eyewitness/$1 eyewitness/$1
