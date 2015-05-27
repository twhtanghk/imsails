#!/bin/sh

root=~/prod/imsails
sails=`which sails`

cd ${root}
/usr/local/bin/forever start -a -l imsails.log $sails lift --prod