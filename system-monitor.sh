#!/bin/bash

# Enhanced System Monitor with multi-format output and logging

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Defaults
INTERVAL=2
OUTPUT_MODE="human"  # human, json, csv
LOG_FILE=""

# Thresholds
CPU_THRESHOLD=90
MEM_THRESHOLD=90
DISK_THRESHOLD=90

# Usage info
usage() {
    echo "Usage: $0 [-i interval] [-o output_mode] [-l log_file] [-h]"
    echo "  -i interval       Refresh interval in seconds (default: 2)"
    echo "  -o output_mode    Output format: human | json | csv (default: human)"
    echo "  -l log_file       Path to log file (optional)"
    echo "  -h                Show this help message"
    exit 1
}

# Parse CLI args
while getopts ":i:o:l:h" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    o) OUTPUT_MODE=$OPTARG ;;
    l) LOG_FILE=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Trap Ctrl+C and exit gracefully
trap "echo -e '\n${YELLOW}Exiting system monitor...${NC}'; exit 0" SIGINT

# Logging helper
log_output() {
    [[ -n "$LOG_FILE" ]] && echo -e "$1" >> "$LOG_FILE"
}

# Data gathering functions

get_cpu_usage() {
    local cpu
    cpu=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%.1f", 100 - v }' 2>/dev/null)
    echo "$cpu"
}

get_memory_usage() {
    local mem
    mem=$(free -m 2>/dev/null | awk 'NR==2{printf "%.2f", $3*100/$2 }')
    echo "$mem"
}

get_disk_usage() {
    local disk
    disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
    echo "$disk"
}

get_network_stats() {
    local iface rx tx rx_mb tx_mb ip
    iface=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -n1)
    if [[ -z "$iface" ]] || [[ ! -d /sys/class/net/$iface/statistics ]]; then
        echo "N/A N/A N/A"
        return
    fi
    rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null)
    tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null)
    rx_mb=$((rx / 1024 / 1024))
    tx_mb=$((tx / 1024 / 1024))
    ip=$(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -n1)
    echo "$iface $rx_mb $tx_mb ${ip:-N/A}"
}

get_uptime() {
    uptime -p 2>/dev/null | sed 's/up //'
}

get_load_average() {
    uptime 2>/dev/null | awk -F'load average:' '{ print $2 }' | xargs
}

get_top_processes() {
    ps -eo pcpu,pmem,comm --sort=-pcpu | head -n 4 | tail -n 3 | \
      awk '{printf "  %5s%%  | %5s%% | %s\n", $1, $2, $3}'
}

# Output functions

print_human() {
    local cpu=$1 mem=$2 disk=$3 load="$4" iface=$5 rx_mb=$6 tx_mb=$7 ip=$8 uptime="$9"
    clear
    echo -e "${YELLOW}=============================="
    echo -e "   🖥️  Enhanced System Monitor"
    echo -e "==============================${NC}"

    # CPU
    echo -e "${CYAN}CPU Usage:${NC} ${cpu}%"
    if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l) )); then
      echo -e "${RED}⚠️  WARNING: High CPU usage!${NC}"
    fi

    # Memory
    echo -e "${CYAN}Memory Usage:${NC} ${mem}%"
    if (( $(echo "$mem > $MEM_THRESHOLD" | bc -l) )); then
      echo -e "${RED}⚠️  WARNING: High Memory usage!${NC}"
    fi

    # Disk
    echo -e "${CYAN}Disk Usage (root):${NC} ${disk}%"
    if (( disk > DISK_THRESHOLD )); then
      echo -e "${RED}⚠️  WARNING: High Disk usage!${NC}"
    fi

    # Network
    if [[ "$iface" == "N/A" ]]; then
      echo -e "${CYAN}Network:${NC} Interface N/A"
    else
      echo -e "${CYAN}Network ($iface):${NC} RX: ${rx_mb} MB | TX: ${tx_mb} MB | IP: ${ip}"
    fi

    # Uptime & Load
    echo -e "${CYAN}Uptime:${NC} ${uptime}"
    echo -e "${CYAN}Load Average:${NC} ${load}"

    # Top processes
    echo -e "${CYAN}Top Processes (CPU% | MEM% | COMMAND):${NC}"
    get_top_processes

    echo -e "${YELLOW}Updated: $(date) | Refresh interval: ${INTERVAL}s${NC}"
}

print_json() {
    local cpu=$1 mem=$2 disk=$3 load="$4" iface=$5 rx_mb=$6 tx_mb=$7 ip=$8 uptime="$9"
    cat <<EOF | tee -a "$LOG_FILE"
{
  "cpu": $cpu,
  "memory": $mem,
  "disk": $disk,
  "load_average": "$load",
  "network": {
    "interface": "$iface",
    "rx_mb": $rx_mb,
    "tx_mb": $tx_mb,
    "ip": "$ip"
  },
  "uptime": "$uptime"
}
EOF
}

print_csv() {
    local cpu=$1 mem=$2 disk=$3 load="$4" iface=$5 rx_mb=$6 tx_mb=$7 ip=$8 uptime="$9"
    echo "$cpu,$mem,$disk,\"$load\",$iface,$rx_mb,$tx_mb,\"$ip\",\"$uptime\"" | tee -a "$LOG_FILE"
}

# Main loop
while true; do
    CPU=$(get_cpu_usage)
    MEM=$(get_memory_usage)
    DISK=$(get_disk_usage)
    read -r IFACE RX_MB TX_MB IP <<< $(get_network_stats)
    UPTIME=$(get_uptime)
    LOAD=$(get_load_average)

    case $OUTPUT_MODE in
        human)
            print_human "$CPU" "$MEM" "$DISK" "$LOAD" "$IFACE" "$RX_MB" "$TX_MB" "$IP" "$UPTIME"
            ;;
        json)
            print_json "$CPU" "$MEM" "$DISK" "$LOAD" "$IFACE" "$RX_MB" "$TX_MB" "$IP" "$UPTIME"
            ;;
        csv)
            print_csv "$CPU" "$MEM" "$DISK" "$LOAD" "$IFACE" "$RX_MB" "$TX_MB" "$IP" "$UPTIME"
            ;;
        *)
            echo "Invalid output mode: $OUTPUT_MODE"
            exit 1
            ;;
    esac

    # Log to file only for human mode or when explicitly enabled
    # (Handled inside print functions with tee -a)

    if [[ "$OUTPUT_MODE" != "human" ]]; then
        # For json/csv, run once and exit
        break
    fi

    sleep "$INTERVAL"
done

