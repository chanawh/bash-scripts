#!/bin/bash

echo "Starting max load stress test to trigger alerts..."

# Number of CPU cores
CPU_CORES=$(nproc)

# Run stress-ng maxing out CPU, memory, and disk IO for 60 seconds
stress-ng --cpu "$CPU_CORES" \
          --vm 1 --vm-bytes 90% \
          --hdd 1 --hdd-bytes 2G \
          --timeout 60s

echo "Max load stress test complete."
