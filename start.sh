#!/bin/sh

root=~/prod/imsails

cd ${root}
/usr/local/bin/forever start -a -l imsails.log sails lift --prod