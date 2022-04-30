#!/usr/bin/env bash

function mainbranch {
  App_Is_edge
  App_Is_commit_unpushed
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
  git branch -D edge || true
  # delete branch so there is no need to use the github GUI to delete it
  git push origin --delete edge || true

  git checkout -b edge
  git push --set-upstream origin edge -f
  my_message="<edge> was freshly branched out from ${default_branch}" App_Blue
}

# TODO App_Compare_If_Two_Var_Are_Equals
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
  echo && my_message="Next step: 'commits' OR 'pr' " App_Green
}

function pr {
  App_Is_edge
  App_Is_input_2_empty_as_it_should
  App_Is_commit_unpushed

  _pr_title=$(git log --format=%B -n 1 $(git log -1 --pretty=format:"%h") | cat -)
  _var_name="_pr_title" _is_it_empty=$(echo ${_pr_title}) && App_Does_Var_Empty
  
  gh pr create --fill --title "${_pr_title}" --base "${default_branch}" &&\
  gh pr view --web
  echo && my_message="Next step: check 'ci' OR 'mrg' " App_Green
  # if needed check ./docs/pr_upstream_issues.md
}

function ci {
  # continuous integration status
  App_Is_input_2_empty_as_it_should &&\
  App_Is_commit_unpushed &&\
  gh run list && sleep 2
  
  _run_id=$(gh run list | head -1 | awk '{print $12}')
  _check_var="_run_id" && App_Does_Var_Empty

  open https://github.com/${github_user}/${app_name}/actions/runs/${run_id}
  echo && my_message="Next step: 'mrg' " App_Green
  #gh run watch
}

function mrg {
  # merge from edge into main_branch
  App_Is_edge
  App_Is_commit_unpushed

  input_2="./docs/mrg_info.md" file_path_is="${input_2}" && App_Does_File_Exist && App_glow

  gh pr merge
  App_Show_version
  echo && my_message="Next step: 'version' " App_Green
}

function version {
# The version is stored within the Dockerfile. For BashLaVa, this Dockerfile is just a config-env file

  App_Is_commit_unpushed
  App_Is_input_2
  App_Is_version_syntax_valid

  _var_name="version_with_rc" _is_it_empty=$(echo ${version_with_rc}) && App_Does_Var_Empty

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
    my_message="FATAL: fct version" && App_Fatal
  fi

# apply updates
  sed -i '' "s/^ARG VERSION=.*$/ARG VERSION=\"${version_trim}\"/" Dockerfile
  sed -i '' "s/^ARG RELEASE=.*$/ARG RELEASE=\"${input_2}\"/" Dockerfile

  git add .
  git commit . -m "Update ${app_name} to version ${app_release} /Dockerfile"
  git push && echo
  App_Show_version && sleep 1
  log

  echo && my_message="Next step: 'tag' " App_Green
}

function tag {
  git tag ${app_release} && git push --tags && echo &&\
  App_Show_version && sleep 1 && echo &&\

  my_message="Next, prepare release" App_Green &&\
  my_message="To quit the release notes: type ':qa + enter'" App_Warning && echo
  gh release create && sleep 4

  App_Show_version
  App_Show_release
  echo && my_message="Next step: 'edge' " App_Green
}

function squash {
  App_Is_commit_unpushed
  App_Is_input_2 # how many steps
  App_Is_input_3 # message

  if ! [[ $input_2 =~ ^[0-9]+$ ]] ; then
    my_message="Syntax error" && App_Fatal
  fi

  git reset --hard HEAD~"${input_2}"
  git merge --squash HEAD@{1}
  git push origin HEAD --force
  git status
  git add -A
  git commit -m "${input_3} /sq"
  git push
  log
}

function test {
# test our script & fct. Idempotent bash script

  help 

  figlet_message="bashLaVa" && App_figlet

  my_message="Attributes:" App_Blue
  my_message="\$1 value is: ${input_1}" App_Gray
  my_message="\$2 value is: ${input_2}" App_Gray
  my_message="\$3 value is: ${input_3}" App_Gray
  my_message="\$4 value is: ${input_4}" App_Gray

  echo
  my_message="OS:" App_Blue
  if [[ $(uname) == "Darwin" ]]; then
    my_message="Running on a Mac (Darwin)" App_Gray
  elif [[ $(uname) != "Darwin" ]]; then
    my_message="bashLaVa is not tested on other machine than Darmin (Mac). Please let me know if you want to contribute (WARN_901)." && App_Warning
  else
    my_message="FATAL: Please open an issue for this behavior (Darmin (Mac)" && App_Fatal
  fi

  echo
  my_message="App required on your local machine:" App_Blue
  App_Is_required_apps_installed
  my_message="All good!" App_Gray

  echo
  my_message="Check files and directories:" App_Blue
  App_Check_Are_Files_Exist
  my_message="All good!" App_Gray

  echo
  my_message="Check versions:" App_Blue
  App_Show_version
  
  echo
  my_message="Configs for this git repo:" App_Blue
  my_message="${app_name} < app_name" App_Gray
  my_message="${app_version} < app_version" App_Gray
  my_message="${app_release} < app_release" App_Gray
  my_message="${github_user} < github_user" App_Gray
  my_message="${default_branch} < default_branch" App_Gray
  my_message="${github_org} < github_org" App_Gray
  my_message="${dockerhub_user} < dockerhub_user" App_Gray
  my_message="${github_registry} < github_registry" App_Gray
  my_message="${bashlava_executable} < bashlava_executable" App_Gray
  my_message="${my_path} < my_path" App_Gray

  echo
  my_message="Test entrypoint:" App_Blue
  array

  echo && my_message="Test banner:" && App_Blue
  banner

  my_message="Test colors option for echo:" && App_Gray
  test_color
}

function test_color {
  my_message="Test my color"
  App_Green
  App_Blue
  App_Warning
  App_Gray
  App_Fatal
}

function status {
  git status -s && echo &&\
  git diff --color-words
}

function help {
  App_Is_input_3_empty_as_it_should
  input_2="./docs/dev_workflow.md" file_path_is="${input_2}" && App_Does_File_Exist && App_glow
  input_2="./docs/release_workflow.md" file_path_is="${input_2}" && App_Does_File_Exist && App_glow
  input_2="./docs/more_commands.md" file_path_is="${input_2}" && App_Does_File_Exist && App_glow

  ### old code that could be useful in the future
  ### list tag #util> within the code
  # cat ${my_path}/${bashlava_executable} | awk '/#util> /' | sed '$ d' | awk '{$1="";$3="";$4="";print $0}' | sort -k2 -n | sed '/\/usr\/local\/bin\//d' && echo
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

function App_short_url {

### CMD EXECUTION
  function sub_short_url {
  clear
  curl -i https://git.io -F \
    "url=https://github.com/${input_2}/${input_3}" \
    -F "code=${input_3}" &&\

### PREVIEW
  echo && my_message="Let's open: https://git.io/${input_3}" && App_Blue && sleep 2 &&\
  open https://git.io/${input_3}
  }

  echo
  my_message="URL ........ : https://git.io/${app_name}" && App_Gray
  my_message="will point to: https://github.com/${github_user}/${app_name}" && App_Gray
  #output example: https://git.io/bashlava

### PROMPT CONFIRMATION
  echo
  my_message="Do you want to continue? (y/n)" && App_Gray
  read user_input;
  case ${user_input} in
    y | Y) sub_short_url;;
    *) my_message="Operation cancelled" && App_Fatal;;
  esac
}

function App_Is_mainbranch {
  _compare_to_me=$(git rev-parse --abbrev-ref HEAD)
  _compare_to_you="${default_branch}" _fct_is="App_Is_mainbranch"
  App_Compare_If_Two_Var_Are_Equals
}

function App_Is_edge {
  _compare_to_me=$(git rev-parse --abbrev-ref HEAD)
  _compare_to_you="edge" _fct_is="App_Is_edge"
  App_Compare_If_Two_Var_Are_Equals
}

function App_Is_commit_unpushed {
  _compare_to_me=$(git status | grep -c "nothing to commit")
  _compare_to_you="1" _fct_is="App_Is_commit_unpushed"
  App_Compare_If_Two_Var_Are_Equals
}

# TODO refactor this function
function App_Is_input_2 {
### ensure the second attribute is not empty to continue
  if [[ "${input_2}" == "not-set" ]]; then
    my_message="You must provide two attributes. See help (WARN_109)" && App_Warning_Stop
  elif [[ "${input_2}" != "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_110)" && App_Fatal
  fi
}

function App_Is_input_3 {
### ensure the third attribute is not empty to continue
  if [[ "${input_3}" == "not-set" ]]; then
    my_message="You must provide three attributes. See help (WARN_111)" && App_Warning_Stop
  elif [[ "${input_3}" != "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_112)" && App_Fatal
  fi
}

# TODO new fct not equal
function App_Is_input_2_empty_as_it_should {
### Stop if 2 attributes are passed.
  if [[ "${input_2}" != "not-set" ]]; then
      my_message="You cannot use two attributes for this fct (WARN_113)" && App_Warning_Stop
  elif [[ "${input_2}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_114)" && App_Fatal
  fi
}

function App_Is_input_3_empty_as_it_should {
# Stop if 3 attributes are passed.
  if [[ "${input_3}" != "not-set" ]]; then
      my_message="You cannot use three attributes for this fct. See help (ERR_115)" && App_Warning_Stop
  elif [[ "${input_3}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_116)" && App_Fatal
  fi
}
function App_Is_Input_4_empty_as_it_should {
# Stop if 4 attributes are passed.
  if [[ "${input_4}" != "not-set" ]]; then
      my_message="You cannot use four attributes with BashLava (WARN_117)" && App_Warning && echo
  elif [[ "${input_4}" == "not-set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: Please open an issue for this behavior (ERR_118)" && App_Fatal
  fi
}

function App_Is_version_syntax_valid {
  # Version is limited to these characters: 1234567890.rR-
  # so we can do: '3.5.13-r3' or '3.5.13-rc3'
  _compare_to_me=$(echo "${input_2}" | sed 's/[^0123456789.rcRC\-]//g')
  _compare_to_you="${input_2}" _fct_is="App_Is_version_syntax_valid"
  App_Compare_If_Two_Var_Are_Equals
}

function App_Is_required_apps_installed {
# is docker running?
  _compare_to_me=$(docker version | grep -c "Server: Docker Desktop")
  _compare_to_you="1" _fct_is="App_Is_required_apps_installed"
  App_Compare_If_Two_Var_Are_Equals

# id gh cli running ?
# does not work, see https://github.com/firepress-org/bashlava/issues/31
# if [[ $(gh auth status | grep -c "Logged in to github.com as") == "1" ]]; ...
}

function App_Check_Are_Files_Exist {

  arr=( "case_what_do_you_want" "dev_workflow" "more_commands" "pr_upstream_issues" "release_workflow" )
  for input_2 in "${arr[@]}"; do
    file_path_is="./docs/${input_2}.md" && App_Does_File_Exist
  done

  file_is="LICENSE" file_path_is="${_bashlava_path}/${file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && init_gitignore && exit 1
  fi

  file_is="README.md" file_path_is="${_bashlava_path}/${file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && init_gitignore && exit 1
  fi

  file_is=".dockerignore" file_path_is="${_bashlava_path}/${file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && init_gitignore && exit 1
  fi

  file_is=".gitignore" file_path_is="${_bashlava_path}/${file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && init_gitignore && exit 1
  fi

  file_is="Dockerfile" file_path_is="${_bashlava_path}/${file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && init_dockerfile && exit 1
  fi

  file_is=".git" dir_path_is="${_bashlava_path}/${file_is}" && App_Does_Directory_Exist
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message=".git directory does not exit" && App_Fatal
  fi
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

function App_Load_variables {

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

### source PUBLIC scripts
file_is="templates.sh"
  file_path_is="${local_bashlava_addon_path}/${file_is}"
  App_Does_File_Exist
  source "${file_path_is}"

file_is="alias.sh"
  file_path_is="${local_bashlava_addon_path}/${file_is}"
  App_Does_File_Exist
  source "${file_path_is}"

### source PRIVATE / custom scripts
# the user must create /private/_entrypoint.sh file
file_is="_entrypoint.sh"
  file_path_is="${local_bashlava_addon_path}/private/${file_is}"
  App_Does_File_Exist
  source "${file_path_is}"

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

  date_hour="$(date +%Y-%m-%d_%HH)XX"
    date_day="$(date +%Y-%m-%d)"
  date_month="$(date +%Y-%m)-XX"
  date_year="$(date +%Y)-XX-XX"

# Define vars from Dockerfile
  app_name=$(cat Dockerfile | grep APP_NAME= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  app_version=$(cat Dockerfile | grep VERSION= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  app_release=$(cat Dockerfile | grep RELEASE= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_user=$(cat Dockerfile | grep GITHUB_USER= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  default_branch=$(cat Dockerfile | grep DEFAULT_BRANCH= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_org=$(cat Dockerfile | grep GITHUB_ORG= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  dockerhub_user=$(cat Dockerfile | grep DOCKERHUB_USER= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_registry=$(cat Dockerfile | grep GITHUB_REGISTRY= | head -n 1 | grep -o '".*"' | sed 's/"//g')

  _url_to_release="https://github.com/${github_user}/${app_name}/releases/new"
  _url_to_check="https://github.com/${github_user}/${app_name}"

# idempotent checkpoints
  _var_name="app_name" _is_it_empty=$(echo ${app_name}) && App_Does_Var_Empty
  _var_name="app_version" _is_it_empty=$(echo ${app_version}) && App_Does_Var_Empty
  _var_name="app_release" _is_it_empty=$(echo ${app_release}) && App_Does_Var_Empty
  _var_name="github_user" _is_it_empty=$(echo ${github_user}) && App_Does_Var_Empty
  _var_name="default_branch" _is_it_empty=$(echo ${default_branch}) && App_Does_Var_Empty
  _var_name="github_org" _is_it_empty=$(echo ${github_org}) && App_Does_Var_Empty
  _var_name="dockerhub_user" _is_it_empty=$(echo ${dockerhub_user}) && App_Does_Var_Empty
  _var_name="github_registry" _is_it_empty=$(echo ${github_registry}) && App_Does_Var_Empty
  _var_name="_url_to_release" _is_it_empty=$(echo ${_url_to_release}) && App_Does_Var_Empty
  _var_name="_url_to_check" _is_it_empty=$(echo ${_url_to_check}) && App_Does_Var_Empty
}

# TODO App_Compare_If_Two_Var_Are_Equals
# TODO logic '"${input_2}" == "not-set"' prevent to call it from test

function App_Show_version {
# Show version from three sources
  if [[ "${input_2}" == "not-set" ]]; then
    echo && my_message="Version checkpoints:" && App_Blue &&\
### dockerfile
    my_message="${app_version} < VERSION in Dockerfile" App_Gray
    my_message="${app_release} < RELEASE in Dockerfile" App_Gray
### tag
    latest_tag="$(git describe --tags --abbrev=0)"
    _var_name="latest_tag" _is_it_empty=$(echo ${latest_tag}) && App_Does_Var_Empty
    my_message="${latest_tag} < TAG on mainbranch" App_Gray
### release
    release_latest=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
      grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')
    _var_name="release_latest" _is_it_empty=$(echo ${release_latest}) && App_Does_Var_Empty
    my_message="${release_latest} < RELEASE on https://github.com/${github_user}/${app_name}/releases/tag/${release_latest}" && App_Gray && echo
  fi
}

function App_Show_release {
  release_latest=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
    grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')
  _var_name="release_latest" _is_it_empty=$(echo ${release_latest}) && App_Does_Var_Empty
  open "https://github.com/${github_user}/${app_name}/releases/tag/${release_latest}"
}


function App_figlet {
  _var_name="docker_img_figlet" _is_it_empty=$(echo ${docker_img_figlet}) && App_Does_Var_Empty
  _var_name="figlet_message" _is_it_empty=$(echo ${figlet_message}) && App_Does_Var_Empty
  docker run --rm ${docker_img_figlet} ${figlet_message}
}

function App_glow {
  _var_name="docker_img_glow" _is_it_empty=$(echo ${docker_img_glow}) && App_Does_Var_Empty
  _var_name="input_2" _is_it_empty=$(echo ${input_2}) && App_Does_Var_Empty
  docker run --rm -it -v $(pwd):/sandbox -w /sandbox ${docker_img_glow} glow -w 120 ${input_2}
}

# Define colors / https://www.shellhacks.com/bash-colors/
function App_Green {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "\e[1;32m${my_message}\e[0m"
                                # green
}
function App_Blue {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "\e[1;34m${my_message}\e[0m"
                                # green
}
function App_Warning {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "\e[1;33m${my_message}\e[0m"
                                # yellow
}
function App_Gray {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "\e[1;37m${my_message}\e[0m"
}
function App_Warning_Stop {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "\e[1;33m${my_message}\e[0m" && exit 1
                                # yellow
}
function App_Fatal {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "\e[1;31m${my_message}\e[0m" && exit 1
                                # red
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

function App_Does_File_Exist {
  if [[ -f "${file_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -f "${file_path_is}" ]]; then
    my_message="Warning: no file: ${file_path_is}" && App_Warning_Stop
  else
    my_message="Fatal error: ${file_path_is}" && App_Fatal
  fi
}

# This fct return the flag '_file_do_not_exist'
function App_Does_File_Exist_NoStop {
  if [[ -f "${file_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -f "${file_path_is}" ]]; then
    my_message="Warning: no file: ${file_path_is}" && App_Warning
    _file_do_not_exist="true"
  else
    my_message="Fatal error: ${file_path_is}" && App_Fatal
  fi
}

function App_Compare_If_Two_Var_Are_Equals {
  if [[ "${_compare_to_me}" == "${_compare_to_you}" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [[ "${_compare_to_me}" != "${_compare_to_you}" ]]; then
    my_message="Checkpoint failed '${_fct_is}' ( ${_compare_to_me} and ${_compare_to_you} )" && App_Warning_Stop
  else
    my_message="FATAL — ${_fct_is}" && App_Fatal
  fi
}

function App_Does_Var_Empty {
  # source must send two vars:_is_it_empty AND _var_name
  if [[ -n "${_is_it_empty}" ]]; then    #if not empty
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ -z "${_is_it_empty}" ]]; then    #if empty
    my_message="Warning: variable '${_var_name}' is empty" && App_Warning_Stop
  else
    my_message="Fatal error: '${_var_name}'" && App_Fatal
  fi
}

# This fct return the flag '_file_do_not_exist'
function App_Does_Directory_Exist {
  if [[ -d "${dir_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -d "${dir_path_is}" ]]; then
    my_message="Warning: no directory: ${dir_path_is}" && App_Warning_Stop
  else
    my_message="Fatal error: ${dir_path_is}" && App_Fatal
  fi
}

### Entrypoint
function main() {
  trap script_trap_err ERR
  trap script_trap_exit EXIT
  source "$(dirname "${BASH_SOURCE[0]}")/.bashcheck.sh"

  App_Load_variables

  if [[ -z "$2" ]]; then    #if empty
    input_2="not-set"
  elif [[ ! -z "$2" ]]; then    #if empty
    input_2=$2
  else
    my_message="Fatal error: 'input_2'" && App_Fatal
  fi

  if [[ -z "$3" ]]; then    #if empty
    input_3="not-set"
  elif [[ ! -z "$3" ]]; then    #if empty
    input_3=$3
  else
    my_message="Fatal error: 'input_3'" && App_Fatal
  fi

  if [[ -z "$4" ]]; then    #if empty
    input_4="not-set"
  elif [[ ! -z "$4" ]]; then    #if empty
    input_4=$4
  else
    my_message="Fatal error: 'input_4'" && App_Fatal
  fi

### Load fct via .bashcheck.sh
  script_init "$@"
  cron_init
  colour_init

### Ensure there are no more than three attrbutes
  App_Is_Input_4_empty_as_it_should

### optional
  # lock_init system

### optionnal Trace the execution of the script to debug (if needed)
  # set -o xtrace

###'command not found' / Add logic to confirm the fct exist or not
  #clear
  $1
}

main "$@"

### If the user does not provide any argument, let offer options
input_1=$1
if [[ -z "$1" ]]; then

  input_2="./docs/case_what_do_you_want.md" && clear && App_glow
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
