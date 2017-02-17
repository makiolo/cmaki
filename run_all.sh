#!/bin/bash -e
CC=gcc CXX=g++ MODE=Debug ./cmaki/run.sh
CC=gcc CXX=g++ MODE=Release ./cmaki/run.sh
CC=clang CXX=clang++ MODE=Debug ./cmaki/run.sh
CC=clang CXX=clang++ MODE=Release ./cmaki/run.sh

TRAVIS_REPO_SLUG=makiolo/$(basename $(pwd))
(cd cmaki_generator && CC=gcc CXX=g++ MODE=Debug ./build github://$TRAVIS_REPO_SLUG -o --server=http://artifacts.myftp.biz:8080)
(cd cmaki_generator && CC=gcc CXX=g++ MODE=Release ./build github://$TRAVIS_REPO_SLUG -o --server=http://artifacts.myftp.biz:8080)
(cd cmaki_generator && CC=clang CXX=clang++ MODE=Debug ./build github://$TRAVIS_REPO_SLUG -o --server=http://artifacts.myftp.biz:8080)
(cd cmaki_generator && CC=clang CXX=clang++ MODE=Release ./build github://$TRAVIS_REPO_SLUG -o --server=http://artifacts.myftp.biz:8080)

