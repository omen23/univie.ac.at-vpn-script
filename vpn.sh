#!/usr/bin/env bash
# (C) 2016 by David Schuster
# for bash users of univie.ac.at to install and or run a vpn tunnel to university
# makes everything easier for everyone
# GPL applies - atleast please mention me if you use parts of this script (=


# ------------------
#        MAIN       
# ------------------
main()
{
trap 'echo; echo "Caught signal..."; echo "Exiting..."; exit 130' SIGTSTP SIGINT SIGTERM SIGHUP
echo "University of Vienna VPN client Installations- und Verbindungsskript"
echo "(C) 2016 by David Schuster"
echo
if [[ $(type -ap f5fpc) != "/usr/local/bin/f5fpc" ]] ; then # we know this path from the installer
  do_install  
else
  connection_manager
fi
}
# ------------------
#    END OF  MAIN       
# ------------------

# ------------------
#     FUNCTIONS
# ------------------

# ------------------
#     F5 PROMPT             
# ------------------
f5prompt()
{
trap 'echo; echo "Disconnected successfully"; echo; echo; f5fpc -o &> /dev/null; exit 130' SIGTSTP SIGINT SIGTERM SIGHUP
echo "f5fpc> Du bist jetzt im f5fpc prompt, 'info' zeigt dir Statistiken des VPN Tunnels"
echo "f5fpc> und 'disconnect' trennt die VPN Verbindung."
while :
do
  echo -n "f5fpc> "
  read answer
  if [ "info" == "$answer" ] ; then
    f5fpc -i
    if [[ $? -ne 5 ]] ; then
    echo "f5fpc> Du bist nicht verbunden - irgendetwas ist schief gegangen."
    exit 1
    fi
  elif [ "disconnect" == "$answer" ] ; then
    f5fpc -o
    exit 0
  else
    echo "f5fpc> Please type 'info' or 'disconnect'!"  
  fi
done
}

# ------------------
#    YESNOPROMPT              
# ------------------
readYes()
{
while read -r -n 1 -s answer; do
  if [[ $answer = [JjNn] ]]; then
    [[ $answer = [Jj] ]] && retval=0
    [[ $answer = [Nn] ]] && retval=1
    break
  fi
done
echo # just a final linefeed, optics...
return $retval
}

# ------------------
#  CLEANUP/TRAPFUNC                
# ------------------
clean_up()
{
cd ~/Desktop/
rm -rf ./VPN_Install/ &> /dev/null
if [[ $1 -eq 1 ]] ; then
  echo
  echo "Caught signal - cleaning up and exiting!"
  exit 130
elif [[ $1 -eq 127 ]] ; then
  echo "utility missing - cleaning up and exiting."
  exit 127
else
  echo "Installation und cleanup fertig!"
  sleep 3
fi
}

# ------------------
# CONNECTION MANAGER
# ------------------
connection_manager()
{
echo "F5Networks Client bereit... connecte mit deiner u:account UserID"
read -p "Bitte gib deine Matrikel-Nummer mit einem 'a' davor ein, gefolgt von [ENTER]: "
f5fpc -s -t vpn.univie.ac.at:8443 -u "$REPLY" -d /etc/ssl/certs/
echo "f5fpc> Wir warten ein paar Sekunden ..."
sleep 9
f5fpc -i &> /dev/null
if [[ $? -eq 5 ]] # strange return code but it's F5Networks :P
  then # you're connected
  f5prompt
else # we got a problem
  echo "f5fpc> Du bist nicht verbunden - irgendetwas ist schief gegangen."
  exit 1
fi # end connection check
}

# ------------------
#     INSTALLER
# ------------------
do_install()
{
trap 'clean_up 1' SIGTSTP SIGINT SIGTERM SIGHUP
echo "F5 Client wird jetzt installiert..."
cd ~/Desktop/ # we want to stay in user-space
mkdir VPN_Install && cd VPN_Install
if type wget &> /dev/null
  then
  wget -q https://vpn.univie.ac.at/public/share/BIGIPLinuxClient.tgz
else
  echo "wget utility muss installiert sein!"
  clean_up 127
fi # wget check
if type tar &> /dev/null
  then
  tar -xf BIGIPLinuxClient.tgz 
else
  echo "tar utility muss installiert sein!"
  clean_up 127
fi # tar check
echo
sleep 1
echo "Antworte zweimal mit 'yes' während der Installation."
sleep 1
sudo ./Install.sh # sorry xD but this is a service script
echo -n "Mozilla Firefox Browser Plugin installieren? (J/N)? "
if readYes
  then # you get the right browser plugin
  echo "Installiere Firefox Browser Plugin..."
  if [[ $(arch) == "x86_64" ]]
    then # we have a 64-bit platform
    cd ~/Desktop/VPN_Install/
    sudo cp \{972ce4c6-7e08-4474-a285-3208198ce6fd\}/plugins/np_F5_SSL_VPN_x86_64.so /usr/lib/mozilla/plugins/ #properly escaped
  elif [[ $(arch) =~ i.86 ]]  # we check for an i.86 platform
    then # we have a i.86 compatible platform
    cd ~/Desktop/VPN_Install/
    sudo cp \{972ce4c6-7e08-4474-a285-3208198ce6fd\}/plugins/np_F5_SSL_VPN_i386.so /usr/lib/mozilla/plugins/ # :D
  else
    echo "no working architecture found - skipping browser plugin installation."
  fi # end of x86_64/i.86 if
fi # end of plugin installer
clean_up
trap 'echo; echo "Caught signal..."; echo "Exiting..."; exit 130' SIGTSTP SIGINT SIGTERM SIGHUP
echo -n "Gleich verbinden? (J/N)? "
if readYes
  then
  connection_manager
else
  echo "Exiting..."
  exit 0
fi
}
# ------------------
#  END OF FUNCTIONS
# ------------------

# ------------------
#    CALL TO MAIN               
# ------------------
main "$@"
# ------------------
#        EOF            
# ------------------
