#!/bin/sh
cd output

# first turn model
vw -d turn1.rand.txt -q cc -q oo -q co -q cs -q os -b 24 -f model1.vw --loss_function logistic --adaptive -l 0.1

for i in `seq 2 25`
do
  vw -d turn$i.rand.txt -q cc -q oo -q co -q cs -q os -b 24 -i model -f model$(($i-1)).vw model$i.vw --loss_function logistic --adaptive -l 0.1
done

