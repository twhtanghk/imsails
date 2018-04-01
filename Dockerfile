FROM beevelop/cordova

ENV APP=/usr/src/app
ADD . $APP

RUN apt-get update && \
    apt-get install -y git imagemagick libav-tools python make g++ ffmpeg && \
    apt-get clean

WORKDIR $APP

RUN npm install && \
    npm install -g ionic && \
    node_modules/.bin/bower --allow-root install && \
    node_modules/.bin/gulp plugin

EXPOSE 1337
        
ENTRYPOINT ./entrypoint.sh
