#!/usr/bin/env bash

function passgen {
  docker run --rm devmtl/alpine:3.11_2020-02-26_08H42s20_dec5798 sh "random7.sh"
}

function lint {
  docker run -it --rm \
    -v $(pwd)/Dockerfile:/Dockerfile:ro \
    redcoolbeans/dockerlint
}

function lint_hado {
# tk wip
  docker run --rm hadolint/hadolint:v1.16.3-4-gc7f877d hadolint --version && echo;

  docker run --rm -i hadolint/hadolint:v1.16.3-4-gc7f877d hadolint \
    --ignore DL3000 \
    - < Dockerfile && \

  echo && \
  docker run -v `pwd`/Dockerfile:/Dockerfile replicated/dockerfilelint /Dockerfile
}

function example_array {
  arr=( "hello" "world" "three" )
  
  for i in "${arr[@]}"; do
    echo ${i}
  done
}

function case_demo {
printf 'Select your demo: (ex1 to ex4): '
read DISTR

case $DISTR in
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#
ex1)
clear
echo "ex1"

;;
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#
ex2)
clear

echo "ex2"

;;
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#
ex3)
clear

echo "ex3"

;;
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#
*)
clear

echo "Selection does not exist."

;;
esac
}