#!/bin/bash

testA() {
  echo "TEST A $1";
}

testB() {
  echo "TEST B $2";
}

"$@"
