#!/bin/sh
#
# Runs standard input through Vowpal Wabbit in test mode, then sends the
# results to standard output. Requires one argument, which is the name of the
# existing VW model to use.
cat > /tmp/vw-input-$$.txt
vw -t -d /tmp/vw-input-$$.txt --adaptive -q cc -q oo -q uu -q vv -q co -q cu -q cv -q ou -q ov --loss_function logistic -i $1 -p /tmp/vw-output-$$.txt && cat /tmp/vw-output-$$.txt && rm /tmp/vw-input-$$.txt && rm /tmp/vw-output-$$.txt
