#!/bin/bash
FIRST=1
PROC_LIST=`ps -eo user,cmd --no-header|awk '{print $1" "$2}'|sed 's/\:$//'|sort|uniq`

echo -n "{\"data\":[";

ps -eo user,cmd --no-header|awk '{print $1" "$2}'|sed 's/\://'|sort|uniq|while read USER PROC; do

  if [ -e "${PROC}" ]; then
    PROC=`echo ${PROC}|awk -F'/' '{print $NF}'`
  fi
  
  if [ $FIRST == 0 ]; then
    echo -n ",";
  fi
  FIRST=0
  
  echo -n "{\"{#PROC.NAME}\":\"${PROC}\",\"{#PROC.USER}\":\"${USER}\"}";

done

echo -ne "]}\n";