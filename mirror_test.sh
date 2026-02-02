#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# Mirror list
MIRRORS=(
    "mirror.iranserver.com"
    "ir.ubuntu.sindad.cloud"
    "mirror.arvancloud.ir"
    "archive.ubuntu.petiak.ir"
    "ubuntu.hostiran.ir"
    "mirrors.pardisco.co"
    "ubuntu.pars.host"
    "mirror.0-1.cloud"
    "ubuntu.shatel.ir"
    "mirror.faraso.org"
    "repo.linuxmirrors.ir"
)

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║    🔍 Ubuntu Mirror Speed Test 🔍      ║${RESET}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${RESET}\n"

# Array to store results
declare -a RESULTS

# Test each mirror
for mirror in "${MIRRORS[@]}"; do
    echo -ne "${BLUE}⏳ Testing ${YELLOW}$mirror${BLUE} ...${RESET}"

    # Ping mirror
    ping_result=$(ping -c 2 -W 2 "$mirror" 2>/dev/null | grep 'rtt' | awk -F'/' '{print $5}')

    if [ -n "$ping_result" ]; then
        # Convert to integer
        ping_ms=$(echo "$ping_result" | cut -d. -f1)
        RESULTS+=("$ping_ms|$mirror")
        echo -e "\r${GREEN}✓${RESET} ${mirror}: ${GREEN}${BOLD}${ping_ms} ms${RESET}                    "
    else
        echo -e "\r${RED}✗${RESET} ${mirror}: ${RED}Connection failed${RESET}              "
    fi
done

echo ""

# Check if any mirror was found
if [ ${#RESULTS[@]} -eq 0 ]; then
    echo -e "${RED}${BOLD}❌ No accessible mirror found!${RESET}"
    exit 1
fi

# Sort results
IFS=$'\n' SORTED=($(sort -t'|' -k1 -n <<<"${RESULTS[*]}"))
unset IFS

# Best mirror
BEST_PING=$(echo "${SORTED[0]}" | cut -d'|' -f1)
BEST_MIRROR=$(echo "${SORTED[0]}" | cut -d'|' -f2)

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║           📊 Final Result 📊           ║${RESET}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${RESET}\n"

echo -e "${MAGENTA}Best mirror:${RESET} ${GREEN}${BOLD}$BEST_MIRROR${RESET}"
echo -e "${MAGENTA}Speed:${RESET} ${GREEN}${BOLD}$BEST_PING ms${RESET}\n"

# Ask for confirmation
echo -e "${YELLOW}${BOLD}Do you want to set this mirror as default?${RESET}"
echo -ne "${CYAN}Enter your answer (y/n): ${RESET}"
read -r answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo -e "\n${BLUE}Configuring mirror...${RESET}"

    # Backup and configure mirror
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
        sudo sed -i.bak "s|URIs: .*|URIs: http://$BEST_MIRROR/ubuntu/|" /etc/apt/sources.list.d/ubuntu.sources
    elif [ -f /etc/apt/sources.list ]; then
        sudo sed -i.bak "s|http://[a-zA-Z0-9.-]*archive.ubuntu.com/ubuntu|http://$BEST_MIRROR/ubuntu|g" /etc/apt/sources.list
    fi

    # Clean cache
    echo -e "${BLUE}Cleaning cache...${RESET}"
    sudo rm -rf /var/lib/apt/lists/*

    echo -e "${BLUE}Updating package list...${RESET}"
    sudo apt update

    echo -e "\n${GREEN}${BOLD}✅ Mirror configured successfully!${RESET}"
else
    echo -e "\n${YELLOW}No changes made.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}────────────────────────────────────────${RESET}"
echo -e "${GREEN} Operation completed successfully! ✨${RESET}"
echo -e "${CYAN}${BOLD}────────────────────────────────────────${RESET}\n"
