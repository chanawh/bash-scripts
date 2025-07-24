#!/bin/bash

# Colors using tput for portability
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
NC=$(tput sgr0)

# Options
INTERVAL=2
CLEAR_SCREEN=true
LOG_FILE=""
RUN_ONCE=false
DEBUG=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --once) RUN_ONCE=true ;;
        --interval) INTERVAL="$2"; shift ;;
        --no-clear) CLEAR_SCREEN=false ;;
        --log) LOG_FILE="$2"; shift ;;
        --debug) DEBUG=true ;;
    esac
    shift
done

log_debug() {
    [[ "$DEBUG" == true ]] && echo -e "${YELLOW}[DEBUG] $1${NC}"
}

# Function to get CPU usage
get_cpu_usage() {
    log_debug "Getting CPU usage..."
    CPU=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%.1f", 100 - v }')
    echo -e "${CYAN}CPU Usage:${NC} ${CPU}%"
}

# Function to get memory usage
get_memory_usage() {
    log_debug "Getting memory usage..."
    MEM=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2 }')
    echo -e "${CYAN}Memory Usage:${NC} ${MEM}%"
}

# Function to get disk usage
get_disk_usage() {
    log_debug "Getting disk usage..."
    DISK=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "${CYAN}Disk Usage (root):${NC} ${DISK}"
}

# Function to get network stats
get_network_stats() {
    log_debug "Getting network stats..."
    IFACE=$(ip route | grep default | awk '{print $5}')
    if [[ -z "$IFACE" ]]; then
        echo -e "${CYAN}Network:${NC} Interface not found"
        return
    fi
    RX1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    sleep 1
    RX2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    RX_RATE=$(( (RX2 - RX1) / 1024 ))
    TX_RATE=$(( (TX2 - TX1) / 1024 ))
    echo -e "${CYAN}Network RX:${NC} ${RX_RATE} KB/s | ${CYAN}TX:${NC} ${TX_RATE} KB/s"
}

# Function to get system uptime
get_uptime() {
    log_debug "Getting uptime..."
    UPTIME=$(uptime -p)
    echo -e "${CYAN}Uptime:${NC} ${UPTIME}"
}

# Function to get temperature
get_temperature() {
    log_debug "Getting CPU temperature..."
    if command -v sensors &> /dev/null; then
        TEMP=$(sensors | grep -m 1 'Package id 0:' | awk '{print $4}')
        echo -e "${CYAN}CPU Temp:${NC} ${TEMP}"
    else
        echo -e "${CYAN}CPU Temp:${NC} sensors not installed"
    fi
}

# Function to list top running processes
list_all_processes() {
    log_debug "Listing top processes..."
    echo -e "${CYAN}Top Running Processes:${NC}"
    echo -e "${YELLOW}PID      COMMAND             %CPU       %MEM${NC}"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 10 | awk '{printf "%-8s %-20s %-10s %-10s\n", $1, $2, $3, $4}'
}

# Function to highlight heavy resource usage
highlight_heavy_processes() {
    log_debug "Highlighting heavy processes..."
    echo -e "${CYAN}Processes Using >50% CPU or >30% MEM:${NC}"
    echo -e "${YELLOW}PID      COMMAND             %CPU       %MEM${NC}"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | awk '$3 > 50 || $4 > 30 {printf "%-8s %-20s %-10s %-10s\n", $1, $2, $3, $4}'
}

# Function to draw a header
draw_header() {
    log_debug "Drawing header..."
    if [[ "$CLEAR_SCREEN" == true ]]; then clear; fi
    echo -e "${YELLOW}=============================="
    echo -e "   🖥️  Red Hat System Monitor"
    echo -e "==============================${NC}"
}

# Main loop
while true; do
    {
        draw_header
        get_cpu_usage
        get_memory_usage
        get_disk_usage
        get_network_stats
        get_temperature
        get_uptime
        echo -e "${YELLOW}----------------------------------------${NC}"
        list_all_processes
        highlight_heavy_processes
        echo -e "${YELLOW}Updated: $(date)${NC}"
    } | tee >(if [[ -n "$LOG_FILE" ]]; then cat >> "$LOG_FILE"; fi)

    [[ "$RUN_ONCE" == true ]] && break
    sleep "$INTERVAL"
done
