FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -y install gcc
RUN apt-get -y install cmake
RUN apt-get -y install python
RUN apt-get -y install python-pip
RUN pip install pyyaml
RUN pip install poster
RUN pip install codecov
