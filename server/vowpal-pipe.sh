#!/bin/sh
#
# Runs standard input through Vowpal Wabbit in test mode, then sends the
# results to standard output. Requires one argument, which is the name of the
# existing VW model to use.
#
cat > /tmp/vw-input-$$.txt
vw -t -d /tmp/vw-input-$$.txt -q cc -q oo -q co -q cs -q os -b 22 --loss_function logistic -i $1 -p /tmp/vw-output-$$.txt -a > /tmp/vw-audit-$$.txt && cat /tmp/vw-output-$$.txt && rm /tmp/vw-input-$$.txt && rm /tmp/vw-output-$$.txt
