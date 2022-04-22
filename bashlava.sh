#!/usr/bin/env bash

function commit {
# if no attribute were past, well... let's see what changed:
  if [[ "${input_2}" == "not-set" ]]; then
    diff
  fi

  App_Is_input_2
  git status && git add -A &&\
  git commit -m "${input_2}" && clear && git push  &&\
  version-read-from-dockerfile
}

function version {
# The version is tracked in a Dockerfile (it's cool if your project don't use docker)
# For BashLaVa, this Dockerfile is just a config-env file
  App_Is_edge
  App_Is_commit_unpushed
  App_Are_files_existing

  App_Show_version_from_three_sources

  App_Is_input_2
  App_Is_version_syntax_valid

# version before
  App_Get_var_from_dockerfile
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
    my_message="FATAL: Please open an issue for this behavior (err_f31)" App_Pink && App_Stop
  fi

# apply updates
  sed -i '' "s/^ARG VERSION=.*$/ARG VERSION=\"${version_trim}\"/" Dockerfile
  sed -i '' "s/^ARG RELEASE=.*$/ARG RELEASE=\"${input_2}\"/" Dockerfile

# version after
  App_Get_var_from_dockerfile
  version_after=${app_release}

  App_Get_var_from_dockerfile
  git add . &&\
  git commit . -m "Update ${app_name} to version ${app_release} /Dockerfile" &&\
  git push origin edge

  echo && my_message="run ci to check status of your built on Github Actions (if any)" App_Blue

  log
# next step is to: 'm' or 'm-'
}

function mainbranch {
  App_Is_edge
  App_Is_commit_unpushed
  App_Are_files_existing
  App_Is_required_apps_installed
  App_Get_var_from_dockerfile

  App_Show_version_from_three_sources

# Update our local state
  git checkout ${default_branch} &&\
  git pull origin ${default_branch} &&\
  log

# next step is to: tag and release
}

function tag {
  App_Are_files_existing
  App_Get_var_from_dockerfile

  git tag ${app_release} && git push --tags && echo

  my_message="Next, publish release over: ${url_to_release}" App_Blue
  open ${url_to_release}
}

function pr {
  App_Is_edge
  App_Is_commit_unpushed
  App_Get_var_from_dockerfile

  pr_title=$(git log --format=%B -n 1 $(git log -1 --pretty=format:"%h") | cat -)
  gh pr create --fill --title "${pr_title}" --base "${default_branch}"

 # if the upstream is wrong, we can reset it:
 # https://github.com/cli/cli/issues/2300
 # git config --local --get-regexp '\.gh-resolved$' | cut -f1 -d' ' | xargs -L1 git config --unset
}

#
  #
    #
      #
        #
          #
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# OFFICIAL SHORTCUTS
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function c { #core> ...... "commit" all changes + git push | usage: c "FEAT: new rule to avoid this glitch
  #core>
  commit
}
function v { #core> ...... "version" update your app | usage: v 1.50.1
  version
}
function m { #core> ...... "mainbranch or main" branch git pull + show logs
  mainbranch
}
function rr { #util> ..... "release read" Show release from Github (attr is opt)
  release-read
}
function tr { #util> ..... "tag read" tag on mainbranch (no attr)
  App_Is_input_2_empty_as_it_should
  tag-read
}
function mdv { #util> .... "markdown viewer" | usage: mdv README.md
  clear
  App_Is_input_2
  App_glow
}
function ci { #util> ..... "continous integration" CI status from Github Actions (no attr)
  App_Is_input_2_empty_as_it_should
  continuous-integration-status
}
function om { #util> ..... "out to mainbranch Basic git checkout (no attr)
  App_Get_var_from_dockerfile
  git checkout ${default_branch}
}
function oe { #util> ..... "out edge" Basic git checkout (no attr)
  git checkout edge
}
function l { #util> ...... "log" show me the latest commits (no attr)
  log
}
function sq { #util> ..... "squash" commits | usage: sq 3 "Add fct xyz
  squash
}
function t { #core> ...... "tag" it uses release version as the tag version + push the tag + open the release page
  tag
}
function e { #util> ...... "edge" recrete a fresh edge branch from mainbranch (no attr)
  edge
}
function s { #util> ...... "status" show me if there is something to commit (no attr)
  status
}
function cr { #util> ..... "changelog read" (no attr)
  App_Is_input_2_empty_as_it_should
  changelog-read
}
function h { #util> ...... "help" alias are also set to: -h, --help, help (no attr)
  help
}
function log { #util> .... "log" Show me the lastest commits (no attr)
  git log --all --decorate --oneline --graph --pretty=oneline | head -n 6
}
function hash { #util> ... "hash" Show me the latest hash commit (no attr)
  git rev-parse HEAD && git rev-parse --short HEAD
}
function diff { #util> ... "diff" show me diff in my code (no attr)
  git diff
}
function vr { #util> ..... "version read" show app's version from Dockerfile (no attr)
  App_Is_input_2_empty_as_it_should
  version-read
}
function test { #util> ... "test" test if requirements for bashLaVa are meet (no attr)
  test-bashlava
}
function gitio { #util> .. "git.io shortner" work only with GitHub repos | usage: shorturl firepress-org ghostfire (opt attr)
  shortner-url
}
function list { #util> ... "list" all core functions (no attr)
  list-functions
}

#
  #
    #
      #
        #
          #
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

function changelog-read {
  input_2="CHANGELOG.md"
  App_Is_input_2
  App_glow50

# if needed, you can specify the file using fct 'mdv'
}

function edge {
# it assumes there will be no conflict with anybody else
# as I'm the only person using 'edge'.
  App_Is_commit_unpushed

  # delete branch
  git branch -d edge || true &&\
  # delete branch so there is no need to use the github GUI to delete it
  git push origin --delete edge || true &&\

  git checkout -b edge &&\
  git push --set-upstream origin edge -f &&\
  my_message="<edge> was freshly branched out from ${default_branch}" App_Blue
}

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

function list-functions {

  title-core &&\
  cat ${my_path}/${bashlava_executable} | awk '/#core> /' | sed '$ d' | awk '{$1="";$3="";$4="";print $0}' | sed '/\/usr\/local\/bin\//d' && echo &&\

  title-utilities &&\
  cat ${my_path}/${bashlava_executable} | awk '/#util> /' | sed '$ d' | awk '{$1="";$3="";$4="";print $0}' | sort -k2 -n | sed '/\/usr\/local\/bin\//d' && echo

  #cat ${my_path}/${bashlava_executable} | awk '/function /' | awk '{print $2}' | sort -k2 -n | sed '/App_/d' | sed '/main/d' | sed '/\/usr\/local\/bin\//d' | sed '/wip-/d'
  #If needed, you can list your add-on fct here as well. We don't list them by default to minimize cluter.
}

function shortner-url {
# output example: https://git.io/bashlava

# when no attributes are passed, use configs from the current project.
  if [[ "${input_2}" == "not-set" ]]; then
    App_Get_var_from_dockerfile
    input_2=${github_user}
    input_3=${app_name}
  fi

  App_Is_input_2
  App_Is_input_3

# generate URL
  clear
  curl -i https://git.io -F \
    "url=https://github.com/${input_2}/${input_3}" \
    -F "code=${input_3}" &&\

# see result
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
    my_message="bashLaVa is not tested on other machine than Darmin (Mac). Please let me know if you want to contribute." App_Warning
  else
    my_message="FATAL: Please open an issue for this behavior (err_f12)" App_Pink && App_Stop
  fi

  # will stop if a file is missing
  App_Are_files_existing

  echo &&\
  echo "App required on your local machine:" &&\
  App_Is_required_apps_installed

  echo &&\
  echo "Configs for this git repo:" &&\
  App_Get_var_from_dockerfile &&\
  my_message="${app_name} < app_name" App_Blue
  my_message="${app_version} < app_version" App_Blue
  my_message="${app_release} < app_release" App_Blue
  my_message="${github_user} < github_user" App_Blue
  my_message="${bashlava_executable} < bashlava_executable" App_Blue
  my_message="${my_path} < my_path" App_Blue
  my_message="${version_with_rc} < version_with_rc" App_Blue

  echo &&\
  my_message="This banner below confirm that your add-on is well configured:" App_Blue
  banner
}

function tag-read { 
  latest_tag="$(git describe --tags --abbrev=0)"
  my_message="${latest_tag} < tag version found on mainbranch" App_Blue
}
function status {
  git status
}

function version-read {
  App_Show_version_from_three_sources
}

function version-read-from-dockerfile {
  App_Get_var_from_dockerfile
  my_message="${app_version} < VERSION found in Dockerfile" App_Blue
  my_message="${app_release} < RELEASE found in Dockerfile" App_Blue
}
function help {
  figlet_message="bashLaVa" App_figlet
  help-main
  list
}

function continuous-integration-status {
# Valid for Github Actions CI. Usually the CI build our Dockerfiles
# while loop for 8 min
  MIN="1" MAX="300"
  for action in $(seq ${MIN} ${MAX}); do
    hub ci-status -v $(git rev-parse HEAD) && echo && sleep 5;
  done
}

function release-read {
# Find the latest version of any GitHub projects | usage: rr pascalandy docker-stack-this

# Find the latest version for THIS project
  if [[ "${input_2}" == "not-set" ]] && [[ "${input_3}" == "not-set" ]] ; then
    App_Get_var_from_dockerfile
# Find the latest version for ANY other projects
  elif [[ "${input_2}" != "not-set" ]] && [[ "${input_3}" != "not-set" ]] ; then
    github_user=${input_2}
    app_name=${input_3}
  else
    my_message="FATAL: Please open an issue for this behavior (err_f13)" App_Pink && App_Stop
  fi

  release_latest=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
    grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')

  my_message="${release_latest} < latest release found on https://github.com/${github_user}/${app_name}/releases/tag/${release_latest}" && App_Blue
}

#
  #
    #
      #
        #
          #
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# WIP work in progress
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

# see also:
#Duplicating a repository To duplicate a repository without forking it, 
# you can run a special clone command, then mirror-push to the new repository.
# https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/duplicating-a-repository

function rebase-theme {
# Syncing a fork, update from a forked
# wip-sync-origin-from-upstream

# CONTEXT
# In my case, it's useful as I paid for some Ghost templates.
# When a venfor updates his project, all I have is a zip file
# with the new code.
#
# TWO GIT REPOS
# Your fork is "origin". The repo you forked from is "upstream".
# 1) I maintain a themeX-from-vendor "origin" repo where I commit the code from the zip file.
# 2) I maintain a themeX-on-firepress "upstream" repo where I maintain the custom code.

### ### ### ### ### ### ### ### ###
# STEP #1
### ### ### ### ### ### ### ### ###
# go to edge branch
  git checkout edge &&\
# Add the remote, call it "upstream" (We do this only one time)
  git remote add upstream git@github.com:pascalandy/shoji-from-vendor.git &&\
  git remote -v &&\
# Fetch all the branches of that remote into remote-tracking branches,
# such as upstream/edge:
# pulls all new commits made to upstream/edge
  git fetch upstream &&\
  git pull upstream edge --allow-unrelated-histories &&\
# There are good chances that conflict might occur
  git diff --name-only --diff-filter=U

### ### ### ### ### ### ### ### ###
# STEP #2
### ### ### ### ### ### ### ### ###
# first, update these two
  git add CHANGELOG.md  # edit
  git add Dockerfile    # edit and dont update it from upstream!

# fix one file at a time
  git add fileYXZ   # optional, using add help us to know which files have been resolved
  git add fileYXZ   # optional, using add help us to know which files have been resolved
  git add fileYXZ   # optional, using add help us to know which files have been resolved

### ### ### ### ### ### ### ### ###
# STEP #3
### ### ### ### ### ### ### ### ###
# remove upstream as it will conflict with 'm,r'
  git remote remove upstream && git remote -v &&\

# Once all conflicts are resolved
  bashlava.sh c "Fixed conflicts / merged from 'nurui-from-vendor'"
}

#
  #
    #
      #
        #
          #
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# CHILD FUNCTIONS
# For BashLaVa, Apps are functions the user don't directly call
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function App_Changelog_Update {
  App_Is_mainbranch
  App_RemoveTmpFiles


# --- GENERATE LOGS / START
# get logs / raw format
  git_logs="$(git --no-pager log --abbrev-commit --decorate=short --pretty=oneline -n25 | \
    awk '/HEAD ->/{flag=1} /tag:/{flag=0} flag' | \
    sed -e 's/([^()]*)//g' | \
    awk '$1=$1')"

# copy logs in a file
  mkdir -pv ~/temp
  echo -e "${git_logs}" > ~/temp/tmpfile2

# --- Time to make the log pretty for the CHANGELOG

# find the number of line in this file
  number_of_lines=$(cat ~/temp/tmpfile2 | wc -l | awk '{print $1}')

  App_Get_var_from_dockerfile

# create URL for each hash commit
  for lineID in $(seq 1 ${number_of_lines}); do
    hash_to_replace=$(cat ~/temp/tmpfile2 | sed -n "${lineID},${lineID}p;" | awk '{print $1}')
    # create URLs from commits
      # Unlike Ubuntu, OS X requires the extension to be explicitly specified.
      # The workaround is to set an empty string --> ''
    sed -i '' "s/${hash_to_replace}/[${hash_to_replace}](https:\/\/github.com\/${github_user}\/${app_name}\/commit\/${hash_to_replace})/" ~/temp/tmpfile2
  done
# add space at the begining of line
  sed 's/^/ /' ~/temp/tmpfile2 > ~/temp/tmpfile3
# add sign "-" at the begining of line
  sed 's/^/-/' ~/temp/tmpfile3 > ~/temp/tmpfile4
# --- GENERATE LOGS / END


# --- GENERATE COMPARE URL / START
# create empty line
  echo -e "" >> ~/temp/tmpfile4

# find the latest tag on Github for this project
# Don't forget, 'release' will push the newest a big later. That's this tag is second_latest_tag
  second_latest_tag=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
    grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')

  echo -e "### 🔍 Compare" >> ~/temp/tmpfile4
  echo -e "- ... with previous release: [${second_latest_tag} <> ${app_release}](https://github.com/${github_user}/${app_name}/compare/${second_latest_tag}...${app_release})" >> ~/temp/tmpfile4
# --- GENERATE COMPARE URL / END

# start and create changelog updates
  echo -e "" > ~/temp/tmpfile
# insert H2 title version
  echo -e "## ${app_release} (${date_day})" >> ~/temp/tmpfile
# insert H3 Updates
  echo -e "### ⚡️ Updates" >> ~/temp/tmpfile
# insert commits
  cat ~/temp/tmpfile4 >> ~/temp/tmpfile


# Insert our release notes after pattern "# Release"
  bottle="$(cat ~/temp/tmpfile)"
# VERY IMPORTANT: we allign our updates under the title Release.
# We must keep our template intacts for this reason.
  awk -vbottle="$bottle" '/# Releases/{print;print bottle;next}1' CHANGELOG.md > ~/temp/tmpfile
  cat ~/temp/tmpfile | awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' > CHANGELOG.md
  App_RemoveTmpFiles && echo &&\

  if [[ "${_flag_bypass_changelog_prompt}" == "false" ]]; then
    nano CHANGELOG.md && echo
  elif [[ "${_flag_bypass_changelog_prompt}" == "true" ]]; then
    echo "Do not prompt" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (err_f14)" App_Pink && App_Stop
  fi
}

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
  else
    my_message="You must be on <${default_branch}> branch to perform this action (ERR5681)" App_Pink
  fi
}
function App_Is_edge {
  currentBranch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "${currentBranch}" == "edge" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [[ "${currentBranch}" != "edge" ]]; then
    my_message="You must be on <edge> branch to perform this action (ERR5682)" App_Pink && App_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (err_f15)" App_Pink && App_Stop
  fi
}

function App_Is_commit_unpushed {
  if [[ $(git status | grep -c "nothing to commit") == "1" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [[ $(git status | grep -c "nothing to commit") != "1" ]]; then
    my_message="You must push your commit(s) before doing this action (ERR5683)" App_Pink && App_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (err_f16)" App_Pink && App_Stop
  fi
}

function App_Is_input_2 {
# ensure the second attribute is not empty to continue
  if [[ "${input_2}" == "not-set" ]]; then
    my_message="You must provide two attributes. See help (ERR5687)" App_Pink
    App_Stop
  elif [[ "${input_2}" != "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (err_f17)" App_Pink && App_Stop
  fi
}
function App_Is_input_3 {
# ensure the third attribute is not empty to continue
  if [[ "${input_3}" == "not-set" ]]; then
    my_message="You must provide three attributes. See help (ERR5688)" App_Pink
    App_Stop
  elif [[ "${input_3}" != "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (err_f18a)" App_Pink && App_Stop
  fi
}

function App_Is_input_2_empty_as_it_should {
# Stop if 2 attributes are passed.
  if [[ "${input_2}" != "not-set" ]]; then
      my_message="You cannot use two attributes for this function. See help (ERR5721)" App_Pink && App_Stop
  elif [[ "${input_2}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (err_f18c)" App_Pink && App_Stop
  fi
}
function App_Is_input_3_empty_as_it_should {
# Stop if 3 attributes are passed.
  if [[ "${input_3}" != "not-set" ]]; then
      my_message="You cannot use three attributes for this function. See help (ERR5721)" App_Pink && App_Stop
  elif [[ "${input_3}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (err_f18c)" App_Pink && App_Stop
  fi
}
function App_Is_Input_4_empty_as_it_should {
# Stop if 4 attributes are passed.
  if [[ "${input_4}" != "not-set" ]]; then
      my_message="You cannot use four attributes with BashLava. See help (ERR5721)" App_Pink && App_Stop
  elif [[ "${input_4}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (err_f18d)" App_Pink && App_Stop
  fi
}

function App_Is_version_syntax_valid {
# Version is limited to these characters: 1234567890.rR-
# so we can do: '3.5.13-r3' or '3.5.13-rc3'
  ver_striped=$(echo "${input_2}" | sed 's/[^0123456789.rcRC\-]//g')

  if [[ "${input_2}" == "${ver_striped}" ]]; then
    echo "Version is valid, lets continue" > /dev/null 2>&1
  elif [[ "${input_2}" != "${ver_striped}" ]]; then
    my_message="The version format is not valid (ERR5731)" App_Pink && App_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (err_f19)" App_Pink && App_Stop
  fi
}

function App_Are_files_existing {
# --- 1)
  if [ -f CHANGELOG.md ] || [ -f CHANGELOG_template.md ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f CHANGELOG.md ] || [ ! -f CHANGELOG_template.md ]; then
    my_message="CHANGELOG.md file does not exit (WAR5684). Let's generate one:" App_Warning && init_changelog && App_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (err_f20)" App_Pink && App_Stop
  fi
# --- 2)
  if [ -f Dockerfile ] || [ -f Dockerfile_template ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f Dockerfile ] || [ ! -f Dockerfile_template ]; then
    my_message="Dockerfile does not exit (WAR5685). Let's generate one:" App_Warning && init_dockerfile && App_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (err_f21)" App_Pink && App_Stop
  fi
# --- 3)
  if [ -f .gitignore ] || [ -f .gitignore_template ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f .gitignore ] || [ ! -f .gitignore_template ]; then
    my_message=".gitignore file does not exit. Let's generate one (WAR5686)" App_Warning && init_gitignore && App_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (err_f22)" App_Pink && App_Stop
  fi
# --- 4)
  if [ -f LICENSE ] || [ -f LICENSE_template ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f LICENSE ] || [ ! -f LICENSE_template ]; then
    my_message="LICENSE file does not exit. Let's generate one (WAR5687)" App_Warning && init_license && App_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (err_f23)" App_Pink && App_Stop
  fi
# --- 5)
  if [ -f README.md ] || [ -f README_template.md ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -f README.md ] || [ ! -f README_template.md ]; then
    my_message="README.md file does not exit. Let's generate one (WAR5688)" App_Warning && init_readme && App_Stop && echo
  else
    my_message="FATAL: Please open an issue for this behavior (err_f24)" App_Pink && App_Stop
  fi
# --- 6)
  if [ -d .git ]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [ ! -d .git ]; then
    my_message="This is not a git repo (WAR5689)" App_Warning && App_Stop
  else
    my_message="FATAL: Please open an issue for this behavior (err_f25)" App_Pink && App_Stop
  fi
# --- 7)
  # 'init_dockerfile_ignore' is optional as not everyone needs this option
}

function App_Is_required_apps_installed {
# hub
  if [[ $(hub version | grep -c "hub version") == "1" ]]; then
    my_message="Hub is installed." App_Blue
  elif [[ $(hub version | grep -c "hub version") != "1" ]]; then
    echo && my_message="Hub is not installed. See requirements https://git.io/bashlava" App_Pink &&\
    open https://git.io/bashlava
  else
    my_message="FATAL: Please open an issue for this behavior (err_f26)" App_Pink && App_Stop
  fi
# docker
  if [[ $(docker version | grep -c "Docker Engine - Community") == "1" ]]; then
    my_message="$(docker --version) is installed." App_Blue
  elif [[ $(docker version | grep -c "Docker Engine - Community") != "1" ]]; then
    my_message="Docker is not running. https://github.com/firepress-org/bash-script-template#requirements" App_Warning
  else
    my_message="FATAL: Please open an issue for this behavior (err_f27)" App_Pink && App_Stop
  fi
}

function App_release_check_vars {
  if [[ -z "${app_name}" ]]; then
    my_message="ERROR: app_name is empty (ERR5691)" App_Pink App_Stop
  elif [[ -z "${app_version}" ]]; then
    my_message="ERROR: app_version is empty (ERR5692)" App_Pink App_Stop
  elif [[ -z "${app_release}" ]]; then
    my_message="ERROR: app_release is empty (ERR5692)" App_Pink App_Stop
  elif [[ -z "${git_repo_url}" ]]; then
    my_message="ERROR: git_repo_url is empty (ERR5693)" App_Pink App_Stop
  elif [[ -z "${release_message1}" ]]; then
    my_message="ERROR: release_message1 is empty (ERR5694)" App_Pink App_Stop
  elif [[ -z "${release_message2}" ]]; then
    my_message="ERROR: release_message2 is empty (ERR5695)" App_Pink App_Stop
  fi

  url_to_check=${git_repo_url}
  App_Curlurl
}

function App_Curlurl {
# must receive var: url_to_check
  UPTIME_TEST=$(curl -Is ${url_to_check} | grep -io OK | head -1);
  MATCH_UPTIME_TEST1="OK";
  MATCH_UPTIME_TEST2="ok";
  if [ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST1" ] || [ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST2" ]; then
    my_message="${url_to_check} <== is online" App_Green
  elif [ "$UPTIME_TEST" != "$MATCH_UPTIME_TEST1" ] || [ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST2" ]; then
    my_message="${url_to_check} <== is offline" App_Pink
    my_message="The git up repo is not responding as expected :-/" App_Pink && sleep 5
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
  github_registery=$(cat Dockerfile | grep GITHUB_REGISTRY= | head -n 1 | grep -o '".*"' | sed 's/"//g')

  # needed for `fct tag`
  url_to_release="https://github.com/${github_user}/${app_name}/releases/new"

  # Validate vars are not empty
  if [[ -z "${app_name}" ]] ; then    #if empty
    clear
    my_message="Can't find variable APP_NAME in the Dockerfile (ERR5481)" App_Pink && App_Stop
  elif [[ -z "${app_version}" ]] ; then    #if empty
    clear
    my_message="Can't find variable VERSION in the Dockerfile (ERR5482)" App_Pink && App_Stop
  elif [[ -z "${app_release}" ]] ; then    #if empty
    clear
    my_message="Can't find variable RELEASE in the Dockerfile (ERR5483)" App_Pink && App_Stop
  elif [[ -z "${github_user}" ]] ; then    #if empty
    clear
    my_message="Can't find variable GITHUB_USER in the Dockerfile (ERR5484)" App_Pink && App_Stop
  elif [[ -z "${default_branch}" ]] ; then    #if empty
    clear
    my_message="Can't find variable DEFAULT_BRANCH in the Dockerfile (ERR5485)" App_Pink && App_Stop
  elif [[ -z "${github_org}" ]] ; then    #if empty
    clear
    my_message="Can't find variable GITHUB_ORG in the Dockerfile (ERR5486)" App_Pink && App_Stop
  elif [[ -z "${dockerhub_user}" ]] ; then    #if empty
    clear
    my_message="Can't find variable DOCKERHUB_USER in the Dockerfile (ERR5487)" App_Pink && App_Stop
  elif [[ -z "${github_registery}" ]] ; then    #if empty
    clear
    my_message="Can't find variable GITHUB_REGISTRY in the Dockerfile (ERR5488)" App_Pink && App_Stop
  fi
}

function App_Show_version_from_three_sources {
# Read the version from three sources
  if [[ "${input_2}" == "not-set" ]]; then
    my_message="Three version checkpoints:" && App_Blue &&\
    version-read-from-dockerfile &&\
    tag-read &&\
    release-read && echo
  fi
}

function App_figlet {
  docker run --rm ${docker_img_figlet} ${figlet_message}
}

function App_glow50 {
# markdown viewer for your terminal. Better than cat!
  docker run --rm -it \
    -v $(pwd):/sandbox \
    -w /sandbox \
    ${docker_img_glow} glow ${input_2} | sed -n 12,50p # show the first 60 lines
}

function App_glow {
  docker run --rm -it \
    -v $(pwd):/sandbox \
    -w /sandbox \
    ${docker_img_glow} glow ${input_2}
}

function App_Pink { echo -e "${col_pink} ERROR: ${my_message}"
}
function App_Warning { echo -e "${col_pink} Warning: ${my_message}"
}
function App_Blue { echo -e "${col_blue} ${my_message}"
}
function App_Green { echo -e "${col_green} ${my_message}"
}
function App_Stop { echo -e "${col_pink} exit 1" && echo && exit 1
}

#
  #
    #
      #
        #
          #
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
    my_message="FATAL: Please open an issue for this behavior (err_f29)" App_Pink && App_Stop
  fi
}

function App_DefineVariables {
# Hardcoded VAR
# Default var & path. Customize if need. Usefull if you want
# to have multiple instance of bashLaVa on your machine
  bashlava_executable="bashlava.sh"
  my_path="/usr/local/bin"

# Hardcoded VAR
# Does this app accept release candidates (ie. 3.5.1-rc1) in the _version? By default = false
# When buidling docker images it better to not have rc in the version as breaks the pattern.
# When not working with a docker build, feel free to put this flag as true.
# default value is false
  version_with_rc="false"

# Reset if needed
  App_Reset_Custom_path
  _bashlava_path="$(cat ${my_path}/bashlava_path)"

# Set absolute path for the add-on scripts
  local_bashlava_addon_path="${_bashlava_path}/add-on"

# every scripts that are not under the main bashLaVa app, should be threated as an add-on.
# It makes it easier to maintain the project, it minimises cluter, it minimise break changes, it makes it easy to accept PR, more modular, etc.
  source "${local_bashlava_addon_path}/help.sh"
  source "${local_bashlava_addon_path}/alias.sh"
  source "${local_bashlava_addon_path}/examples.sh"
  source "${local_bashlava_addon_path}/templates.sh"
  source "${local_bashlava_addon_path}/utilities.sh"

# load your custom script in there:
  source "${local_bashlava_addon_path}/custom_scripts_entrypoint.sh"

# Set defaults for flags
  _flag_bypass_changelog_prompt="false"
  _flag_deploy_commit_message="not-set"
  _commit_message="not-set"

#	docker images
  docker_img_figlet="devmtl/figlet:1.1"
  docker_img_glow="devmtl/glow:0.3.0"

#	Define color for echo prompts:
  export col_std="\e[39m——>\e[39m"
  export col_grey="\e[39m——>\e[39m"
  export col_blue="\e[34m——>\e[39m"
  export col_pink="\e[35m——>\e[39m"
  export col_green="\e[36m——>\e[39m"
  export col_white="\e[97m——>\e[39m"
  export col_def="\e[39m"

#	Date generators
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

# ENTRYPOINT
function main() {

  trap script_trap_err ERR
  trap script_trap_exit EXIT
  source "$(dirname "${BASH_SOURCE[0]}")/.bashcheck.sh"

# Load variables
  App_DefineVariables

# Set empty attribute. The user must provide 1 to 3 attributes
  input_1=$1
  if [[ -z "$1" ]]; then    #if empty
    clear
    help
  else
    input_1=$1
  fi

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

# Load functions via .bashcheck.sh
  script_init "$@"
  cron_init
  colour_init

# Ensure there are no more than three attrbutes
  App_Is_Input_4_empty_as_it_should

### optional
  # lock_init system

### optionnal Trace the execution of the script to debug (if needed)
  # set -o xtrace

# ToDo: Add logic to confirm the function exist or not | tk
  clear
  $1
}

main "$@"
echo
