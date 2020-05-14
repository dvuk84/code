#!/bin/bash

# Shuts down the computer if no
# key press detected in ARG sec
# Example: "./shutdown.sh 5 &"

while :
do
  read -t $1 -n 1 -s
  if [ $? -ne 0 ]
  then
    /usr/sbin/shutdown -h now
  fi
done
