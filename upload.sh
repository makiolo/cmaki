#!/bin/bash -e

TRAVIS_REPO_SLUG=makiolo/$(basename $(pwd))

(cd node_modules/cmaki_generator && ./build github://$TRAVIS_REPO_SLUG -o --server=http://artifacts.myftp.biz:8080)

