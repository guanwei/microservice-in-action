FROM ruby:2.5.0
MAINTAINER docker-library <docker-library@github.com>

RUN apt-get update -y

ADD . /app

WORKDIR /app
RUN bundle install --jobs 8

EXPOSE 9292

CMD ["rackup","-o","0.0.0.0"]