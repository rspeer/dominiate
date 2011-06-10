#!/bin/sh
#
# Runs standard input through Vowpal Wabbit in test mode, then sends the
# results to standard output. Requires one argument, which is the name of the
# existing VW model to use.
#
# TODO: change to 24-bit model
cat > /tmp/vw-input-$$.txt
vw -t -d /tmp/vw-input-$$.txt --adaptive -q cc -q oo -q co -q cs -q os --loss_function logistic -i $1 -p /tmp/vw-output-$$.txt && cat /tmp/vw-output-$$.txt && rm /tmp/vw-input-$$.txt && rm /tmp/vw-output-$$.txt
