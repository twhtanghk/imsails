#!/bin/sh

root=~/prod/imsails

cd ${root}
/usr/local/bin/forever start -a -l stdout.log sails lift --prod