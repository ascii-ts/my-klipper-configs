#!/bin/sh
#set -x #debug aktivieren
# Script um beim Shutdown von OctoPi auch den Drucker (incl. Octopi) abzuschalten
# Da ein RaspberryPi sich ja nicht selbst ausschalten kann macht das hier
# eine Steckdose mit Tasmota
# Benutzung:
# /home/pi/shutdown_steckdose_off.sh 90
# Schaltet die Steckdose mit 90 Sekunden verzögerung ab.
 
# IP der Tasmota Steckdose
ip=192.168.15.31
off=$1

#Octorprint access
ipocto=127.0.0.1
apikey=B847BD6381114376A2EE56E4922F2E60 
 
#Verwendeter 1. RuleTimer
timer=1
#Verwendete 2. RULE (Regel)
rulenum=2
 
#Rule Power OFF erste Steckdose falls es mehrer gibt.
rule="ON Rules#Timer=$timer DO Power1 off ENDON"

# aktuelle Temeratur des HotEnds
#curtemp=`wget -q -O - http://$ipocto/api/printer/tool?apikey=$apikey | cut -d : -f3 | cut -d . -f1`
curtemp=`wget -q -O - http://127.0.0.1:7125/api/printer | jq .temperature.tool0.actual | cut -d . -f1` 
if [ -n "$off" ]
then
  # Erstmal prüfen ob die notwendige Rule schon existiert und OK ist
  result=`wget -q -O - http://$ip/cm?cmnd=rule$rulenum | sed 's/.*"Rules":"//' | sed 's/".*//'`
  # Wenn nicht passt dann wird die rule neu erstellt/überschrieben.
  if [ "$rule" != "$result" ]
  then
    setrule=`echo $rule | sed 's/ /%20/g' | sed 's/#/%23/g'`
    result=`wget -q -O - http://$ip/cm?cmnd=rule$rulenum%20$setrule`
    result=`wget -q -O - http://$ip/cm?cmnd=rule$rulenum%20ON`
  fi
  while [ $curtemp -ge 50 ]
  do
	sleep 10
	echo "current temp $curtemp"
	curtemp=`wget -q -O - http://127.0.0.1:7125/api/printer | jq .temperature.tool0.actual | cut -d . -f1` 
  done
  if [ $off -gt 0 ]
  then
    #Timer setzen - nach Ablauf der Zeit schaltet die Steckdose aus.
    wget -q -O /dev/null http://$ip/cm?cmnd=Backlog%20ruletimer$timer%20$off 
#echo "shutdown tasmota in bla"
  else
    #Direkt ausschalten - weniger tolle Idee...
  #  wget -q -O /dev/null http://$ip/cm?cmnd=Backlog%20ruletimer180%20$off
  echo "shutdown in default of 180 "
  fi
fi
 
echo "OctopPi Shutdown"
sleep 1
/usr/bin/sudo /sbin/shutdown -h +1
exit 0
