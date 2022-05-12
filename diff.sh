#!/usr/bin/env bash

since=$1
all_args=("$@")
paths=("${all_args[@]:1}")
fetch="git fetch origin ${since}"
$fetch
cmd="git diff --quiet origin/${since} HEAD -- ${paths[@]}"

$cmd;  echo $?