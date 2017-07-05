# DOCKER-VERSION        1.3.2

FROM ubuntu:zesty

RUN apt-get update
RUN apt-get -y install apt-utils apt-transport-https build-essential curl
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get -y install nodejs yarn

RUN mkdir /hubot
ADD bin /hubot/bin
ADD lib /hubot/lib
ADD scripts /hubot/scripts
COPY external-scripts.json /hubot/
COPY package.json /hubot/
COPY yarn.lock /hubot/

RUN cd /hubot && yarn install

EXPOSE 9001

WORKDIR /hubot

CMD ["bin/hubot"]

ENTRYPOINT ["/bin/bash"]
