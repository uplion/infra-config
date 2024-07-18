#!/bin/bash
stream=false
if [ "$1" == "stream" ]; then
  stream=true
fi

data=$(jo -p model="gpt-3.5-turbo" messages=$(jo -a $(jo role="user" content="1+324=?")) stream=$stream)

curl -H "Content-Type: application/json" -d "$data" http://172.21.0.2:30080/api/v1/chat/completions -v
