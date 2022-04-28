#!/usr/bin/env bash

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# Dev workflow
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function mainbranch {
  App_Is_edge
  App_Is_commit_unpushed
  App_Are_files_existing
  App_Is_required_apps_installed
  App_Is_input_2_empty_as_it_should
  App_Show_version

# Update our local state
  git checkout ${default_branch} &&\
  git pull origin ${default_branch} &&\
  log
}

function edge {
# it assumes there will be no conflict with anybody else
# as I'm the only person using 'edge'.
  App_Is_input_2_empty_as_it_should
  App_Is_commit_unpushed
  App_Is_required_apps_installed

  # delete branch
  git branch -d edge || true &&\
  # delete branch so there is no need to use the github GUI to delete it
  git push origin --delete edge || true &&\

  git checkout -b edge &&\
  git push --set-upstream origin edge -f &&\
  my_message="<edge> was freshly branched out from ${default_branch}" App_Blue
}

function commit {
  # if no attribut was provided, well... let's see what changed: 
  if [[ "${input_2}" == "not-set" ]]; then
    git status -s && echo &&\
    git diff --color-words
  elif [[ "${input_2}" != "not-set" ]]; then
    App_Is_input_2
    git status && git add -A &&\
    git commit -m "${input_2}" && clear &&\
    git push
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_137)" && App_Fatal
  fi
}

function pr {
  App_Is_edge
  App_Is_input_2_empty_as_it_should
  App_Is_commit_unpushed

  pr_title=$(git log --format=%B -n 1 $(git log -1 --pretty=format:"%h") | cat -)

  if [[ -n "${pr_title}" ]]; then    #if not empty
    echo "All good and idempotent" > /dev/null 2>&1
    gh pr create --fill --title "${pr_title}" --base "${default_branch}" &&\
    gh pr view --web
  elif [[ -z "${pr_title}" ]]; then    #if empty
    my_message="Warning: pr_title variable is empty. (WAR_921)" && App_Warning_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_999)" && App_Fatal
  fi

 # if the upstream is wrong, we can reset it / https://github.com/cli/cli/issues/2300
 # git config --local --get-regexp '\.gh-resolved$' | cut -f1 -d' ' | xargs -L1 git config --unset
}

function ci {
  # continuous integration status
  App_Is_input_2_empty_as_it_should &&\
  App_Is_commit_unpushed &&\
  gh run list && sleep 2 &&\
  run_id=$(gh run list | head -1 | awk '{print $12}')

  if [[ -z "${run_id}" ]]; then    #if empty
    run_id="not-set"
  else
    open https://github.com/${github_user}/${app_name}/actions/runs/${run_id}
  fi

  #gh run watch
}

function mrg {
  # merge from edge into main_branch
  App_Is_edge
  App_Is_commit_unpushed
  gh pr merge &&\
  App_Show_version
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# Release workflow
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function version {
# The version is stored within the Dockerfile. For BashLaVa, this Dockerfile is just a config-env file

  App_Is_commit_unpushed
  App_Are_files_existing

  App_Is_input_2
  App_Is_version_syntax_valid

# version before
  version_before=${app_release}

# Logic between 'version' and 'release'.
# For docker projects like https://github.com/firepress-org/ghostfire,
# there is a conflict where defining a version like 3.11-rc2 doesn't work because the dockerfile will try to build 'alpine 3.11-rc2'.
# Therefore, we need to have a release flag. This allows us to have a clean release cycle.
# sed will trim '-rc2'
  if [[ "${version_with_rc}" == "false" ]]; then
    version_trim=$(echo ${input_2} | sed 's/-r.*//g')
  elif [[ "${version_with_rc}" != "false" ]]; then
    version_trim=${input_2}
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_101)" && App_Fatal
  fi

# apply updates
  sed -i '' "s/^ARG VERSION=.*$/ARG VERSION=\"${version_trim}\"/" Dockerfile
  sed -i '' "s/^ARG RELEASE=.*$/ARG RELEASE=\"${input_2}\"/" Dockerfile

# version after
  App_Get_var_from_dockerfile
  version_after=${app_release}

  git add . &&\
  git commit . -m "Update ${app_name} to version ${app_release} /Dockerfile" &&\
  git push && echo &&\

  App_Show_version && sleep 1 && echo &&\
  log
}

function tag {
  App_Is_mainbranch
  App_Are_files_existing

  git tag ${app_release} && git push --tags && echo &&\
  App_Show_version && sleep 1 && echo &&\

  my_message="Next, prepare release" App_Blue &&\
  my_message="To quit the release notes: type ':qa + enter'" App_Blue &&\
  echo && sleep 1 &&\

  gh release create
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# Utility's functions
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function squash {
  App_Is_commit_unpushed
  App_Is_input_2
  App_Is_input_3

  backwards_steps="${input_2}"
  git_message="${input_3}"
  usage="sq 3 'Add fct xyz'"

  git reset --hard HEAD~"${backwards_steps}" &&\
  git merge --squash HEAD@{1} &&\
  git push origin HEAD --force &&\
  git status &&\
  git add -A &&\
  git commit -m "${git_message} (squash)" &&\
  git push;

  log
}

function shortner-url {
### output example: https://git.io/bashlava

### when no attributes are passed, use configs from the current project.
  if [[ "${input_2}" == "not-set" ]]; then
    input_2=${github_user}
    input_3=${app_name}
  fi

  App_Is_input_2
  App_Is_input_3

### generate URL
  clear
  curl -i https://git.io -F \
    "url=https://github.com/${input_2}/${input_3}" \
    -F "code=${input_3}" &&\

### see result
  echo && my_message="Let's open: https://git.io/${input_3}" && App_Blue && sleep 2 &&\
  open https://git.io/${input_3}
}

function test-bashlava {
# test our script & fct. Idempotent bash script

  figlet_message="bashLaVa" App_figlet

  echo "Attributes:" &&\
  my_message="\$1 value is: ${input_1}" App_Blue &&\
  my_message="\$2 value is: ${input_2}" App_Blue &&\
  my_message="\$3 value is: ${input_3}" App_Blue &&\
  my_message="\$4 value is: ${input_4}" App_Blue &&\

  echo &&\
  echo "OS:" &&\
  if [[ $(uname) == "Darwin" ]]; then
    my_message="Running on a Mac (Darwin)" App_Blue
  elif [[ $(uname) != "Darwin" ]]; then
    my_message="bashLaVa is not tested on other machine than Darmin (Mac). Please let me know if you want to contribute (WARN_901)." && App_Warning
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_102)" && App_Fatal
  fi

### will stop if a file is missing
  App_Are_files_existing

  echo && echo "App required on your local machine:" &&\
  App_Is_required_apps_installed

  echo && echo "Configs for this git repo:" &&\

  my_message="${app_name} < app_name" App_Blue
  my_message="${app_version} < app_version" App_Blue
  my_message="${app_release} < app_release" App_Blue
  my_message="${github_user} < github_user" App_Blue
  my_message="${default_branch} < default_branch" App_Blue
  my_message="${github_org} < github_org" App_Blue
  my_message="${dockerhub_user} < dockerhub_user" App_Blue
  my_message="${github_registry} < github_registry" App_Blue
  my_message="${bashlava_executable} < bashlava_executable" App_Blue
  my_message="${my_path} < my_path" App_Blue

  # test that the entrypoint works properly
  echo && echo "function example_array" && example_array

  echo && my_message="This banner below confirm that your add-on is well configured:" App_Blue
  banner
}

function status {
  gh status &&\
  git status
}

function help {

  input_2="./docs/dev_workflow.md" && App_glow &&\
  input_2="./docs/release_workflow.md" && App_glow &&\
  input_2="./docs/more_commands.md" && App_glow

  ### old code that could be useful in the future
  ### list tag #util> within the code
  # cat ${my_path}/${bashlava_executable} | awk '/#util> /' | sed '$ d' | awk '{$1="";$3="";$4="";print $0}' | sort -k2 -n | sed '/\/usr\/local\/bin\//d' && echo
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# function alias
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function m {
  mainbranch
}
function e {
  edge
}
function c {
  commit
}

### pr / ci / mrg

function v {
  version
}
function t { 
  tag
}
function mdv {
  clear
  App_Is_input_2
  App_glow
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
  git log --all --decorate --oneline --graph --pretty=oneline | head -n 6
}
function hash {
  git rev-parse HEAD && git rev-parse --short HEAD
}
function sv {
# show version / version read
  App_Is_input_2_empty_as_it_should
  App_Show_version
}
function test {
  test-bashlava
}
function gitio {
  shortner-url
}
function App_Yellow {
  App_Warning
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# CHILD FUNCTIONS
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function App_RemoveTmpFiles {
  rm ~/temp/tmpfile > /dev/null 2>&1
  rm ~/temp/tmpfile2 > /dev/null 2>&1
  rm ~/temp/tmpfile3 > /dev/null 2>&1
  rm ~/temp/tmpfile4 > /dev/null 2>&1
}

function App_Is_mainbranch {
  currentBranch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "${currentBranch}" == "${default_branch}" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [[ "${currentBranch}" != "${default_branch}" ]]; then
    my_message="You must be on branch ${default_branch} to perform this action (ERR_103)" && App_Warning_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_104)" && App_Fatal
  fi
}

function App_Is_edge {
  currentBranch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "${currentBranch}" == "edge" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [[ "${currentBranch}" != "edge" ]]; then
    my_message="You must be on branch edge to perform this action (ERR_105)" && App_Warning_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_106)" && App_Fatal
  fi
}

function App_Is_commit_unpushed {
  if [[ $(git status | grep -c "nothing to commit") == "1" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [[ $(git status | grep -c "nothing to commit") != "1" ]]; then
    my_message="You must push your commit(s) before doing this action (ERR_107)" && App_Warning_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_108)" && App_Fatal
  fi
}

function App_Is_input_2 {
# ensure the second attribute is not empty to continue
  if [[ "${input_2}" == "not-set" ]]; then
    my_message="You must provide two attributes. See help (WARN_109)" && App_Warning_Stop
  elif [[ "${input_2}" != "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_110)" && App_Fatal
  fi
}
function App_Is_input_3 {
# ensure the third attribute is not empty to continue
  if [[ "${input_3}" == "not-set" ]]; then
    my_message="You must provide three attributes. See help (WARN_111)" && App_Warning_Stop
  elif [[ "${input_3}" != "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_112)" && App_Fatal
  fi
}

function App_Is_input_2_empty_as_it_should {
# Stop if 2 attributes are passed.
  if [[ "${input_2}" != "not-set" ]]; then
      my_message="You cannot use two attributes for this function. See help (ERR_113)" && App_Warning_Stop
  elif [[ "${input_2}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_114)" && App_Fatal
  fi
}
function App_Is_input_3_empty_as_it_should {
# Stop if 3 attributes are passed.
  if [[ "${input_3}" != "not-set" ]]; then
      my_message="You cannot use three attributes for this function. See help (ERR_115)" && App_Warning_Stop
  elif [[ "${input_3}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_116)" && App_Fatal
  fi
}
function App_Is_Input_4_empty_as_it_should {
# Stop if 4 attributes are passed.
  if [[ "${input_4}" != "not-set" ]]; then
      my_message="You cannot use four attributes with BashLava. See help (ERR_117)" && App_Warning_Stop
  elif [[ "${input_4}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_118)" && App_Fatal
  fi
}

function App_Is_version_syntax_valid {
# Version is limited to these characters: 1234567890.rR-
# so we can do: '3.5.13-r3' or '3.5.13-rc3'
  ver_striped=$(echo "${input_2}" | sed 's/[^0123456789.rcRC\-]//g')

  if [[ "${input_2}" == "${ver_striped}" ]]; then
    echo "Version is valid, lets continue" > /dev/null 2>&1
  elif [[ "${input_2}" != "${ver_striped}" ]]; then
    my_message="The version format is not valid (ERR_119)" && App_Warning_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_120)" && App_Fatal
  fi
}

function App_Are_files_existing {

# --- 2)
  if [ -f Dockerfile ] || [ -f Dockerfile_template ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f Dockerfile ] || [ ! -f Dockerfile_template ]; then
    my_message="Dockerfile does not exit (WARN_902). Let's generate one:" && init_dockerfile && App_Warning_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_121)" && App_Fatal
  fi
# --- 3)
  if [ -f .gitignore ] || [ -f .gitignore_template ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f .gitignore ] || [ ! -f .gitignore_template ]; then
    my_message=".gitignore file does not exit. Let's generate one (WARN_903)" && init_gitignore && App_Warning_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_122)" && App_Fatal
  fi
# --- 4)
  if [ -f LICENSE ] || [ -f LICENSE_template ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f LICENSE ] || [ ! -f LICENSE_template ]; then
    my_message="LICENSE file does not exit. Let's generate one (WARN_904)" && init_license && App_Warning_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_123)" && App_Fatal
  fi
# --- 5)
  if [ -f README.md ] || [ -f README_template.md ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f README.md ] || [ ! -f README_template.md ]; then
    my_message="README.md file does not exit. Let's generate one (WARN_905)" && init_readme && App_Warning_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_124)" && App_Fatal
  fi
# --- 6)
  if [ -d .git ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -d .git ]; then
    my_message="This is not a git repo (WARN_906)" && App_Warning_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_125)" && App_Fatal
  fi
# --- 7)
  # 'init_dockerfile_ignore' is optional as not everyone needs this option
}

function App_Is_required_apps_installed {
# check if these app are running

# docker
  if [[ $(docker version | grep -c "Server: Docker Desktop") == "1" ]]; then
    my_message="$(docker --version) is installed." App_Blue
  elif [[ $(docker version | grep -c "Server: Docker Desktop") != "1" ]]; then
    my_message="Docker is not running (WARN_907). https://github.com/firepress-org/bash-script-template#requirements" && App_Warning
    my_message="Bashlava can run withtout Docker but your visual experience will suffer." && App_Warning
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_126)" && App_Fatal
  fi

# gh (github cli)
# does not work, see https://github.com/firepress-org/bashlava/issues/31

#  if [[ $(gh auth status | grep -c "Logged in to github.com as") == "1" ]]; then
#    my_message="gh is installed." App_Blue
#  elif [[ $(gh auth status | grep -c "Logged in to github.com as") != "1" ]]; then
#    echo && my_message="gh is not installed. See requirements https://git.io/bashlava" && App_Warning_Stop
#  else
#    my_message="FATAL: Please open an issue for this behavior (ERR_127)" && App_Fatal
#  fi
}

function App_Curl_url {
# must receive var: url_to_check
  UPTIME_TEST=$(curl -Is ${url_to_check} | grep -io OK | head -1);
  MATCH_UPTIME_TEST1="OK";
  MATCH_UPTIME_TEST2="ok";
  if [ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST1" ] || [ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST2" ]; then
    my_message="${url_to_check} <== is online" && App_Green
  elif [ "$UPTIME_TEST" != "$MATCH_UPTIME_TEST1" ] || [ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST2" ]; then
    my_message="${url_to_check} <== is offline" && App_Warning
    my_message="The git up repo is not responding as expected :-/" && App_Fatal
  fi
}

function App_Get_var_from_dockerfile {
# Extract vars from our Dockerfile
  app_name=$(cat Dockerfile | grep APP_NAME= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  app_version=$(cat Dockerfile | grep VERSION= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  app_release=$(cat Dockerfile | grep RELEASE= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_user=$(cat Dockerfile | grep GITHUB_USER= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  default_branch=$(cat Dockerfile | grep DEFAULT_BRANCH= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_org=$(cat Dockerfile | grep GITHUB_ORG= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  dockerhub_user=$(cat Dockerfile | grep DOCKERHUB_USER= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_registry=$(cat Dockerfile | grep GITHUB_REGISTRY= | head -n 1 | grep -o '".*"' | sed 's/"//g')

# Validate vars are not empty
  if [[ -z "${app_name}" ]] ; then    #if empty
    clear
    my_message="Can't find variable APP_NAME in the Dockerfile (ERR_128)" && App_Fatal
  elif [[ -z "${app_version}" ]] ; then    #if empty
    clear
    my_message="Can't find variable VERSION in the Dockerfile (ERR_129)" && App_Fatal
  elif [[ -z "${app_release}" ]] ; then    #if empty
    clear
    my_message="Can't find variable RELEASE in the Dockerfile (ERR_130)" && App_Fatal
  elif [[ -z "${github_user}" ]] ; then    #if empty
    clear
    my_message="Can't find variable GITHUB_USER in the Dockerfile (ERR_131)" && App_Fatal
  elif [[ -z "${default_branch}" ]] ; then    #if empty
    clear
    my_message="Can't find variable DEFAULT_BRANCH in the Dockerfile (ERR_132)" && App_Fatal
  elif [[ -z "${github_org}" ]] ; then    #if empty
    clear
    my_message="Can't find variable GITHUB_ORG in the Dockerfile (ERR_133)" && App_Fatal
  elif [[ -z "${dockerhub_user}" ]] ; then    #if empty
    clear
    my_message="Can't find variable DOCKERHUB_USER in the Dockerfile (ERR_134)" && App_Fatal
  elif [[ -z "${github_registry}" ]] ; then    #if empty
    clear
    my_message="Can't find variable GITHUB_REGISTRY in the Dockerfile (ERR_135)" && App_Fatal
  fi

  url_to_release="https://github.com/${github_user}/${app_name}/releases/new"
  url_to_check="https://github.com/${github_user}/${app_name}"
  # App_Curl_url
}

function App_Show_version {
# Show version from three sources
  if [[ "${input_2}" == "not-set" ]]; then
    echo && my_message="Version checkpoints:" && App_Blue &&\

# 1) dockerfile
    my_message="${app_version} < VERSION in Dockerfile" App_Blue
    my_message="${app_release} < RELEASE in Dockerfile" App_Blue

# 2) tag
    latest_tag="$(git describe --tags --abbrev=0)"
    my_message="${latest_tag} < TAG on mainbranch" App_Blue

# 3) release
    release_latest=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
      grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')

    my_message="${release_latest} < RELEASE on https://github.com/${github_user}/${app_name}/releases/tag/${release_latest}" && App_Blue && echo
  fi
}

function App_figlet {
  docker run --rm ${docker_img_figlet} ${figlet_message}
}

function App_glow {
  docker run --rm -it -v $(pwd):/sandbox -w /sandbox ${docker_img_glow} glow -w 120 ${input_2}
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# Define colors / https://www.shellhacks.com/bash-colors/
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#
function App_Green { echo -e "\e[1;32m${my_message}\e[0m"
                                # green
}
function App_Blue { echo -e "\e[1;34m${my_message}\e[0m"
                                # green
}
function App_Warning { echo -e "\e[1;33m${my_message}\e[0m"
                                # yellow
                                # does not stop the scripts
}
function App_Warning_Stop { echo -e "\e[1;33m${my_message}\e[0m" && App_Fatal
                                # yellow
                                # does not stop the scripts
}
function App_Fatal {
  my_message="exit 1" && echo -e "\e[1;31m${my_message}\e[0m"
                                # red
  exit 1
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# bashLaVa engine & low-level logic
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function App_Reset_Custom_path {
# In file ${my_path}/bashlava_path_tmp, we set an absolute path like: '/Users/pascalandy/Documents/github/firepress-org/bashlava'
# It finds and configures it automatically. This way we don't have to hard code it :)
# Don't confuse it with the symlink which is usually at "/usr/local/bin/bashlava.sh"
# We write bashlava_path on disk to avoid running this request all the time.
# Again, ${my_path}/bashlava_path point to a file on disk (not a variable)
  if [ ! -f ${my_path}/bashlava_path ]; then
    readlink $(which "${bashlava_executable}") > "${my_path}/bashlava_path_tmp"
    rm ${my_path}/bashlava_path
# this will strip "/bashlava.sh" from the absolute path
    cat "${my_path}/bashlava_path_tmp" | sed "s/\/${bashlava_executable}//g" > "${my_path}/bashlava_path"
# clean up
    rm ${my_path}/bashlava_path_tmp
  elif [ -f ${my_path}/bashlava_path ]; then
      echo "Path is valid. Lets continue." > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_136)" && App_Fatal
  fi
}

function App_DefineVariables {
# Hardcoded VAR

# Default var & path. Customize if need. Usefull if you want
# to have multiple instance of bashLaVa on your machine
  bashlava_executable="bashlava.sh"
  my_path="/usr/local/bin"

# Does this app accept release candidates (ie. 3.5.1-rc1) in the _version? By default = false
# When buidling docker images it better to not have rc in the version as breaks the pattern.
# When not working with a docker build, feel free to put this flag as true.
# default value is false
  version_with_rc="false"

### Reset if needed
  App_Reset_Custom_path
  _bashlava_path="$(cat ${my_path}/bashlava_path)"

### Set absolute path for the add-on scripts
  local_bashlava_addon_path="${_bashlava_path}/add-on"

# every scripts that are not under the main bashLaVa app, should be threated as an add-on.
# It makes it easier to maintain the project, it minimises cluter, it minimise break changes, it makes it easy to accept PR, more modular, etc.

### entrypoint: public scripts
  if [[ -f "${local_bashlava_addon_path}/code_example.sh" ]]; then
    echo "all good / idempotent" > /dev/null 2>&1
    source "${local_bashlava_addon_path}/code_example.sh"
  elif [[ ! -f "${local_bashlava_addon_path}/code_example.sh" ]]; then
    my_message="Warning: /code_example.sh is not present (WARN_108)" && App_Warning_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_139)" && App_Fatal
  fi

### entrypoint: private / custom scripts
# by default bashlava does not come with the private DIR
# the user must create /private/_entrypoint.sh file
  if [[ -f "${local_bashlava_addon_path}/private/_entrypoint.sh" ]]; then
    echo "all good / idempotent" > /dev/null 2>&1
    source "${local_bashlava_addon_path}/private/_entrypoint.sh"
  elif [[ ! -f "${local_bashlava_addon_path}/private/_entrypoint.sh" ]]; then
    my_message="Warning: /private/_entrypoint.sh is not present (WARN_109)" && App_Warning_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_140)" && App_Fatal
  fi

### Set defaults for flags
  _flag_deploy_commit_message="not-set"
  _commit_message="not-set"

###	docker images
  docker_img_figlet="devmtl/figlet:1.1"
  docker_img_glow="devmtl/glow:1.4.1"

###	Date generators
  date_nano="$(date +%Y-%m-%d_%HH%Ms%S-%N)"
    date_sec="$(date +%Y-%m-%d_%HH%Ms%S)"
    date_min="$(date +%Y-%m-%d_%HH%M)"
#
  date_hour="$(date +%Y-%m-%d_%HH)XX"
    date_day="$(date +%Y-%m-%d)"
  date_month="$(date +%Y-%m)-XX"
  date_year="$(date +%Y)-XX-XX"
#	This is how it looks like:
            # 2017-02-22_10H24_14-500892448
            # 2017-02-22_10H24_14
            # 2017-02-22_10H24
#
            # 2017-02-22_10HXX
            # 2017-02-22
            # 2017-02-XX
            # 2017-XX-XX
}

### Entrypoint
function main() {

  trap script_trap_err ERR
  trap script_trap_exit EXIT
  source "$(dirname "${BASH_SOURCE[0]}")/.bashcheck.sh"

### Load ENV variables
  App_DefineVariables
  App_Get_var_from_dockerfile

  if [[ -z "$2" ]]; then    #if empty
    input_2="not-set"
  else
    input_2=$2
  fi

  if [[ -z "$3" ]]; then    #if empty
    input_3="not-set"
  else
    input_3=$3
  fi

  if [[ -z "$4" ]]; then    #if empty
    input_4="not-set"
  else
    input_4=$4
  fi

### Load functions via .bashcheck.sh
  script_init "$@"
  cron_init
  colour_init

### Ensure there are no more than three attrbutes
  App_Is_Input_4_empty_as_it_should

### optional
  # lock_init system

### optionnal Trace the execution of the script to debug (if needed)
  # set -o xtrace

###'command not found' / Add logic to confirm the function exist or not
  #clear
  $1
}

main "$@"

### If the user does not provide any argument, let offer options
input_1=$1
if [[ -z "$1" ]]; then

  input_2="./docs/case_what_do_you_want.md" && clear && App_glow;
  read user_input; echo;
  case ${user_input} in
    1) input_2="./docs/dev_workflow.md" && clear && App_glow;;
    2) input_2="./docs/release_workflow.md" && clear && App_glow;;
    3) input_2="./docs/more_commands.md" && clear && App_glow;;
    4) test;;
    5) help;;
    6) input_2="./LICENSE" && clear && App_glow;;
    7) input_2="./README.md" && clear && App_glow;;
    *) my_message="Invalid input." App_Fatal;; 
  esac

else
  input_1=$1
fi
