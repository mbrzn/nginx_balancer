#!/bin/bash

while [ "1" -lt "2" ]
do
  sleep 1
  #echo "Hello"
  curl -s localhost:1314 | grep -P '<title.+Welcome' > nul
  ./trafic.sh
done

