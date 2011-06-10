#!/bin/sh
cd output
for i in `seq 1 25`
do
  echo $i
  grep __$i\" allTurns.txt > turn$i.txt
  sort -k 3.22,3.30 turn$i.txt > turn$i.rand.txt
done
