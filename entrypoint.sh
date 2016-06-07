#!/bin/sh

./node_modules/.bin/gulp --prod
sed 's/\/config.xml/config.xml/g' <./platforms/browser/www/cordova.js >/tmp/cordova.js
cp /tmp/cordova.js ./platforms/browser/www
cp /tmp/cordova.js ./platforms/browser/platform_www
node app.js --prod
