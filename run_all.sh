#!/bin/bash
CC=gcc CXX=g++ MODE=Debug ./cmaki/run.sh
CC=gcc CXX=g++ MODE=Release ./cmaki/run.sh
CC=clang CXX=clang++ MODE=Debug ./cmaki/run.sh
CC=clang CXX=clang++ MODE=Release ./cmaki/run.sh

