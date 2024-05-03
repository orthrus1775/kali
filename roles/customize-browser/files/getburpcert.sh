#!/bin/bash
/bin/bash -c "/usr/lib/jvm/java-1-openjdk-amd64/bin/java -Djava.awt.headless=true -jar /usr/share/burpsuite/burpsuite.jar < <(echo y) &" 
sleep 20

# counter=0

# while [ $counter -lt 5 ]; do
#     if [ -f /tmp/cacert.der ]; then
#         # File exists, set the exit code for success and exit
#         exit 0
#     else
#         # File doesn't exist, so download it using curl
#         curl http://localhost:8080/cert -o /tmp/cacert.der
#     fi

#     # Increment the counter
#     ((counter++))

#     # Sleep for 10 seconds
#     sleep 10
# done

# # If the loop completes without finding the file, set the exit code for failure
# exit 1
