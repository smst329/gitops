#!/bin/bash

for i in {1..10}; do dd if=/dev/urandom of=$i bs=1M count=16; done
