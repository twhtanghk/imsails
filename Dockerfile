FROM beevelop/cordova

WORKDIR /usr/src/app
ADD https://github.com/twhtanghk/imsails/archive/master.tar.gz /tmp
RUN tar --strip-components=1 -xzf /tmp/master.tar.gz && \
	rm /tmp/master.tar.gz && \
	apt-get update && \
	apt-get install -y git && \
	apt-get clean && \
	npm install && \
	npm install -g ionic && \
	node_modules/.bin/bower --allow-root install && \
	node_modules/.bin/gulp --prod
EXPOSE 1337
        
ENTRYPOINT node app.js --prod
