#! /bin/bash

for x in $(ssh git@awsgit list); do git clone git@awsgit:repo/$x; done

git clone git@github.com:smst329/gitops.git
