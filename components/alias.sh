#!/usr/bin/env bash

function m {
  mainbranch
}
function e {
  edge
}
function c {
  commit
}

### not shortcuts: pr / ci / mrg

function v {
  version
}
function t { 
  tag
}
function om {
  git checkout ${default_branch}
}
function oe {
  git checkout edge
}
function l {
  log
}
function sq { 
  squash
}
function h {
  help
}
function s {
  show
}
function 1 {
  test
}
function 2 {
  help
}
function hash {
  git rev-parse HEAD && git rev-parse --short HEAD
}
function Print_Yellow {
  Print_Warning
}
### capture common typos
function sh { 
  App_invalid_cmd
}
function oo { 
  App_invalid_cmd
}
function App_invalid_cmd {
  export my_message="Invalid command" && Print_Warning_Stop
}
