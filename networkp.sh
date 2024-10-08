#/bin/bash

#Installations and Anonymity Check

	#Ensuring system is updated to the latest
	echo 'Ensuring system is updated to the latest version by executing "sudo apt-get update"'
	echo "$(tput blink)Please wait, patience is a virtue$(tput sgr0)"  #Blinking was intentionally put into the script to indicate that the machine is not frozen (As nmaps might take time)
	sudo apt-get update	 #Ensures that packages in system are up to date									
		 #Check if geoiplookup is installed
function checkgeoiplookup() #creates function geoiplookup
{
				if [ $(command -v geoiplookup) == -z ]		#if geoiplookup is in the commands database, output will not be empty. If the command is not present, there will be no output. '== -z' means is empty. i.e. no command -> install, command found -> next step
				then
					echo "geoiplookup is required but it's not installed. Installing geoiplookup now."	#String to inform user installing geoiplookup
					sudo apt-get install geoiplookup #installs geoiploopup
				else
					echo "geoiplookup application is installed"	#string informing user geoiplookup already installed
			fi
		
}		
checkgeoiplookup	#Calls out geoiplookup function

function checksshpass()	#creates function checksshpass
{	
			if [ $(command -v sshpass) == -z ]		#if sshpass is in the commands database, output will not be empty. If the command is not present, there will be no output. '== -z' means is empty. i.e. no command -> install, command found -> next step
				then
					echo "sshpass is required but it's not installed. Installing sshpass now."	#String to inform user installing geoiplookup
					sudo apt-get install sshpass #installs sshpass
				else
					echo "sshpass application is installed"	#string informing user sshpass already installed
			fi
}	
checksshpass #Calls out checksshpass function

function checknipe() #creates function checknipe and checks anonymous status
{
		# Locating nipe.pl and its relevant files
			if [ $(locate nipe.pl) == -z ] #locates for nipe.pl files. If nil found, to install nipe and relevant codes
				then	#if nipe.pl files not found, to install relevant files
					echo "Unable to locate nipe.pl. Installing nipe.pl now"			#String informing of Installing nipe.pl and its relevant files
					git clone https://github.com/htrgouvea/nipe && cd nipe  		#Creates a nipe folder and clones files into the nipe folder and cds into it
					sudo apt-get install cpanminus									#installs cpanminus
					cpanm --installdeps .											#installs cpanminus codes/applications
					sudo cpan install Switch JSON LWP::UserAgent Config::Simple		#installs cpanminus codes/applications
					sudo perl nipe.pl install										#installs nipe
			
				else	#nipe.pl is installed, will check if network is anonymous
					echo "nipe.pl is installed, checking if network is anonymous"
					nipelocation=$(locate nipe.pl | head -n1)					#Obtains the nipe location e.g. /home/kali/nipe/nipe.pl, and stores it as the location of the nipe.pl
					nipefolder=$(echo $nipelocation | sed 's/\/nipe.pl//g')		#Use nipelocation to get the path of the nipe.pl folder
					cd $nipefolder												#Changes Directory into the nipe.pl folder 
					sudo perl nipe.pl start										#Starting nipe.pl										
					sudo perl nipe.pl status
					nipetrue=$(sudo perl nipe.pl status | grep Status | awk '{print $3}')			#variable for grepping for the word "true"
						if [ $nipetrue == 'true' ]										#If managed to grep for word 'true'
							then
								anonIP=$(sudo perl nipe.pl status | grep Ip | awk '{print $3}')						#creating variable for anonymous IP address
								echo "$anonIP is the anonymous IP address"			#String message indicating the anonymous IP address
								anonIPcountry=$(geoiplookup $anonIP | head -n1 | awk '{print $5,$6,$7}')						#creating variable for anonIPcountry, awk to show only 5th and 6th column. In an event of two name countries like united states, added more columns
								echo "$anonIPcountry is the spoofed country name"	#string informing the user the spoofed country name
							else
								echo "You are not anonymous! Please ensure anonymousness Exiting now!" #string informs user of exiting as not annonymous
								exit
						fi
			fi
			
}
checknipe #Calls out checknipe function

#obtains the url to be scanned, remote user and password an remote host ip

	echo 'Please specify the URL/address to scan from the remote server'
	read url										#read user input to save as a variable $url
	echo "Please specify the ip of the remote host"	#string asking for ip of remote host
	read remoteip									#reads user input as a variable $remoteip
	echo "Please specify the user of the remote host" #string asking for user of the remote host
	read remoteuser									#reads user input as variable $remoteuser
	echo "Please type the password of the user in the previous question"	#string asking user for password of the remote user
	read remotepass									#reads user input as variable $remotepass
	sleep 1											#spaces out information to prevent user information overload


#Connect to the remote server
	echo "Now attempting to connect to the remote server"		
	sshpass -p "$remotepass" ssh "$remoteuser@$remoteip" echo "Connected to server!"						#attempts to connect to server using sshpass,

#Obtaining and giving details of the given address/url
	echo "Here are the details of the remote server"	#string informeing user of remote server details that are about to be given
	sleep 1
	remoteipcountry=$(sudo geoiplookup $remoteip | head -n1 | awk '{print $5,$6,$7}')	#obtains the remote country ip and saves it as a variable $remoteipcountry
	echo "The country of the remote server is $remoteipcountry" #information stirng
	sleep 1
	echo "The IP of the remote server is $remoteip"				#information string
	timeup=$(sudo uptime | awk '{print $1}')					#creates variable of the uptime as $timeup
	timeupusers=$(sudo uptime | awk '{print $(NF-6)}')			#creates variable of the number of users on the server as $timeupusers
	echo "This server has been up for $timeup"		#information string
	echo "                            HH:MM:SS"		#for showing what the above numbers represent in terms of time
	sleep 1
	echo "There are $timeupusers user(s) currently logged in to this server" #information string showing number of users in the server
	sleep 1													#rest for information overload

#Changing permissions of /var and /var/log folder so that we can put the saved scanned in to the var log file
	sshpass -p "$remotepass" ssh "$remoteuser@$remoteip" "sudo -S chmod 777 /var /var/log"					#uses sshpass to change permissions of the /var/log folder of remote server
	sleep 1

#Create a scan log folder to document everthing that was scanned
	sshpass -p "$remotepass" ssh "$remoteuser"@"$remoteip" 'sudo -S touch /var/log/scanned.log && sudo -S chmod 777 /var/log/scanned.log'

#WHOIS scanning and saving into /var/log
	echo "Now checking the whois data of the given URL/Address, saving scanned whois data to /var/log as scanWHOIS.txt"	#information string
	sshpass -p "$remotepass" ssh "$remoteuser@$remoteip" "sudo -S whois $url > /var/log/scanWHOIS.txt " #uses sshpass to do whois from the remote server
	whoisTIME=$(date +"%H:%M:%S") 	#creates Variable for time of whois scan
	whoisDATE=$(date +"%Y-%m-%d")	#creates Variable for date of whois scan
	whoisDAY=$(date +"%A")	#creates Variable for day of whois scan
	sshpass -p "$remotepass" ssh "$remoteuser@$remoteip" "echo "A whois scan was completed on $whoisDAY, $whoisDATE at $whoisTIME on $url" >> /var/log/scanned.log" #echos information regarding date time and day regarding scan into the scanned.log file
	sleep 1

#NMAP scanning and saving into /var/log
	echo "Now checking the nmap data of the given URL/Address, saving scanned whois data to /var/log as scanNMAP.txt"	#information string
	sshpass -p "$remotepass" ssh "$remoteuser@$remoteip" "sudo -S nmap -O $url > /var/log/scanNMAP.txt $url" #uses sshpass to do nmap from the remote server
	nmapTIME=$(date +"%H:%M:%S") 	#creates Variable for time of nmap scan
	nmapDATE=$(date +"%Y-%m-%d")	#creates Variable for date of nmap scan
	nmapDAY=$(date +"%A")	#creates Variable for day of nmap scan
	sshpass -p "$remotepass" ssh "$remoteuser@$remoteip" "echo "An nmap scan was completed on $nmapDAY, $nmapDATE at $nmapTIME on $url" >> /var/log/scanned.log" #echos information regarding date time and day regarding scan into the scanned.log file
	sleep 1



#Obtaining file via ftp
		# Connect to FTP server and download scanNMAP.txt and scanWHOIS.txt
		ftp -n $remoteip <<EOF
		quote USER $remoteuser
		quote PASS $remotepass
		cd /var/log
		lcd ~
		get scanNMAP.txt
		get scanWHOIS.txt
		quit
EOF

echo "Scan Complete"








