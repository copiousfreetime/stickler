FROM x684867/ubuntucore14.04:latest
MAINTAINER Cameron Cooper <cameron@edgecase.io>

RUN apt-get update -y
RUN apt-get install -y ruby
RUN env REALLY_GEM_UPDATE_SYSTEM=1 gem update --system
RUN gem install stickler
RUN mkdir /data

EXPOSE 80
ENTRYPOINT ["stickler-server", "start", "--port", "80", "/data"]