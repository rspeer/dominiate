#!/bin/sh
cd output

#vw -d turn1.rand.txt -q cc -q oo -q co -q cs -q os -b 22 -f model$i.vw \
#--loss_function logistic -c --passes 2

for i in `seq 1 25`
do
vw -d turn$i.rand.txt -q cc -q oo -q co -q cs -q os -b 22 -f model$i.vw \
--loss_function logistic -c --passes 2
done

