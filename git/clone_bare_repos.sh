#!/bin/bash

for x in $(ls -l ~/repo|awk -F' ' '{print $9}'); do git clone $1/$x; done
