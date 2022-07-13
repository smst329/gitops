#! /bin/bash

for x in $(ssh git@$1 list); do git clone git@$1:repo/$x; done
