#!/bin/bash
set -x
# Function to send requests and log status codes
send_requests() {
    local url=$1
    local filename=$2
    local i=0
 
    # Loop to send 1000 requests
    while [ $i -lt 20000 ]; do
        # Send request and get status code
        status_code=$(curl  -k -s -o /dev/null -w "%{http_code}" "$url")
 
        # Get current timestamp
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 
        # Log status code and timestamp to file
        echo "$timestamp - $status_code" >> "$filename"
 
        # Increment counter
        i=$((i+1))
    done
}
 
# URL and file names
#url1="https://gw-dev.barraq.com.sa/buk/"
#url2="https://gw-dev.barraq.com.sa/buk/"
file1="tyk_dashboard_status.log"
file2="gw_status.log"
url1="http://127.0.0.1:8080/blog"
url2="http://127.0.0.1:8080/home"
 
# Send requests and log status codes
send_requests "$url1" "$file1" &
send_requests "$url2" "$file2" &
 
# Wait for both processes to finish
wait
 
echo "Requests sent and status codes logged."
