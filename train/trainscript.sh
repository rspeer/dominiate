#!/bin/sh
cd output

for i in `seq 1 25`
do
vw -d turn$i.rand.txt -q cc -q oo -q co -q cs -q os -b 22 -f model$i.vw \
--loss_function logistic --adaptive -c --passes 2
done

# note -- currently needs to be re-run for turns 13 and 16
