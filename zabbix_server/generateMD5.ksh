#!/bin/sh

Directory="./library"
cd $Directory && >md5
for File in $( ls -1|egrep -v '(index|md5)' ); do
  md5sum $File >> md5
done
cd - 1>/dev/null 2>&1

Directory="./modules"
cd $Directory && >md5
for File in $( ls -1|egrep -v '(index|md5)' ); do
  md5sum $File >> md5
done
cd - 1>/dev/null 2>&1