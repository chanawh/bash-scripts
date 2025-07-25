#!/bin/bash

# sysmon - Advanced Bash System Monitor CLI Tool

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
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
trap "echo -e '\n${YELLOW}Exiting sysmon...${NC}'; exit 0" SIGINT

# System data collectors
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{usage=100 - $8; printf "%.1f", usage}'
}

get_mem_usage() {
    free | awk '/Mem:/ { printf "%.1f", $3*100/$2 }'
}

get_disk_usage() {
    df / | awk 'NR==2 { gsub("%", "", $5); print $5 }'
}

get_load_avg() {
    awk '{ print $(NF-2), $(NF-1), $NF }' /proc/loadavg
}

get_ip_address() {
    ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1
}

get_uptime() {
    uptime -p | sed 's/up //'
}

log_output() {
    [[ -n "$LOG_FILE" ]] && echo "$1" >> "$LOG_FILE"
}

print_human() {
    draw_header
    echo -e "${CYAN}CPU Usage:${NC} $1%"
    echo -e "${CYAN}Memory Usage:${NC} $2%"
    echo -e "${CYAN}Disk Usage:${NC} $3%"
    echo -e "${CYAN}Load Average:${NC} $4"
    echo -e "${CYAN}IP Address:${NC} $5"
    echo -e "${CYAN}Uptime:${NC} $6"
    echo -e "${YELLOW}Updated: $(date) | Refresh: ${INTERVAL}s${NC}"
}

print_json() {
    echo "{\n  \"cpu\": $1,\n  \"mem\": $2,\n  \"disk\": $3,\n  \"loadavg\": \"$4\",\n  \"ip\": \"$5\",\n  \"uptime\": \"$6\"\n}" | tee -a "$LOG_FILE"
}

print_csv() {
    echo "$1,$2,$3,$4,$5,\"$6\"" | tee -a "$LOG_FILE"
}

draw_header() {
    clear
    echo -e "${YELLOW}=============================="
    echo -e "   🖥️  sysmon - System Monitor"
    echo -e "==============================${NC}"
}

# Main loop
while true; do
    CPU=$(get_cpu_usage)
    MEM=$(get_mem_usage)
    DISK=$(get_disk_usage)
    LOAD=$(get_load_avg)
    IP=$(get_ip_address)
    UPTIME=$(get_uptime)

    case $OUTPUT_MODE in
        human)
            print_human "$CPU" "$MEM" "$DISK" "$LOAD" "$IP" "$UPTIME"
            ;;
        json)
            print_json "$CPU" "$MEM" "$DISK" "$LOAD" "$IP" "$UPTIME"
            ;;
        csv)
            print_csv "$CPU" "$MEM" "$DISK" "$LOAD" "$IP" "$UPTIME"
            ;;
        *)
            echo "Invalid output mode"
            exit 1
            ;;
    esac

    sleep "$INTERVAL"
    [[ "$OUTPUT_MODE" != "human" ]] && break
    # Only repeat for human view

done
