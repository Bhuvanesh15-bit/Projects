#!/usr/bin/env bash

#Total CPU usage
cpu_usage=$(top -bn1 | awk '/^%Cpu/ {print 100 - $8}')

#Total memory usage
mem_total=$(free -m | awk '/^Mem:/ {print $2}')
mem_used=$(free -m | awk '/^Mem:/ {print $3}')
mem_free=$(free -m | awk '/^Mem:/ {print $7}')
mem_percent=$(awk -v used="$mem_used" -v total="$mem_total" 'BEGIN { if (total > 0) printf "%.2f", (used / total) * 100; else print "0" }')

#Total disk usage
disk_total=$(df -m / | awk 'NR==2 {print $2}')
disk_used=$(df -m / | awk 'NR==2 {print $3}')
disk_free=$(df -m / | awk 'NR==2 {print $4}')
disk_percent=$(awk -v used="$disk_used" -v total="$disk_total" 'BEGIN { if (total > 0) printf "%.2f", (used / total) * 100; else print "0" }')

#Top 5 processes by CPU usage
top_processes=$(ps -eo %cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5)

#Top 5 processes by memory usage
top_mem_processes=$(ps -eo %mem,%cpu,comm --sort=-%mem | head -n 6 | tail -n 5)

echo "Total CPU usage: ${cpu_usage}%"
echo "Total memory usage: ${mem_used}MB used / ${mem_total}MB total (${mem_percent}%) | ${mem_free}MB free"
echo "Total disk usage: ${disk_used}MB used / ${disk_total}MB total (${disk_percent}%) | ${disk_free}MB free"
echo "Top 5 processes by CPU usage:"
echo "$top_processes"
echo "Top 5 processes by memory usage:"
echo "$top_mem_processes"