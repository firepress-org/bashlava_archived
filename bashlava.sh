#!/usr/bin/env bash

# See bashlava for all details https://github.com/firepress-org/bashlava

# There are: 0o0o TODO

# TODO
#fct: m
#	CASE ask if the user wants 'e'

# TODO
# better management core vars

# TODO
# manage private vars https://github.com/firepress-org/bashlava/issues/83

# TODO
### App check brew + git-crypt + gnupg
#if brew ls --versions myformula > /dev/null; then
   # The package is installed
#else
   # The package is not installed
#fi

function mainbranch {
  App_input_2_Is_Empty_As_It_Should
  Condition_No_Commits_Must_Be_Pending
  Condition_Apps_Must_Be_Installed
  App_Is_edge

  App_Show_Version

### Update our local state
  git checkout ${default_branch}
  git pull origin ${default_branch}
  echo
  log
}

function edge {
# TODO
# have this branch created with a unique ID to avoid conflicts with other developers edge_sunny

### it assumes there will be no conflict with anybody else
### as I'm the only person using 'edge'.
  App_input_2_Is_Empty_As_It_Should       # fct without attributs
  Condition_No_Commits_Must_Be_Pending
  Condition_Apps_Must_Be_Installed

### delete branch
  git branch -D edge || true

### delete branch so there is no need to use the github GUI to delete it
# TODO
# check if branch edge exist (more slick)
  git push origin --delete edge || true

  git checkout -b edge
  git push --set-upstream origin edge -f
  App_Show_Version
  # UX fun
  my_message="<edge> was freshly branched out from ${default_branch}" App_Blue
  echo && my_message="NEXT MOVE suggestion: code something and 'c' " App_Green
}

function commit {
  App_Is_input_2_Provided
  git status
  git add -A
  git commit -m "${input_2}"
  git push
  # UX fun
  echo && my_message="NEXT MOVE suggestion: 'c' - 'pr' " App_Green
}

function pr {
### see pr_upstream_issues.md to debug merging
  App_Is_edge
  App_input_2_Is_Empty_As_It_Should
  Condition_No_Commits_Must_Be_Pending

  _pr_title=$(git log --format=%B -n 1 $(git log -1 --pretty=format:"%h") | cat -)
  _var_name="_pr_title" _is_it_empty=$(echo ${_pr_title}) && App_Does_Var_Empty
  
  gh pr create --fill --title "${_pr_title}" --base "${default_branch}"
  gh pr view --web

### PROMPT
  echo
  my_message="Do you want to see CI status? (y/n)" && App_Blue
  read user_input;
  case ${user_input} in
    y | Y) ci;;
    *) my_message="Operation cancelled" && App_Fatal;;
  esac

  # UX fun
  echo && my_message="NEXT MOVE suggestion: 'ci' - 'mrg' " App_Green
}

function mrg {
  # merge from edge into main_branch
  App_Is_edge
  Condition_No_Commits_Must_Be_Pending
  App_input_2_Is_Empty_As_It_Should

  _doc_name="mrg_info.md" App_Show_Docs

  gh pr merge

### PROMPT
  echo
  my_message="Do you want to see CI status? (y/n)" && App_Blue
  read user_input;
  case ${user_input} in
    y | Y) ci;;
    *) my_message="Operation cancelled" && App_Fatal;;
  esac

  App_Show_Version

  # UX fun
  echo && my_message="NEXT MOVE suggestion: 'ci' - 'sv' - 'v' - 't' " App_Green
}

function ci {
  # continuous integration status
  App_input_2_Is_Empty_As_It_Should
  Condition_No_Commits_Must_Be_Pending

### show latest build and open webpage on Github Actions
  #gh run list && sleep 1
  _run_id=$(gh run list | head -1 | awk '{print $11}')
  _var_name="_run_id" _is_it_empty=$(echo ${_run_id}) && App_Does_Var_Empty
### Opening the run id cuase issues. Lets stick to /actions/
  open https://github.com/${github_user}/${app_name}/actions/

  # Follow status within the terminal
  gh run watch
  # UX fun
  echo && my_message="NEXT MOVE suggestion: 'mrg' " App_Green
}

function version {
### The version is stored within the Dockerfile. For BashLaVa, this Dockerfile is just a config-env file
  Condition_No_Commits_Must_Be_Pending
  App_Is_input_2_Provided
  Condition_Version_Must_Be_Valid

  _var_name="version_with_rc" _is_it_empty=$(echo ${version_with_rc}) && App_Does_Var_Empty

### Logic between 'version' and 'release'.
  # For docker projects like https://github.com/firepress-org/ghostfire,
  # there is a conflict where defining a version like 3.11-rc2 doesn't work because the dockerfile will try to build 'alpine 3.11-rc2'.
  # Therefore, we need to have a release flag. This allows us to have a clean release cycle.
  # sed will trim '-rc2'

  if [[ "${version_with_rc}" == "false" ]]; then
    version_trim=$(echo ${input_2} | sed 's/-r.*//g')
  elif [[ "${version_with_rc}" != "false" ]]; then
    version_trim=${input_2}
  else
    my_message="FATAL: version" && App_Fatal
  fi

### Apply updates
  sed -i '' "s/^ARG VERSION=.*$/ARG VERSION=\"${version_trim}\"/" Dockerfile
  sed -i '' "s/^ARG RELEASE=.*$/ARG RELEASE=\"${input_2}\"/" Dockerfile

  git add .
  git commit . -m "Update ${app_name} to version ${input_2}"
  git push && echo
  App_Show_Version && sleep 1
  log
  # UX fun
  echo && my_message="NEXT MOVE suggestion: 'pr' - 't' " App_Green
}

function tag {
  Condition_No_Commits_Must_Be_Pending
  App_input_2_Is_Empty_As_It_Should

  git tag ${app_release} && git push --tags && echo
  App_Show_Version && sleep 1 && echo

  my_message="Next, prepare release" App_Gray
  my_message="To quit the release notes: type ':qa + enter'" App_Gray && echo

  gh release create && sleep 4
  App_Show_Version
  App_Show_Release
  # UX fun
  echo && my_message="NEXT MOVE suggestion: start over from 'e' " App_Green
}

function squash {
  Condition_No_Commits_Must_Be_Pending
  App_Is_input_2_Provided # how many steps
  App_Is_input_3_Provided # message

  if ! [[ $input_2 =~ ^[0-9]+$ ]] ; then
    my_message="Oups, syntax error." && App_Warning_Stop
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
  echo && my_message="NEXT MOVE suggestion: 'c' - 'pr' " App_Green
}

function test {
# test our script & fct. Idempotent bash script

  echo
  my_message="Check attributes:" App_Blue
  my_message="\$1 value is: ${input_1}" App_Gray
  my_message="\$2 value is: ${input_2}" App_Gray
  my_message="\$3 value is: ${input_3}" App_Gray
  my_message="\$4 value is: ${input_4}" App_Gray

  echo
  my_message="Check apps required:" App_Blue
  Condition_Apps_Must_Be_Installed

  echo
  my_message="Check files and directories:" App_Blue
  App_Check_Are_Files_Exist
  my_message="All good!" App_Gray

  echo
  my_message="Check array from directory components:" App_Blue
  App_array

  echo
  my_message="Check OS" App_Blue
  if [[ $(uname) == "Darwin" ]]; then
    my_message="Running on a Mac (Darwin)" App_Gray
  elif [[ $(uname) != "Darwin" ]]; then
    my_message="bashLaVa is not tested on other machine than Mac OS (Darmin)." && App_Warning
  else
    my_message="FATAL: Test / Check OS" && App_Fatal
  fi

  # PRINT OPTION 1
  echo
  my_message="Check App_glow:" && App_Blue
  _doc_name="test.md" App_Show_Docs

  # PRINT OPTION 2
  # 'test_color' it bypassed as it does an 'exit 0'
  my_message="Check colors options:" && App_Blue && echo
  my_message="bashlava test"
  App_Green
  #App_Blue
  App_Warning
  App_Gray
  #App_Fatal

  # PRINT OPTION 3
  echo
  my_message="Check App_Banner:" && App_Blue
  my_message="bashLaVa test" && App_Banner

  my_message="Check configs:" App_Blue
  my_message="${app_name} < app_name" App_Gray
  #my_message="${app_version} < app_version" App_Gray
  #my_message="${app_release} < app_release" App_Gray
  my_message="${github_user} < github_user" App_Gray
  my_message="${default_branch} < default_branch" App_Gray
  my_message="${github_org} < github_org" App_Gray
  my_message="${dockerhub_user} < dockerhub_user" App_Gray
  my_message="${github_registry} < github_registry" App_Gray
  my_message="${bashlava_executable} < bashlava_executable" App_Gray
  my_message="${my_path} < my_path" App_Gray

  input_2="not_set"
  App_Show_Version
}

function test_color {
  my_message="bashlava test"
  App_Green
  App_Blue
  App_Warning
  App_Gray
  App_Fatal
}

function help {
  App_input_3_Is_Empty_As_It_Should

  _doc_name="dev_workflow.md" App_Show_Docs
  _doc_name="release_workflow.md" App_Show_Docs
  _doc_name="more_commands.md" App_Show_Docs

  ### old code that could be useful in the future
  ### list tag #util> within the code
  # cat ${my_path}/${bashlava_executable} | awk '/#util> /' | sed '$ d' | awk '{$1="";$3="";$4="";print $0}' | sort -k2 -n | sed '/\/usr\/local\/bin\//d' && echo
}

function status {
  git diff --color-words && git status -s
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

function App_Load_variables {
### Default var & path. Customize if need. Usefull if you want
  # to have multiple instance of bashLaVa on your machine
  bashlava_executable="bashlava.sh"
  my_path="/usr/local/bin"

### Does this app accept release candidates (ie. 3.5.1-rc1) in the _version? By default = false
  # When buidling docker images it better to not have rc in the version as breaks the pattern.
  # When not working with a docker build, feel free to put this flag as true.
  # default value is false
  version_with_rc="false"

### Reset if needed
  App_Reset_Custom_path
  _bashlava_path="$(cat ${my_path}/bashlava_path)"

### Set absolute path for the /components directory
  _components_path="${_bashlava_path}/components"

### Set absolute path for the /docs directory
  _docs_path="${_bashlava_path}/docs"

# every scripts that are not under the main bashLaVa app, should be threated as an components.
# It makes it easier to maintain the project, it minimises cluter, it minimise break changes, it makes it easy to accept PR, more modular, etc.

### source PUBLIC scripts

# TODO
# we have few array that are configs. They should be all together under the same block of code.

### source files under /components
  arr=( "alias.sh" "code_example.sh" "templates.sh")
  for action in "${arr[@]}"; do
    _file_is="${action}" _file_path_is="${_components_path}/${_file_is}" && App_Does_File_Exist
    source "${_file_path_is}"
  done

### We dont source this file. See example using Mapfile
  _file_is="list.txt" _file_path_is="${_components_path}/${_file_is}" && App_Does_File_Exist

# TODO
# create a flag where the default is we don't use private

### source PRIVATE / custom scripts
  # the user must create /private/_entrypoint.sh file
  _file_is="_entrypoint.sh" _file_path_is="${_components_path}/private/${_file_is}" && App_Does_File_Exist
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

function App_Show_Version {
  echo && my_message="Check versions:" && App_Blue

### version in dockerfile
  my_message="${app_version} < VERSION in Dockerfile" App_Gray
  my_message="${app_release} < RELEASE in Dockerfile" App_Gray

### tag
  if [ $(git tag -l "$app_version") ]; then
    echo "Good, a tag is present" > /dev/null 2>&1
    latest_tag="$(git describe --tags --abbrev=0)"
    _var_name="latest_tag" _is_it_empty=$(echo ${latest_tag}) && App_Does_Var_Empty
  else
    echo "Logic: new projet don't have any tags. So we must expect that it can be empty" > /dev/null 2>&1
    latest_tag="none "
  fi
  my_message="${latest_tag} < TAG     in mainbranch" App_Gray

### release
  release_latest=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
    grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')

  if [[ -z "$release_latest" ]]; then
    release_latest="none "
    echo "Logic: new projet don't have any release. So we must expect that it can be empty" > /dev/null 2>&1
  elif [[ ! -z "$release_latest" ]]; then
    echo "Good, a release is present" > /dev/null 2>&1
    _var_name="release_latest" _is_it_empty=$(echo ${release_latest}) && App_Does_Var_Empty
  else
    my_message="FATAL: App_Show_Version | release_latest " && App_Fatal
  fi

  my_message="${release_latest} < RELEASE in https://github.com/${github_user}/${app_name}/releases/tag/${release_latest}" && App_Gray
  echo
}

# TODO
# to refactor, too much duplication

function App_Show_Release {
  release_latest=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
    grep tag_name | awk -F ': "' '{ print $2 }' | awk -F '",' '{ print $1 }')
  _var_name="release_latest" _is_it_empty=$(echo ${release_latest}) && App_Does_Var_Empty
  open "https://github.com/${github_user}/${app_name}/releases/tag/${release_latest}"
}

function App_Banner {
  _var_name="docker_img_figlet" _is_it_empty=$(echo ${docker_img_figlet}) && App_Does_Var_Empty
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  docker run --rm ${docker_img_figlet} ${my_message}
}

### TODO
# this is not clean, but it works 'App_glow' / 'App_Show_Docs'
# we can't provide an abosolute path to the file because the Docker container can't the absolute path
# I also DONT want to provide two arguments when using glow
# I might simply stop using a docker container for this
# but as a priciiple, I like to call a docker container

function App_glow {
  # markdown viewer (mdv)
  _var_name="docker_img_glow" _is_it_empty=$(echo ${docker_img_glow}) && App_Does_Var_Empty
  _var_name="input_2" _is_it_empty=$(echo ${input_2}) && App_Does_Var_Empty
  my_message="Info: 'mdv' can only read markdown files at the same path level" App_Green
  sleep 0.5

  _present_path_is=$(pwd)
  _file_is="${input_2}" _file_path_is="${_present_path_is}/${input_2}" && App_Does_File_Exist

  docker run --rm -it -v $(pwd):/sandbox -w /sandbox ${docker_img_glow} glow -w 120 ${input_2}
}

function App_Show_Docs {
  # idempotent checkpoint
  _var_name="docker_img_glow" _is_it_empty=$(echo ${docker_img_glow}) && App_Does_Var_Empty
  _var_name="_doc_name" _is_it_empty=$(echo ${_doc_name}) && App_Does_Var_Empty

  _present_path_is=$(pwd)
  _file_is="${_doc_name}" _file_path_is="${_docs_path}/${_doc_name}" && App_Does_File_Exist

  cd ${_docs_path}
  docker run --rm -it -v $(pwd):/sandbox -w /sandbox ${docker_img_glow} glow -w 110 ${_doc_name}
  cd ${_present_path_is}
}

# Define colors / https://www.shellhacks.com/bash-colors/
function App_Green {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "✨ \e[1;32m${my_message}\e[0m"
}
function App_Blue {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "👋 \e[1;34m${my_message}\e[0m"
}
function App_Warning {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "🚨 \e[1;33m${my_message}\e[0m"
}
function App_Gray {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "\e[1;37m${my_message}\e[0m"
}
function App_Warning_Stop {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
  echo -e "   🚨 \e[1;33m${my_message}\e[0m 🚨" && exit 1
}
function App_Fatal {
  _var_name="my_message" _is_it_empty=$(echo ${my_message}) && App_Does_Var_Empty
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


function App_Is_mainbranch {
  _compare_me=$(git rev-parse --abbrev-ref HEAD)
  _compare_you="${default_branch}" _fct_is="App_Is_mainbranch"
  App_Are_Var_Equal
}

function App_Is_edge {
  _compare_me=$(git rev-parse --abbrev-ref HEAD)
  _compare_you="edge" _fct_is="App_Is_edge"
  App_Are_Var_Equal
}

function Condition_No_Commits_Must_Be_Pending {
  _compare_me=$(git status | grep -c "nothing to commit")
  _compare_you="1" _fct_is="Condition_No_Commits_Must_Be_Pending"
  App_Are_Var_Equal
}

# TODO 1
# refactor this function
# compare var to var
function App_Is_input_2_Provided {
### ensure the second attribute is not empty to continue
  if [[ "${input_2}" == "not_set" ]]; then
    my_message="You must provide two attributes. fct: App_Is_input_2_Provided" && App_Warning_Stop
  elif [[ "${input_2}" != "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: App_Is_input_2_Provided" && App_Fatal
  fi
}

# TODO 2
function App_Is_input_3_Provided {
### ensure the third attribute is not empty to continue
  if [[ "${input_3}" == "not_set" ]]; then
    my_message="You must provide three attributes. fct: App_Is_input_3_Provided" && App_Warning_Stop
  elif [[ "${input_3}" != "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: App_Is_input_3_Provided" && App_Fatal
  fi
}

# TODO 3
function App_input_2_Is_Empty_As_It_Should {
### Stop if 2 attributes are passed.
  if [[ "${input_2}" != "not_set" ]]; then
      my_message="You can NOT use two attributes. fct: App_input_2_Is_Empty_As_It_Should" && App_Warning_Stop
  elif [[ "${input_2}" == "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: App_input_2_Is_Empty_As_It_Should" && App_Fatal
  fi
}

function App_input_3_Is_Empty_As_It_Should {
# Stop if 3 attributes are passed.
  if [[ "${input_3}" != "not_set" ]]; then
      my_message="You can NOT use three attributes. fct: App_input_3_Is_Empty_As_It_Should" && App_Warning_Stop
  elif [[ "${input_3}" == "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: App_input_3_Is_Empty_As_It_Should" && App_Fatal
  fi
}
function App_input_4_Is_Empty_As_It_Should {
# Stop if 4 attributes are passed.
  if [[ "${input_4}" != "not_set" ]]; then
      my_message="You cannot use four attributes. fct: App_input_4_Is_Empty_As_It_Should" && App_Warning && echo
  elif [[ "${input_4}" == "not_set" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: App_input_4_Is_Empty_As_It_Should" && App_Fatal
  fi
}

function Condition_Version_Must_Be_Valid {
  # Version is limited to these characters: 1234567890.rR-
  # so we can do: '3.5.13-r3' or '3.5.13-rc3'
  _compare_me=$(echo "${input_2}" | sed 's/[^0123456789.rcRC\-]//g')
  _compare_you="${input_2}" _fct_is="Condition_Version_Must_Be_Valid"
  App_Are_Var_Equal
}

function Condition_Apps_Must_Be_Installed {
### docker running?
  _compare_me=$(docker version | grep -c "Server: Docker Desktop")
  _compare_you="1" _fct_is="Condition_Apps_Must_Be_Installed"
  App_Are_Var_Equal
  my_message="Docker is installed" && App_Gray

### gh cli installed
  _compare_me=$(gh --version | grep -c "https://github.com/cli/cli/releases/tag/v")
  _compare_you="1" _fct_is="Condition_Apps_Must_Be_Installed"
  App_Are_Var_Equal
  my_message="gh cli is installed" && App_Gray
}

function App_Check_Are_Files_Exist {

### List markdown files under /docs
  arr=( "welcome_to_bashlava" "dev_workflow" "more_commands" "mrg_info" "pr_upstream_issues" "release_workflow" "test" )
  for action in "${arr[@]}"; do
    _file_is="${action}" _file_path_is="${_docs_path}/${_file_is}.md" && App_Does_File_Exist
  done

  _file_is="LICENSE" _file_path_is="${_bashlava_path}/${_file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && App_init_license && exit 1
  fi

  _file_is="README.md" _file_path_is="${_bashlava_path}/${_file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && App_init_readme && exit 1
  fi

  _file_is=".gitignore" _file_path_is="${_bashlava_path}/${_file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && App_init_gitignore && exit 1
  fi

  _file_is="Dockerfile" _file_path_is="${_bashlava_path}/${_file_is}" && App_Does_File_Exist_NoStop
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message="Dockerfile does not exit, let's generate one" && App_Warning && sleep 2 && App_init_dockerfile && exit 1
  fi

### Warning only
  _file_is=".dockerignore" _file_path_is="${_bashlava_path}/${_file_is}" && App_Does_File_Exist_NoStop

### Whern it happens, you want to know ASAP
  _file_is=".git" dir_path_is="${_bashlava_path}/${_file_is}" && App_Does_Directory_Exist
  if [[ "${_file_do_not_exist}" == "true" ]]; then
    my_message=".git directory does not exit" && App_Fatal
  fi
}

function App_Does_File_Exist {
  if [[ -f "${_file_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -f "${_file_path_is}" ]]; then
    my_message="Warning: no file: ${_file_path_is}" && App_Warning_Stop
  else
    my_message="FATAL: App_Does_File_Exist | ${_file_path_is}" && App_Fatal
  fi
}

# This fct return the flag '_file_do_not_exist'
function App_Does_File_Exist_NoStop {
  if [[ -f "${_file_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -f "${_file_path_is}" ]]; then
    my_message="Warning: no file: ${_file_path_is}" && App_Warning
    _file_do_not_exist="true"
  else
    my_message="FATAL: App_Does_File_Exist_NoStop | ${_file_path_is}" && App_Fatal
  fi
}

# Think, IF vars are EQUAL, continue else fail the process
function App_Are_Var_Equal {
  if [[ "${_compare_me}" == "${_compare_you}" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  elif [[ "${_compare_me}" != "${_compare_you}" ]]; then
    my_message="Checkpoint failed '${_fct_is}' ( ${_compare_me} and ${_compare_you} )" && App_Warning_Stop
  else
    my_message="FATAL: App_Are_Var_Equal | ${_fct_is}" && App_Fatal
  fi
}
# Think, IF vars are NOT equal, continue else fail the process
function App_Are_Var_Not_Equal {
  if [[ "${_compare_me}" == "${_compare_you}" ]]; then
    my_message="Checkpoint failed '${_fct_is}' ( ${_compare_me} and ${_compare_you} )" && App_Warning_Stop
  elif [[ "${_compare_me}" != "${_compare_you}" ]]; then
    echo "Good, lets continue" > /dev/null 2>&1
  else
    my_message="FATAL: App_Are_Var_Not_Equal | ${_fct_is}" && App_Fatal
  fi
}

# Think, IF vars is not empty, continue else fail
function App_Does_Var_Empty {
  # source must send two vars:_is_it_empty AND _var_name
  if [[ -n "${_is_it_empty}" ]]; then    #if not empty
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ -z "${_is_it_empty}" ]]; then    #if empty
    my_message="Warning: variable '${_var_name}' is empty" && App_Warning_Stop
  else
    my_message="FATAL: App_Does_Var_Empty | ${_var_name}" && App_Fatal
  fi
}

# This fct return the flag '_file_do_not_exist'
function App_Does_Directory_Exist {
  if [[ -d "${dir_path_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
  elif [[ ! -d "${dir_path_is}" ]]; then
    my_message="Warning: no directory: ${dir_path_is}" && App_Warning_Stop
  else
    my_message="FATAL: App_Does_Directory_Exist | ${dir_path_is}" && App_Fatal
  fi
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# bashLaVa engine set up
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function App_Reset_Custom_path {
# In file ${my_path}/bashlava_path_tmp, we set an absolute path like: '~/Users/myuser/Documents/github/firepress-org/bashlava'
# ${my_path}/bashlava_path point to a file on disk (not a variable)
# It finds and configures it automatically. This way we don't have to hard code it :)
# Don't confuse it with the symlink which is usually at "/usr/local/bin/bashlava.sh"
# We write bashlava_path on disk for speed optimization and to avoid running this request all the time.
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
    my_message="FATAL: App_Reset_Custom_path | ${dir_path_is}" && App_Fatal
  fi
}

### Entrypoint
function main() {
  trap script_trap_err ERR
  trap script_trap_exit EXIT
  source "$(dirname "${BASH_SOURCE[0]}")/.bashcheck.sh"

  App_Load_variables

  if [[ -z "$2" ]]; then    #if empty
    input_2="not_set"
  elif [[ ! -z "$2" ]]; then    #if not empty
    input_2=$2
  else
    my_message="FATAL: <input_2> = ${input_2}" && App_Fatal
  fi

  if [[ -z "$3" ]]; then    #if empty
    input_3="not_set"
  elif [[ ! -z "$3" ]]; then    #if not empty
    input_3=$3
  else
    my_message="FATAL: <input_3> = ${input_3}" && App_Fatal
  fi

  if [[ -z "$4" ]]; then    #if empty
    input_4="not_set"
  elif [[ ! -z "$4" ]]; then    #if not empty
    input_4=$4
  else
    my_message="FATAL: <input_4> = ${input_4}" && App_Fatal
  fi

### Load fct via .bashcheck.sh
  script_init "$@"
  cron_init
  colour_init

### Ensure there are no more than three attrbutes
  App_input_4_Is_Empty_As_It_Should

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
  _doc_name="welcome_to_bashlava.md" && clear && App_Show_Docs

  read user_input; echo;
  case ${user_input} in
    # Dont use the shortcut 't' here! Its used for fct 'tag'
    1) clear && test;;
    2 | h) clear && help;;
    *) my_message="Invalid input" App_Fatal;; 
  esac

elif [[ ! -z "$1" ]]; then
  echo "Good, user did provide argument(s)." > /dev/null 2>&1
else
  my_message="FATAL: main (When no arg are provided)" && App_Fatal
fi
