#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to get CPU usage
get_cpu_usage() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' -v prefix="$prefix" \
        '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%.1f", 100 - v }')
    echo -e "${CYAN}CPU Usage:${NC} ${CPU}%"
}

# Function to get memory usage
get_memory_usage() {
    MEM=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2 }')
    echo -e "${CYAN}Memory Usage:${NC} ${MEM}%"
}

# Function to get disk usage
get_disk_usage() {
    DISK=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "${CYAN}Disk Usage (root):${NC} ${DISK}"
}

# Function to get network stats
get_network_stats() {
    IFACE=$(ip route | grep default | awk '{print $5}')
    RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    echo -e "${CYAN}Network RX:${NC} $((RX / 1024 / 1024)) MB | ${CYAN}TX:${NC} $((TX / 1024 / 1024)) MB"
}

# Function to get system uptime
get_uptime() {
    UPTIME=$(uptime -p)
    echo -e "${CYAN}Uptime:${NC} ${UPTIME}"
}

# Function to draw a header
draw_header() {
    clear
    echo -e "${YELLOW}=============================="
    echo -e "   🖥️  Red Hat System Monitor"
    echo -e "==============================${NC}"
}

# Main loop
while true; do
    draw_header
    get_cpu_usage
    get_memory_usage
    get_disk_usage
    get_network_stats
    get_uptime
    echo -e "${YELLOW}Updated: $(date)${NC}"
    sleep 2
done
