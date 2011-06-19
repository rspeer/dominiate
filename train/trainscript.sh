#!/bin/sh
cd output

for i in `seq 1 25`
do
vw -d turn$i.rand.txt -q cc -q oo -q co -q cs -q os -b 20 -f model$i.vw --loss_function logistic
done

