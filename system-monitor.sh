[root@localhost bash-scripts]# cat system-monitor.sh
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default refresh interval (seconds)
INTERVAL=2

# Thresholds for alerts
CPU_THRESHOLD=90
MEM_THRESHOLD=90
DISK_THRESHOLD=90

# Print usage/help
usage() {
    echo "Usage: $0 [-i interval]"
    echo "  -i interval    Refresh interval in seconds (default: 2)"
    exit 1
}

# Parse arguments
while getopts ":i:h" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Function to get CPU usage %
get_cpu_usage() {
    local cpu
    cpu=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%.1f", 100 - v }' 2>/dev/null)
    if [[ -z "$cpu" ]]; then
      echo -e "${CYAN}CPU Usage:${NC} N/A"
      return
    fi
    echo -e "${CYAN}CPU Usage:${NC} ${cpu}%"
    if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l) )); then
      echo -e "${RED}⚠️  WARNING: High CPU usage!${NC}"
    fi
}

# Function to get Memory usage %
get_memory_usage() {
    local mem
    mem=$(free -m 2>/dev/null | awk 'NR==2{printf "%.2f", $3*100/$2 }')
    if [[ -z "$mem" ]]; then
      echo -e "${CYAN}Memory Usage:${NC} N/A"
      return
    fi
    echo -e "${CYAN}Memory Usage:${NC} ${mem}%"
    if (( $(echo "$mem > $MEM_THRESHOLD" | bc -l) )); then
      echo -e "${RED}⚠️  WARNING: High Memory usage!${NC}"
    fi
}

# Function to get Disk usage %
get_disk_usage() {
    local disk
    disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ -z "$disk" ]]; then
      echo -e "${CYAN}Disk Usage (root):${NC} N/A"
      return
    fi
    echo -e "${CYAN}Disk Usage (root):${NC} ${disk}%"
    if (( disk > DISK_THRESHOLD )); then
      echo -e "${RED}⚠️  WARNING: High Disk usage!${NC}"
    fi
}

# Function to get Network stats (RX, TX in MB) and IP address
get_network_stats() {
    local iface rx tx ip
    iface=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -n1)
    if [[ -z "$iface" ]]; then
      echo -e "${CYAN}Network:${NC} Interface N/A"
      return
    fi

    if [[ ! -d /sys/class/net/$iface/statistics ]]; then
      echo -e "${CYAN}Network:${NC} Interface $iface stats unavailable"
      return
    fi

    rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null)
    tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null)

    # Convert bytes to MB
    rx_mb=$((rx / 1024 / 1024))
    tx_mb=$((tx / 1024 / 1024))

    # Get IP address(es)
    ip=$(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -n1)

    echo -e "${CYAN}Network ($iface):${NC} RX: ${rx_mb} MB | TX: ${tx_mb} MB | IP: ${ip:-N/A}"
}

# Function to get system uptime
get_uptime() {
    local uptime
    uptime=$(uptime -p 2>/dev/null)
    echo -e "${CYAN}Uptime:${NC} ${uptime:-N/A}"
}

# Function to get load averages
get_load_average() {
    local load
    load=$(uptime 2>/dev/null | awk -F'load average:' '{ print $2 }' | xargs)
    echo -e "${CYAN}Load Average:${NC} ${load:-N/A}"
}

# Function to get top 3 CPU and Memory consuming processes
get_top_processes() {
    echo -e "${CYAN}Top Processes (CPU% | MEM% | COMMAND):${NC}"
    ps -eo pcpu,pmem,comm --sort=-pcpu | head -n 4 | tail -n 3 | \
      awk '{printf "  %5s%%  | %5s%% | %s\n", $1, $2, $3}'
}

# Function to draw the header
draw_header() {
    clear
    echo -e "${YELLOW}=============================="
    echo -e "   🖥️  Enhanced System Monitor"
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
    get_load_average
    get_top_processes
    echo -e "${YELLOW}Updated: $(date) | Refresh interval: ${INTERVAL}s${NC}"
    sleep "$INTERVAL"
done
