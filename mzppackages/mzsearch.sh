#!/bin/bash
#######################################################
#      search packages Mazon OS - version 0.0.1       #
#                                                     #
#      @utor: Diego Sarzi <diegosarzi@gmail.com>      #
#      created: 2019/02/20          licence: MIT      #
#######################################################

source /lib/lsb/init-functions

if [ "$(id -u)" != "0" ]; then
	echo "Please run root."
	exit
fi

VARLIB="/var/lib/mzsearch"

helpMe(){
	echo -e "usage: mzsearch [-u] [--update] or <package> \n \
------ LIST OPTIONS ------- \n \
-u, --update     Update list packages in repositore online. Need Internet.\n \
ex: mzsearch nano # for search."
	exit
}

if [[ $1 = "" ]] || [ $1 = "-h" ] || [ $1 = "--help" ]; then
	helpMe
fi

# update
#########################
## check folder /var/lib/search-mazon exist
if [ $1 = "-u" ] || [ $1 = "--update" ]; then
	if [ -e "$VARLIB" ]; then
		cd $VARLIB
	else
		mkdir $VARLIB
		cd $VARLIB
	fi
	## Clean folder
	#echo "Clean /var/lib/mzsearch/"
        log_info_msg "Clean /var/lib/search-mazon/"
	rm -f *
	evaluate_retval

	## Updating FOLDER from website mazonos.com
	log_info_msg "Updating Folders..."
	wget -c -q http://mazonos.com/packages
	evaluate_retval
	echo "Updating Packages..."
	# capture folders
	###########################
	folders=$(cat $VARLIB/packages | grep href | sed 's/      <a href="//g' | cut -d/ -f1 | more +2)
	cleanFolders=$(echo $folders | sed 's/<pre>?C=N;O=D">Name< //g')

	## Updating PACKAGES from website mazonos.com
	# capture files
	##########################
	for i in $cleanFolders; do
		declare -g ii=$i
		log_info_msg "Updating... "
		printf $i
		wget -c -q "http://mazonos.com/packages/$i"
		evaluate_retval
		package=$(cat "$VARLIB/$i" | grep href | sed 's/      <a href="//g' | cut -d/ -f1 | sed 's/">.*<//g' | grep -v sha256 | more +2)
		cleanPackages=$(echo $package | sed 's/<pre>?C=N;O=D//g')

		## Generate list in /var/search-mazon/list
		for p in $cleanPackages; do
			echo "$ii/$p" >> list
		done
	done

	echo "All packages updated! Use: # mzsearch <package> for searching."

	exit
fi

# search
#########################
## Search in list package used in command.
pkg=$(grep $1 $VARLIB/list)
pkgInstall=$(echo $pkg | cut -d"/" -f2)
declare -g pkgNumber=0

# Check package exist.
if [[ $pkg != "" ]]; then
	echo "--------------- RESULT ----------------"
	## Show results
	for i in $pkg; do
		echo -e "\e[5m\e[42m\e[30m-FOUND-\e[0m $i"
		echo "---------------------------------------"
		pkgCheckNumber=$(($pkgCheckNumber+1))
	done
	
	echo "found $pkgCheckNumber files."

	## Check number packages.
	if [ $pkgCheckNumber = '1' ]; then
		for i in $pkg; do
			declare -g ee=$i
			echo ""

			## Download package.
			read -p "Download? [Y/n]" download
			echo ""
			if [[ $download = "" ]] || [ $download = "Y" ] || [ $download = "y" ]; then
				cd /tmp/
				wget "http://mazonos.com/packages/$i"
				echo ""

				# Install Package.
				read -p "Install $ee ? [Y/n]" install
				if [[ $install = "" ]] || [ $install = 'y' ] || [ $install = 'Y' ]; then
					banana -i $pkgInstall
					echo ""
				fi
			fi
		done
	else
		echo "Choose one package for download or install."
	fi
else
	echo "No packages found!"
fi

# return folder
#########################
cd - >/dev/null 2>&1
