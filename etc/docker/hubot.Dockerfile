# DOCKER-VERSION        1.3.2

FROM ubuntu:artful

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN apt-get update
RUN apt-get -y install apt-utils apt-transport-https build-essential curl
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get -y install nodejs git python3-pip php7.1-cli gcc g++ make
RUN pip3 install mkdocs pymdown-extensions markdown-fenced-code-tabs

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
