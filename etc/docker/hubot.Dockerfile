# DOCKER-VERSION        1.3.2

FROM ubuntu:artful

RUN apt-get update
RUN apt-get -y install apt-utils apt-transport-https build-essential curl
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get -y install nodejs git python3-pip php7.1-cli
RUN pip3 install mkdocs==0.17.2 pymdown-extensions
RUN npm install --global gulp

RUN mkdir /hubot
ADD bin /hubot/bin
ADD img /hubot/img
ADD lib /hubot/lib
ADD scripts /hubot/scripts
COPY external-scripts.json /hubot/
COPY package.json /hubot/
COPY package-lock.json /hubot/

RUN cd /hubot && npm install --no-save

EXPOSE 9001

WORKDIR /hubot

CMD ["bin/hubot"]

ENTRYPOINT ["/bin/bash"]
