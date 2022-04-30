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
function mdv {
  clear && App_Is_input_2 && App_glow
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
function s {
  status
}
function h {
  help
}
function log {
  git log --all --decorate --oneline --graph --pretty=oneline | head -n 10
}
function hash {
  git rev-parse HEAD && git rev-parse --short HEAD
}
function sv {
# show version / version read
  App_Is_input_2_empty_as_it_should && App_Show_version
}
function gitio {
  App_short_url
}
function App_Yellow {
  App_Warning
}

### capture common typo or bad habits
function invalid {
  my_message="Invalid command" && App_Warning_Stop
}
function sh { 
  invalid
}
function oo { 
  invalid
}
