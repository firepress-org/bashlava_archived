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
  clear && Condition_Attr_2_Must_Be_Provided && App_glow
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
function log {
  git log --all --decorate --oneline --graph --pretty=oneline | head -n 10
}
function hash {
  git rev-parse HEAD && git rev-parse --short HEAD
}
function sv {
# show version / version read
  Condition_Attr_2_Must_Be_Empty && App_Show_Version 
}
function App_Yellow {
  Print_Warning
}

### capture common typo or bad habits
function sh { 
  App_invalid_cmd
}
function oo { 
  App_invalid_cmd
}
function App_invalid_cmd {
  my_message="Invalid command" && Print_Warning_Stop
}
