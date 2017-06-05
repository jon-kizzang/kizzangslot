FROM 190041820615.dkr.ecr.us-east-1.amazonaws.com/kizzangnodetemplate

# Copy this repo into place.
ADD . /var/www/kizzangslot

WORKDIR /var/www/kizzangslot
RUN npm install lodash depd forever body-parser socket.io
RUN npm install
RUN npm install nodemon -g
EXPOSE 1337
# By default start up apache in the foreground, override with /bin/bash for interative.
# CMD nodemon app.coffee