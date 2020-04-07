#!/bin/bash
ANSWER="./.asf"
_wifi_adapter=$(ip address show | grep -Ei "^[0-9]" | awk '{print $2}' | sed 's/://g'  | grep -Evi "lo" | grep -Ei "w")
_wifi_adptr=( $_wifi_adapter )
_intrfc=""
_interface_mn=""
_intr_once=0
_backtitle="This FrameWork to WiFi conection"
_wf_type=""
_wep_keypass=0
_my_ssid=""
mypass=""
function slct_intrfc()
{
	if [[ $_intr_once -eq 0 ]]; then
		_intr_once=1
		for i in ${_wifi_adptr[*]}; do
			_interface_mn="${_interface_mn} $i -"
		done
	fi
	dialog --backtitle "$_backtitle" --title "Select interface" --menu "\nPlease to select WiFi interface\n" 0 0 3 ${_interface_mn} 2>${ANSWER}
	_intrfc=$(cat ${ANSWER})
	wait
	ip link set ${_intrfc[*]} up
	wait
}
function type_wifi_connect()
{
	dialog --default-item 1 --backtitle "$_backtitle" --title "Selecting WiFi connection encryption" \
    --menu "\nPlease select wireless encryption (WEP or WPA)\n" 0 0 3 \
 	"1" "WPA" \
 	"2" "WEP" \
	"3" "Back" 2>${ANSWER}	

    case $(cat ${ANSWER}) in
        "1") _wf_type="wpa"
             ;;
        "2") _wf_type="wep"
			wep_keyorpass
             ;;
          *) wifimenu
             ;;
     esac
}
function wep_keyorpass()
{
	dialog --default-item 2 --backtitle "$_backtitle" --title "Configuration mode WEP connection" \
    --menu "\nPlease to select mode WEP connection\n" 0 0 2 \
 	"1" "Key authentication mode" \
 	"2" "Password authorization mode" \
	"3" "Back" 2>${ANSWER}	

    case $(cat ${ANSWER}) in
        "1") _wep_keypass=0
             ;;
        "2") _wep_keypass=1
             ;;
          *) type_wifi_connect
             ;;
     esac
	wifimenu
}
function search_wifi_ssid()
{
	_srch_ssid=$(iw dev wlan0 scan | grep -Ei "ssid" | sed 's/^[ \t]*//' | sed 's/SSID: //g')
	_ssid_mn=""
	for j in ${_srch_ssid[*]}; do
		_ssid_mn="${_ssid_mn} $j -"
	done
	dialog --backtitle "$_backtitle" --title "Selecting a wireless network" --menu "\nPlease select your wireless network\n" 0 0 16 ${_ssid_mn} 2>${ANSWER}
	variables=$(cat ${ANSWER})
	_my_ssid=""
	_my_ssid="${variables[*]}"
	unset variables
	dialog --backtitle "$_backtitle" --title "Input the Password" --inputbox "\nPlease enter the password (key) for your WiFi network\n" 0 0 "" 2>${ANSWER}
	mypass=$(cat ${ANSWER})
}
function connect_wifi_network()
{
	if [[ $_wf_type == "wpa" ]]; then
		wpa_passphrase "$_my_ssid" "${mypass[*]}" > /root/example.conf
		wait
		wpa_supplicant -B -i "${_intrfc[*]}" -c /root/example.conf
		wait
	else
		if [[ $_wep_keypass -eq 0 ]]; then
			iw dev "${_intrfc[*]}" connect "$_my_ssid" key 0:${mypass[*]}
			wait
		else
			iw dev "${_intrfc[*]}" connect "$_my_ssid" key d:2:${mypass[*]}
			wait
		fi
	fi
	wait
	clear
	wait
	sleep 3
	wait
	dhcpcd ${_intrfc[*]}
	wait
	sleep 3
	wait
	ping -c 3 ya.ru
	wait
	sleep 3
	wait
}
function wifimenu()
{
	if [[ $SUB_MENU != "wifimenu" ]]; then
	   SUB_MENU="wifimenu"
	   HIGHLIGHT_SUB=1
	else
	   if [[ $HIGHLIGHT_SUB != 5 ]]; then
	      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
	   fi
	fi
	
	dialog --default-item ${HIGHLIGHT_SUB} --backtitle "$_backtitle" --title "WiFi configuration network" \
    --menu "\nPlease select the appropriate menu to set up a wireless Internet connection\n" 0 0 5 \
 	"1" "Select an interface" \
 	"2" "Selecting wireless connection encryption (WEP/WPA)" \
 	"3" "Find a network and enter your password" \
 	"4" "DHCPCD" \
	"5" "Exit" 2>${ANSWER}	

	HIGHLIGHT_SUB=$(cat ${ANSWER})
    case $(cat ${ANSWER}) in
        "1") slct_intrfc
             ;;
        "2") type_wifi_connect
             ;;
        "3") search_wifi_ssid
		;;
	"4") connect_wifi_network
		;;
          *) rm -rf $ANSWER
			clear
			exit 0
             ;;
     esac
     wifimenu
}
wifimenu
exit 0

