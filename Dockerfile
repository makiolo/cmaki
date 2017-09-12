FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -y install g++-4.9
RUN apt-get -y install lcov
RUN apt-get -y install cppcheck
RUN apt-get -y install clang-3.6
RUN apt-get -y install valgrind
RUN apt-get -y install cmake
RUN apt-get -y install python
RUN apt-get -y install python-pip
RUN pip install --upgrade pip
RUN pip install pyyaml
RUN pip install poster
RUN pip install codecov
