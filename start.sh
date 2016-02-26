#!/bin/sh

root=$(dirname $0)

forever start --workingDir ${root} -a -l imsails.log app.js --prod