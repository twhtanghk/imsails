FROM beevelop/cordova:v6.4.0

ENV APP=/usr/src/app

RUN apt-get update && \
    apt-get install -y git imagemagick libav-tools python make g++ ffmpeg && \
    apt-get clean

Add . $APP

WORKDIR $APP

RUN npm install -g ionic npm && \
    npm install && \
    node_modules/.bin/bower --allow-root install && \
    node_modules/.bin/gulp plugin

EXPOSE 1337
        
ENTRYPOINT ./entrypoint.sh
