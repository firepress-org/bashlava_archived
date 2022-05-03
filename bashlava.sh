#!/usr/bin/env bash

# See bashlava for all details https://github.com/firepress-org/bashlava

# There are 20 flags TODO in the code /

# the idea was to create App_List_All_Fct
# it had many impacts on the code and I renamed a lot of fct
# one of the ripple effect is that we now have a fct show().
# show() is work in progress.

# TODO
# better management core vars
# rename DEFAULT_BRANCH to MAIN_BRANCH_NAME="master"
# file to check VS file to source
# logical flags to manage under /private/*
# source "${_path_components}/private/
# Need to check if files exist

# TODO
# dummy to create a dummy commit as test quickly the whole workflow

# TODO
# rename color Print_Green << Print_Green

# Core_Reset_Custom_Path << Core_Reset_Bashlava_Path

# TODO
# glitch, release function is not stable when we tag. Sometimes it show the older release

# TODO
# create ci for using shellcheck

# TODO
# manage private vars https://github.com/firepress-org/bashlava/issues/83

# TODO
### App check brew + git-crypt + gnupg
#if brew ls --versions myformula > /dev/null; then
   # The package is installed
#else
   # The package is not installed
#fi

function mainbranch { # User_
  Condition_Attr_2_Must_Be_Empty
  Condition_No_Commits_Pending
  Condition_Apps_Must_Be_Installed

  Show_Version

### Update our local state
  git checkout ${default_branch}
  git pull origin ${default_branch}
  echo
  log
}

function edge { # User_
# TODO
# have this branch created with a unique ID to avoid conflicts with other developers edge_sunny

### it assumes there will be no conflict with anybody else
### as I'm the only person using 'edge'.
  Condition_Attr_2_Must_Be_Empty       # fct without attributs
  Condition_No_Commits_Pending
  Condition_Apps_Must_Be_Installed

### delete branch
  git branch -D edge || true

### delete branch so there is no need to use the github GUI to delete it
# TODO
# check if branch edge exist (more slick)
  git push origin --delete edge || true

  git checkout -b edge
  git push --set-upstream origin edge -f
  Show_Version
  # UX fun
  my_message="Done! checkout edge from ${default_branch}" Print_Gray
  echo && my_message="NEXT MOVE suggestion: code something and 'c' " Print_Green
}

function commit { # User_
  Condition_Attr_2_Must_Be_Provided
  git status
  git add -A
  git commit -m "${input_2}"
  git push
  # UX fun
  echo && my_message="NEXT MOVE suggestion: 1) 'c' 2) 'pr' " Print_Green
}

function pr { # User_
  Condition_Branch_Must_Be_Edge
  Condition_Attr_2_Must_Be_Empty
  Condition_No_Commits_Pending

  _pr_title=$(git log --format=%B -n 1 "$(git log -1 --pretty=format:"%h")" | cat -)
  _var_name="_pr_title" _is_it_empty="${_pr_title}" && Condition_Vars_Must_Be_Not_Empty
  
  gh pr create --fill --title "${_pr_title}" --base "${default_branch}"
  gh pr view --web
  Prompt_YesNo_ci

  echo && my_message="NEXT MOVE suggestion: 1='ci' 2='mrg' 9=cancel (or any key)" && Print_Green
  input_2="not_set"   #reset input_2
  read -r user_input;
  case ${user_input} in
    1 | ci) ci;;
    2 | mrg) mrg;;
    *) my_message="Cancelled" && Print_Gray;;
  esac

  #see debug_upstream.md
}

function mrg { # User_
  # merge from edge into main_branch
  Condition_Branch_Must_Be_Edge
  Condition_No_Commits_Pending
  Condition_Attr_2_Must_Be_Empty

  gh pr merge
  Prompt_YesNo_ci
  Show_Version

  echo && my_message="NEXT MOVE suggestion: 1='ci' 2='sv' 3='v' 4='t' 9=cancel (or any key)" && Print_Green
  input_2="not_set"   #reset input_2
  read -r user_input;
  case ${user_input} in
    1 | ci) ci;;
    2 | sv) sv;;
    3 | v) version;;
    4 | t) tag;;
    *) my_message="Cancelled" && Print_Gray;;
  esac
}

function ci { # User_
  # continuous integration status
  Condition_Attr_2_Must_Be_Empty
  Condition_No_Commits_Pending

### show latest build and open webpage on Github Actions
  #gh run list && sleep 1
  _run_id=$(gh run list | head -1 | awk '{print $11}')
  _var_name="_run_id" _is_it_empty="${_run_id}" && Condition_Vars_Must_Be_Not_Empty
### Opening the run id cuase issues. Lets stick to /actions/
  open https://github.com/${github_user}/${app_name}/actions/

  # Follow status within the terminal
  gh run watch

  echo && my_message="NEXT MOVE suggestion: 1='mrg' 9=cancel (y/n)" && Print_Green
  input_2="not_set"   #reset input_2
  read -r user_input;
  case ${user_input} in
    1 | y | mrg) mrg;;
    *) my_message="Cancelled" && Print_Gray;;
  esac
}

function version { # User_
### The version is stored within the Dockerfile. For BashLaVa, this Dockerfile is just a config-env file
  Condition_No_Commits_Pending
  Show_Version

  if [[ "${input_2}" == "not_set" ]]; then
    # The user did not provide a version
    echo && my_message="What is the version number (ex: 1.12.4)?" && Print_Green
    read -r user_input;
    input_2="${user_input}"
    #
    echo && my_message="You confirm version: ${user_input} is right? (y/n)" && Print_Green
    # warning: dont reset input_2
    read -r user_input;
    case ${user_input} in
      1 | y) echo "Good, lets continue" > /dev/null 2>&1;;
      *) my_message="Cancelled" && Print_Gray;;
    esac
  elif [[ "${input_2}" != "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Condition_Attr_2_Must_Be_Provided" && Print_Fatal
  fi

  Condition_Attr_2_Must_Be_Provided
  Condition_Version_Must_Be_Valid

### Apply updates in Dockerfile
  sed -i '' "s/^ARG VERSION=.*$/ARG VERSION=\"${input_2}\"/" Dockerfile

  git add .
  git commit . -m "Update ${app_name} to version ${input_2}"
  git push && echo
  Show_Version

  echo && my_message="NEXT MOVE suggestion: 1='pr' 2='t' 9=cancel (or any key)" && Print_Green
  input_2="not_set"   #reset input_2
  read -r user_input;
  case ${user_input} in
    1 | pr) pr;;
    2 | t) tag;;
    *) my_message="Cancelled" && Print_Gray;;
  esac
}

function tag { # User_
  Condition_No_Commits_Pending
  Condition_Attr_2_Must_Be_Empty

  git tag ${app_version} && git push --tags && echo
  Show_Version

  echo && my_message="Next, prepare release" Print_Gray
  my_message="To quit the release notes: type ':qa + enter'" Print_Gray && echo

  gh release create && sleep 5
  Show_Version
  Show_Release

  echo && my_message="NEXT MOVE suggestion: 'e' (y/n)" && Print_Green
  input_2="not_set"   #reset input_2
  read -r user_input;
  case ${user_input} in
    1 | y | e) edge;;
    *) my_message="Abord" && Print_Gray;;
  esac
}

function squash { # User_
  Condition_No_Commits_Pending
  Condition_Attr_2_Must_Be_Provided # how many steps
  Condition_Attr_3_Must_Be_Provided # message

  if ! [[ "${input_2}" =~ ^[0-9]+$ ]] ; then
    my_message="Oups, syntax error." && Print_Warning_Stop
  fi

  git reset --hard HEAD~"${input_2}"
  git merge --squash HEAD@{1}
  git push origin HEAD --force
  git status
  git add -A
  git commit -m "${input_3} /sq"
  git push
  log
  # UX fun
  echo && my_message="NEXT MOVE suggestion: 'c' - 'pr' " Print_Green
}

function log { # User_
  git log --all --decorate --oneline --graph --pretty=oneline | head -n 10
}

function test { # User_
# test our script & fct. Idempotent bash script

  echo
  my_message="Check attributes:" Print_Blue
  my_message="\$1 value is: ${input_1}" Print_Gray
  my_message="\$2 value is: ${input_2}" Print_Gray
  my_message="\$3 value is: ${input_3}" Print_Gray
  my_message="\$4 value is: ${input_4}" Print_Gray

  echo
  my_message="Check apps required:" Print_Blue
  Condition_Apps_Must_Be_Installed

  echo
  my_message="Check files and directories:" Print_Blue
  Core_Check_Which_File_Exist
  my_message="All good!" Print_Gray

  echo
  my_message="Check array from directory components:" Print_Blue
  App_array

  echo
  my_message="Check OS" Print_Blue
  if [[ $(uname) == "Darwin" ]]; then
    my_message="Running on a Mac (Darwin)" Print_Gray
  elif [[ $(uname) != "Darwin" ]]; then
    my_message="bashLaVa is not tested on other machine than Mac OS (Darmin)." && Print_Warning
  else
    my_message="FATAL: Test / Check OS" && Print_Fatal
  fi

  # PRINT OPTION 1
  echo
  my_message="Check mdv:" && Print_Blue
  _doc_name="test.md" Show_Docs

  # PRINT OPTION 2
  # 'App_test_color' it bypassed as it does an 'exit 0'
  my_message="Check colors options:" && Print_Blue && echo
  my_message="bashlava test"
  Print_Green
  #Print_Blue
  Print_Warning
  Print_Gray
  #Print_Fatal

  # PRINT OPTION 3
  echo
  my_message="Check Print_Banner:" && Print_Blue
  my_message="bashLaVa test" && Print_Banner

  my_message="Check configs:" Print_Blue
  my_message="${app_name} < app_name" Print_Gray
  #my_message="${app_version} < app_version" Print_Gray
  my_message="${github_user} < github_user" Print_Gray
  my_message="${default_branch} < default_branch" Print_Gray
  my_message="${github_org} < github_org" Print_Gray
  my_message="${dockerhub_user} < dockerhub_user" Print_Gray
  my_message="${github_registry} < github_registry" Print_Gray
  my_message="${bashlava_executable} < bashlava_executable" Print_Gray
  my_message="${_path_user} < _path_user" Print_Gray

  input_2="not_set"
  Show_Version
}

function help { # User_
  Condition_Attr_3_Must_Be_Empty

  _doc_name="help.md" Show_Docs
}

# TODO
function show { # User_
  Prompt_All_Available_Fct
    #Show_Version
}

function mdv { # User_
  Print_mdv
}

function gitio { # User_

### CMD EXECUTION
  function sub_short_url {
  clear
  curl -i https://git.io -F \
    "url=https://github.com/${input_2}/${input_3}" \
    -F "code=${input_3}" &&\

### PREVIEW
  echo && my_message="Let's open: https://git.io/${input_3}" && Print_Blue && sleep 2 &&\
  open https://git.io/${input_3}
  }

  echo
  my_message="URL ........ : https://git.io/${app_name}" && Print_Gray
  my_message="will point to: https://github.com/${github_user}/${app_name}" && Print_Gray
  #output example: https://git.io/bashlava

### PROMPT CONFIRMATION
  echo
  my_message="Do you want to continue? (y/n)" && Print_Gray
  read -r user_input;
  case ${user_input} in
    y | Y) sub_short_url;;
    *) my_message="Operation cancelled" && Print_Fatal;;
  esac
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# App : these are sub functions. They are not called directly by the user
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function App_test_color {
  my_message="bashlava test"
  Print_Green
  Print_Blue
  Print_Warning
  Print_Gray
  Print_Fatal
}

function Prompt_YesNo_ci {
  # called by fct like: pr, mrg
  echo && my_message="Want to see 'ci' status? (y/n)" && Print_Blue
  read -r user_input;
  case ${user_input} in
    y | Y) ci;;
    *) my_message="Abord 'ci' status" && Print_Green;;
  esac
}

# TODO
function Show_All { 
  Show_Version
  echo "WIP"
}

function Show_Version {
  echo && my_message="Check versions:" && Print_Blue

  Core_Load_Vars_Dockerfile

### version in dockerfile
  my_message="${app_version} < VERSION in Dockerfile" Print_Gray

### tag
  if [[ -n $(git tag -l "${app_version}") ]]; then
    echo "Good, a tag is present" > /dev/null 2>&1
    latest_tag="$(git describe --tags --abbrev=0)"
    _var_name="latest_tag" _is_it_empty="${latest_tag}" && Condition_Vars_Must_Be_Not_Empty
  else
    echo "Logic: new projet don't have any tags. So we must expect that it can be empty" > /dev/null 2>&1
    latest_tag="none "
  fi
  my_message="${latest_tag} < TAG     in mainbranch" Print_Gray

### release
  release_latest=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
    grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')

  if [[ -z "${release_latest}" ]]; then
    release_latest="none "
    echo "Logic: new projet don't have any release. So we must expect that it can be empty" > /dev/null 2>&1
  elif [[ -n "${release_latest}" ]]; then
    echo "Good, a release is present" > /dev/null 2>&1
    _var_name="release_latest" _is_it_empty="${release_latest}" && Condition_Vars_Must_Be_Not_Empty
  else
    my_message="FATAL: Show_Version | release_latest " && Print_Fatal
  fi

  my_message="${release_latest} < RELEASE in https://github.com/${github_user}/${app_name}/releases/tag/${release_latest}" && Print_Gray
  echo
}

# TODO
# to refactor, too much duplication

function Show_Release {
  release_latest=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
    grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')
  _var_name="release_latest" _is_it_empty="${release_latest}" && Condition_Vars_Must_Be_Not_Empty
  open "https://github.com/${github_user}/${app_name}/releases/tag/${release_latest}"
}

# TODO
# this is not clean, but it works 'mdv' / 'Show_Docs'
  # we can't provide an abosolute path to the file because the Docker container can't the absolute path
  # I also DONT want to provide two arguments when using glow
  # I might simply stop using a docker container for this
  # but as a priciiple, I like to call a docker container

function Show_Docs {
  # idempotent checkpoint
  _var_name="docker_img_glow" _is_it_empty="${docker_img_glow}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="_doc_name" _is_it_empty="${_doc_name}" && Condition_Vars_Must_Be_Not_Empty

  _present_path_is="$(pwd)"
  _file_is="${_doc_name}" _file_path_is="${_path_docs}/${_doc_name}" && Condition_File_Must_Be_Present

  cd ${_path_docs} || { echo "FATAL: Show_Docs / cd"; exit 1; }
  docker run --rm -it -v "$(pwd)":/sandbox -w /sandbox ${docker_img_glow} glow -w 110 ${_doc_name}
  cd ${_present_path_is} || { echo "FATAL: Show_Docs / cd"; exit 1; }
}

function Print_mdv {
  clear
  Condition_Attr_2_Must_Be_Provided

  # markdown viewer (mdv)
  _var_name="docker_img_glow" _is_it_empty="${docker_img_glow}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="input_2" _is_it_empty="${input_2}" && Condition_Vars_Must_Be_Not_Empty
  my_message="Info: 'mdv' can only read markdown files at the same path level" Print_Green
  sleep 0.5

  _present_path_is=$(pwd)
  _file_is="${input_2}" _file_path_is="${_present_path_is}/${input_2}" && Condition_File_Must_Be_Present

  docker run --rm -it -v "$(pwd)":/sandbox -w /sandbox ${docker_img_glow} glow -w 120 "${input_2}"
}

function Print_Banner {
  _var_name="docker_img_figlet" _is_it_empty="${docker_img_figlet}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="my_message" _is_it_empty="${my_message}" && Condition_Vars_Must_Be_Not_Empty
  docker run --rm ${docker_img_figlet} ${my_message}
}

# Define colors / https://www.shellhacks.com/bash-colors/
function Print_Gray {
  _var_name="my_message" _is_it_empty="${my_message}" && Condition_Vars_Must_Be_Not_Empty
  echo -e "\e[1;37m${my_message}\e[0m"
}
function Print_Green {
  _var_name="my_message" _is_it_empty="${my_message}" && Condition_Vars_Must_Be_Not_Empty
  echo -e "✨ \e[1;32m${my_message}\e[0m"
}
function Print_Blue {
  _var_name="my_message" _is_it_empty="${my_message}" && Condition_Vars_Must_Be_Not_Empty
  echo -e "👋 \e[1;34m${my_message}\e[0m"
}

### Why do we have Print_Warning and Print_Warning_Stop here ?
  # Fatal is usually reverse for unexpected erros within bashlava
  # Warning are expected - sometimes we want to stop the function, sometimes we want to continue
function Print_Warning {
  _var_name="my_message" _is_it_empty="${my_message}" && Condition_Vars_Must_Be_Not_Empty
  echo -e "🚨 \e[1;33m${my_message}\e[0m"
}
function Print_Warning_Stop {
  _var_name="my_message" _is_it_empty="${my_message}" && Condition_Vars_Must_Be_Not_Empty
  echo -e "   🚨 \e[1;33m${my_message}\e[0m 🚨" && exit 1
}
function Print_Red {
  _var_name="my_message" _is_it_empty="${my_message}" && Condition_Vars_Must_Be_Not_Empty
  echo -e "   🚨 \e[1;31m${my_message}\e[0m 🚨"
}
function Print_Fatal {
  _var_name="my_message" _is_it_empty="${my_message}" && Condition_Vars_Must_Be_Not_Empty
  echo -e "   🚨 \e[1;31m${my_message}\e[0m 🚨" && exit 1
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# Conditions (idempotent due diligence)
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#


function Condition_Branch_Must_Be_Mainbranch {
  echo "function not required yet"
  #
  _compare_me=$(git rev-parse --abbrev-ref HEAD)
  _compare_you="${default_branch}" _fct_is="Condition_Branch_Must_Be_Mainbranch"
  Condition_Vars_Must_Be_Equal
}

function Condition_Branch_Must_Be_Edge {
  _compare_me=$(git rev-parse --abbrev-ref HEAD)
  _compare_you="edge" _fct_is="Condition_Branch_Must_Be_Edge"
  Condition_Vars_Must_Be_Equal
}

function Condition_No_Commits_Pending {
  _compare_me=$(git status | grep -c "nothing to commit")
  _compare_you="1" _fct_is="Condition_No_Commits_Pending"
  Condition_Vars_Must_Be_Equal
}

# TODO 1
# refactor this function
# compare var to var
function Condition_Attr_2_Must_Be_Provided {
### ensure the second attribute is not empty to continue
  if [[ "${input_2}" == "not_set" ]]; then
    my_message="You must provide two attributes. fct: Condition_Attr_2_Must_Be_Provided" && Print_Warning_Stop
  elif [[ "${input_2}" != "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Condition_Attr_2_Must_Be_Provided" && Print_Fatal
  fi
}

# TODO 2
function Condition_Attr_3_Must_Be_Provided {
### ensure the third attribute is not empty to continue
  if [[ "${input_3}" == "not_set" ]]; then
    my_message="You must provide three attributes. fct: Condition_Attr_3_Must_Be_Provided" && Print_Warning_Stop
  elif [[ "${input_3}" != "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Condition_Attr_3_Must_Be_Provided" && Print_Fatal
  fi
}

function Condition_Attr_4_Must_Be_Provided {
  echo "fct: not needed yet"
}

# TODO 3
function Condition_Attr_2_Must_Be_Empty {
### Stop if 2 attributes are passed.
  if [[ "${input_2}" != "not_set" ]]; then
      my_message="You can NOT use two attributes. fct: Condition_Attr_2_Must_Be_Empty" && Print_Warning_Stop
  elif [[ "${input_2}" == "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Condition_Attr_2_Must_Be_Empty" && Print_Fatal
  fi
}

function Condition_Attr_3_Must_Be_Empty {
# Stop if 3 attributes are passed.
  if [[ "${input_3}" != "not_set" ]]; then
      my_message="You can NOT use three attributes. fct: Condition_Attr_3_Must_Be_Empty" && Print_Warning_Stop
  elif [[ "${input_3}" == "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Condition_Attr_3_Must_Be_Empty" && Print_Fatal
  fi
}
function Condition_Attr_4_Must_Be_Empty {
# Stop if 4 attributes are passed.
  if [[ "${input_4}" != "not_set" ]]; then
      my_message="You cannot use four attributes. fct: Condition_Attr_4_Must_Be_Empty" && Print_Warning && echo
  elif [[ "${input_4}" == "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Condition_Attr_4_Must_Be_Empty" && Print_Fatal
  fi
}

function Condition_Version_Must_Be_Valid {
  # Version is limited to these characters: 1234567890.rR-
  # so we can do: '3.5.13-r3' or '3.5.13-rc3'
  _compare_me=$(echo "${input_2}" | sed 's/[^0123456789.rcRC\-]//g')
  _compare_you="${input_2}" _fct_is="Condition_Version_Must_Be_Valid"
  Condition_Vars_Must_Be_Equal
}

function Condition_Apps_Must_Be_Installed {
### docker running?
  _compare_me=$(docker version | grep -c "Server: Docker Desktop")
  _compare_you="1" _fct_is="Condition_Apps_Must_Be_Installed"
  Condition_Vars_Must_Be_Equal
  my_message="Docker is installed" && Print_Gray

### gh cli installed
  _compare_me=$(gh --version | grep -c "https://github.com/cli/cli/releases/tag/v")
  _compare_you="1" _fct_is="Condition_Apps_Must_Be_Installed"
  Condition_Vars_Must_Be_Equal
  my_message="gh cli is installed" && Print_Gray
}

function Core_Check_Which_File_Exist {

### List markdown files under /docs/*
  arr=( "welcome_to_bashlava" "help" "test" "debug_upstream" )
  for action in "${arr[@]}"; do
    _file_is="${action}" _file_path_is="${_path_docs}/${_file_is}.md" && Condition_File_Must_Be_Present
  done

### List files under /components/*
  arr=( "sidecars.sh" "alias.sh" "example.sh" "list.txt" )
  for action in "${arr[@]}"; do
    _file_is="${action}" _file_path_is="${_path_components}/${_file_is}" && Condition_File_Must_Be_Present
  done

  _file_is="LICENSE" _file_path_is="${_path_bashlava}/${_file_is}" && Condition_File_Optionnally_Present
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && Print_Warning && sleep 2 && App_init_license && exit 1
  fi

  _file_is="README.md" _file_path_is="${_path_bashlava}/${_file_is}" && Condition_File_Optionnally_Present
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && Print_Warning && sleep 2 && App_init_readme && exit 1
  fi

  _file_is=".gitignore" _file_path_is="${_path_bashlava}/${_file_is}" && Condition_File_Optionnally_Present
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && Print_Warning && sleep 2 && App_init_gitignore && exit 1
  fi

  _file_is="Dockerfile" _file_path_is="${_path_bashlava}/${_file_is}" && Condition_File_Optionnally_Present
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && Print_Warning && sleep 2 && App_init_dockerfile && exit 1
  fi

### Warning only
  _file_is=".dockerignore" _file_path_is="${_path_bashlava}/${_file_is}" && Condition_File_Optionnally_Present

### Whern it happens, you want to know ASAP
  _file_is=".git" dir_path_is="${_path_bashlava}/${_file_is}" && Condition_Dir_Must_Be_Present
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message=".git directory does not exit" && Print_Fatal
  fi
}

function Condition_File_Must_Be_Present {
  if [[ -f "${_file_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -f "${_file_path_is}" ]]; then
    my_message="Warning: no file: ${_file_path_is}" && Print_Warning_Stop
  else
    my_message="FATAL: Condition_File_Must_Be_Present | ${_file_path_is}" && Print_Fatal
  fi
}

# This fct return the flag '_file_do_not_exist'
function Condition_File_Optionnally_Present {
  if [[ -f "${_file_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -f "${_file_path_is}" ]]; then
    my_message="Warning: no file: ${_file_path_is}" && Print_Warning
    _file_do_not_exist="true"
  else
    my_message="FATAL: Condition_File_Optionnally_Present | ${_file_path_is}" && Print_Fatal
  fi
}

# Think, IF vars are EQUAL, continue else fail the process
function Condition_Vars_Must_Be_Equal {
  if [[ "${_compare_me}" == "${_compare_you}" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [[ "${_compare_me}" != "${_compare_you}" ]]; then
    my_message="Checkpoint failed '${_fct_is}' ( ${_compare_me} and ${_compare_you} )" && Print_Warning_Stop
  else
    my_message="FATAL: Condition_Vars_Must_Be_Equal | ${_fct_is}" && Print_Fatal
  fi
}
# Think, IF vars are NOT equal, continue else fail the process
function Condition_Vars_Must_Be_Not_Equal {
  if [[ "${_compare_me}" == "${_compare_you}" ]]; then
    my_message="Checkpoint failed '${_fct_is}' ( ${_compare_me} and ${_compare_you} )" && Print_Warning_Stop
  elif [[ "${_compare_me}" != "${_compare_you}" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Condition_Vars_Must_Be_Not_Equal | ${_fct_is}" && Print_Fatal
  fi
}

# Think, IF vars is not empty, continue else fail
function Condition_Vars_Must_Be_Not_Empty {
  # source must send two vars:_is_it_empty AND _var_name
  if [[ -n "${_is_it_empty}" ]]; then    #if not empty
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ -z "${_is_it_empty}" ]]; then    #if empty
    my_message="Warning: variable '${_var_name}' is empty" && Print_Warning_Stop
  else
    my_message="FATAL: Condition_Vars_Must_Be_Not_Empty | ${_var_name}" && Print_Fatal
  fi
}

# This fct return the flag '_file_do_not_exist'
function Condition_Dir_Must_Be_Present {
  if [[ -d "${dir_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -d "${dir_path_is}" ]]; then
    my_message="Warning: no directory: ${dir_path_is}" && Print_Warning_Stop
  else
    my_message="FATAL: Condition_Dir_Must_Be_Present | ${dir_path_is}" && Print_Fatal
  fi
}

function Condition_Dir_Optionnally_Present {
  echo "function required yet"
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# Core engine
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function Core_Reset_Bashlava_Path {
# In file ${_path_user}/bashlava_path_tmp, we set an absolute path like: '~/Users/myuser/Documents/github/firepress-org/bashlava'
# bashlava_path is a file on disk (not a variable)
# It finds and configures it automatically. This way we don't have to hard code it :)
# Don't confuse it with the symlink which is usually at "/usr/local/bin/bashlava.sh"
# We write bashlava_path on disk for speed optimization and to avoid running this request all the time.
  if [[ ! -f ${_path_user}/bashlava_path ]]; then
    readlink "$(which "${bashlava_executable}")" > "${_path_user}/bashlava_path_tmp"
    rm ${_path_user}/bashlava_path
# this will strip "/bashlava.sh" from the absolute path
    cat "${_path_user}/bashlava_path_tmp" | sed "s/\/${bashlava_executable}//g" > "${_path_user}/bashlava_path"
# clean up
    rm ${_path_user}/bashlava_path_tmp
  elif [[ -f ${_path_user}/bashlava_path ]]; then
      echo "Path is valid. Lets continue." > /dev/null 2>&1
  else
    my_message="FATAL: Core_Reset_Bashlava_Path | ${dir_path_is}" && Print_Fatal
  fi
}

function Core_Load_Vars_General {
### Default var & path. Customize if need. Usefull if you want
  # to have multiple instance of bashLaVa on your machine
  bashlava_executable="bashlava.sh"
  _path_user="/usr/local/bin"

### Reset if needed
  Core_Reset_Bashlava_Path

### Set absolute path for the project root ./
  _path_bashlava="$(cat "${_path_user}"/bashlava_path)"

### Set absolute path for the ./components directory
  _path_components="${_path_bashlava}/components"

### Set absolute path for the ./docs directory
  _path_docs="${_path_bashlava}/docs"

# every scripts that are not under the main bashLaVa app, should be threated as an components.
# It makes it easier to maintain the project, it minimises cluter, it minimise break changes, it makes it easy to accept PR, more modular, etc.

### source PUBLIC scripts

# TODO
# we have few array that are configs. They should be all together under the same block of code.
### source files under /components
  arr=( "alias.sh" "sidecars.sh")
  for action in "${arr[@]}"; do
    _file_is="${action}" _file_path_is="${_path_components}/${_file_is}" && Condition_File_Must_Be_Present
    # code optimization 0o0o, add logic: _to_source="true"
    source "${_file_path_is}"
  done

# TODO
# code optimization 0o0o / Need logic to manage file under /private/* 

### source PRIVATE / custom scripts
  # the user must create /private/_entrypoint.sh file
  _file_is="_entrypoint.sh" _file_path_is="${_path_components}/private/${_file_is}" && Condition_File_Must_Be_Present
  source "${_file_path_is}"

### Set defaults for flags
  _flag_deploy_commit_message="not_set"
  _commit_message="not_set"

###	docker images
  docker_img_figlet="devmtl/figlet:1.1"
  docker_img_glow="devmtl/glow:1.4.1"

###	Date generators
  date_nano="$(date +%Y-%m-%d_%HH%Ms%S-%N)"
    date_sec="$(date +%Y-%m-%d_%HH%Ms%S)"
    date_min="$(date +%Y-%m-%d_%HH%M)"

  date_hour="$(date +%Y-%m-%d_%HH)XX"
    date_day="$(date +%Y-%m-%d)"
  date_month="$(date +%Y-%m)-XX"
  date_year="$(date +%Y)-XX-XX"
}

function Core_Load_Vars_Dockerfile {
# Define vars from Dockerfile
  app_name=$(cat Dockerfile | grep APP_NAME= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  app_version=$(cat Dockerfile | grep VERSION= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_user=$(cat Dockerfile | grep GITHUB_USER= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  default_branch=$(cat Dockerfile | grep DEFAULT_BRANCH= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_org=$(cat Dockerfile | grep GITHUB_ORG= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  dockerhub_user=$(cat Dockerfile | grep DOCKERHUB_USER= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_registry=$(cat Dockerfile | grep GITHUB_REGISTRY= | head -n 1 | grep -o '".*"' | sed 's/"//g')

  _url_to_release="https://github.com/${github_user}/${app_name}/releases/new"
  _url_to_check="https://github.com/${github_user}/${app_name}"

# idempotent checkpoints
  _var_name="app_name" _is_it_empty="${app_name}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="app_version" _is_it_empty="${app_version}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="github_user" _is_it_empty="${github_user}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="default_branch" _is_it_empty="${default_branch}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="github_org" _is_it_empty="${github_org}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="dockerhub_user" _is_it_empty="${dockerhub_user}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="github_registry" _is_it_empty="${github_registry}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="_url_to_release" _is_it_empty="${_url_to_release}" && Condition_Vars_Must_Be_Not_Empty
  _var_name="_url_to_check" _is_it_empty="${_url_to_check}" && Condition_Vars_Must_Be_Not_Empty
}

### Entrypoint
function main() {
  trap script_trap_err ERR
  trap script_trap_exit EXIT
  source "$(dirname "${BASH_SOURCE[0]}")/.bashcheck.sh"

  Core_Load_Vars_General
  Core_Load_Vars_Dockerfile
  Core_Check_Which_File_Exist

  if [[ -z "$2" ]]; then    #if empty
    input_2="not_set"
  elif [[ -n "$2" ]]; then    #if not empty
    input_2=$2
  else
    my_message="FATAL: <input_2> = ${input_2}" && Print_Fatal
  fi

  if [[ -z "$3" ]]; then    #if empty
    input_3="not_set"
  elif [[ -n "$3" ]]; then    #if not empty
    input_3=$3
  else
    my_message="FATAL: <input_3> = ${input_3}" && Print_Fatal
  fi

  if [[ -z "$4" ]]; then    #if empty
    input_4="not_set"
  elif [[ -n "$4" ]]; then    #if not empty
    input_4=$4
  else
    my_message="FATAL: <input_4> = ${input_4}" && Print_Fatal
  fi

### Load fct via .bashcheck.sh
  script_init "$@"
  cron_init
  colour_init

### Ensure there are no more than three attrbutes
  Condition_Attr_4_Must_Be_Empty

# TODO
# set as configs ex: debug="true"

### optional
  # lock_init system

### optionnal Trace the execution of the script to debug (if needed)
  # set -o xtrace

###'command not found' / Add logic to confirm the fct exist or not
  #clear
  $1
}

### Calling 'main' function by default
main "$@"

  # TODO This logic was probably creating issues
  ### Invoke main with args if not sourced. Approach via: https://stackoverflow.com/a/28776166/8787985
  #  if ! (return 0 2> /dev/null); then
  #      main "$@"
  #  fi

### When no arg are provided
input_1=$1
if [[ -z "$1" ]]; then
  echo "OK, user did not provide argument. Show options" > /dev/null 2>&1
  _doc_name="welcome_to_bashlava.md" && clear && Show_Docs

  read -r user_input; echo;
  case ${user_input} in
    # Dont use the shortcut 't' here! Its used for fct 'tag'
    1) clear && test;;
    2 | h) clear && help;;
    *) my_message="Invalid input" Print_Fatal;; 
  esac

elif [[ -n "$1" ]]; then
  echo "Good, user did provide argument(s)." > /dev/null 2>&1
else
  my_message="FATAL: main (When no arg are provided)" && Print_Fatal
fi
