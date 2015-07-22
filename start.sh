#!/bin/sh

root=~/prod/imsails
sails=`which sails`

forever start --workingDir ${root} -a -l imsails.log ${sails} lift --prod