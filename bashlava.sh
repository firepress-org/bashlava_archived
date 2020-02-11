#!/usr/bin/env bash

# THIS VARIABLE MUST CONFIGURED LOCALY
function App_Custom_path {
  # Define bashlava's path on your local machine:
  local_bashlava_path="/Volumes/960G/_pascalandy/11_FirePress/Github/firepress-org/bashlava"
  App_Check_Custom_path
}

#
  #
    #
      #
        #
          #
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# GIT WORKFLOW
#
#   push commits, update CHANGELOG, rebase or merge, squash (when needed)
#   tag and push the release. All without leaving the terminal!
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function help {
  # available alias: -h h bashlava
  figlet_message="bashLaVa" App_figlet && help-main && which
}

function push {
# think: commit all changes & push on git repo
# usage: bashlava.sh push "Feat: add the hability to see CICD status".
# The signs <"> are required!

  # if no attribute were past, well... let's see what changed then:
  if [[ "${input_2}" == "not-set" ]]; then
    diff
  fi

  App_Is_Input2
  git status && git add -A && \
  git commit -m "${input_2}" && clear && git push;
}

function dk {
  # think: dockerfile update version in our Dockerfile
  # usage: bashlava.sh version 1.50.1

  if [[ "${input_2}" == "not-set" ]]; then
    dk-view && echo 
  fi

  App_Is_Input2
  App_Is_edge

  tag_version="${input_2}"
  App_UpdateDockerfileVersion && \

  App_GetVarFromDockerile
  git add . && \
  git commit . -m "Update ${app_name} to version ${app_version}" && \
  git push origin edge

  echo && my_message="cmd <ci> can be useful at this point when our Dockerfile is built on Github Actions." App_Blue
  # tk maybe build a github action ci watcher...
}

function dk-view {
  # think: view app version from the Dockerfile
  App_GetVarFromDockerile
  my_message="${app_version} < version found in Dockerfile" App_Blue
}

function master {
  # usage bashlava.sh master 3.5.1
  # think squash and rebase edge to master (with squash for a clean master branch)

  if [[ "${input_2}" == "not-set" ]]; then
    dk-view
  fi

  App_Is_Input2
  App_Is_commit_unpushed
  App_Is_changelog
  App_Is_dockerfile
  App_Is_gitignore
  log
  
  # prompt
  my_message="What are we about to merge here?" App_Blue
  read -p "==> " squash_message

  # Update our local state
  git checkout master && \
  git pull origin master && \

  # by using mrg_edge_2_master we create one clean squashed commit
  # remove and create mrg_edge_2_master
  git branch -D mrg_edge_2_master || true && \
  git checkout -b mrg_edge_2_master && \
  # no need to push it to origin (local branch only)

  # merge & squash edge into mrg_edge_2_master
  git merge --squash edge && \
  git commit . -m "${squash_message} /squashed" && \

  # back to master
  git checkout master && \
  # rebase (commits are already squashed at this point)
  git rebase mrg_edge_2_master && \

    # fix conflicts manually if any, then
    # git add . && \
    # git rebase --continue || true

  # push updates
  git push origin master && \
  # clean up
  git branch -D mrg_edge_2_master || true true && echo;

  # update CHANGELOG
  export tag_version="${input_2}"
  App_Changelog_Update

  # next step ==> release
}

function master-nosq {
  # usage: bashlava.sh master-nosq 3.5.1
  # think rebase master from edge NO_SQUASH

  if [[ "${input_2}" == "not-set" ]]; then
    dk-view
  fi
  
  App_Is_Input2
  App_Is_commit_unpushed
  App_Is_changelog
  App_Is_dockerfile
  App_Is_gitignore

  # Update our local state
  git checkout master && \
  git pull origin master && \

  # rebase
  git rebase edge && \
  git push origin master && echo;

  # update CHANGELOG
  export tag_version="${input_2}"
  App_Changelog_Update

  # next setp ==> release
}

function release {
  # think push release + tags to github
  # at this point we commited our changelog and rebase to master
  # usage: bashlava.sh release 1.50.1
  App_Is_Input2
  App_Is_master
  App_GetVarFromDockerile

  # push updates
  git commit . -m "Update CHANGELOG to version ${app_version}" && \
  git push origin master && \

  App_Is_dockerfile
  App_Is_hub_installed

  # Tag our release
  git tag ${app_version} && git push --tags && echo

  # prepared release
  release_message1="Refer to [CHANGELOG.md](https://github.com/${github_user}/${app_name}/blob/master/CHANGELOG.md) for details about this release."
  release_message2="Released with [bashLaVa](https://github.com/firepress-org/bashlava). You should try it, it's addictive."

  # push release
  hub release create -oc \
    -m "${app_version}" \
    -m "${release_message1}" \
    -m "${release_message2}" \
    -t "$(git rev-parse HEAD)" \
    "${app_version}" && \

  echo && my_message="https://github.com/${github_user}/${app_name}/releases/tag/${app_version}" App_Blue && \
  edge

  # let's cheers up a bit!
  clear && figlet_message="Good job!" App_figlet;
  figlet_message="${app_version} is up." App_figlet;
}

function cl-view {
  # think: Show me the CHANGELOG.md
  input_2="CHANGELOG.md"
  App_Is_Input2
  App_glow50
}

function edge {
  # usage: bashlava.sh master
  # think scrap branch edge and recreate it as a new feat branch
  # it assumes there will be no conflict with anybody else as I'm the only person using 'edge'
  App_Is_commit_unpushed

  git branch -D edge || true && \
  git checkout -b edge && \
  git push --set-upstream origin edge -f && \

  echo && my_message="<edge> was create from scratch (from <master>)" App_Blue
}

function sq {
  # usage: bashlava.sh sq 3 "Add fct xyz"
  # think: squash. The fct master does squash our commits as well
  App_Is_commit_unpushed
  App_Is_Input2
  App_Is_Input3

  backwards_steps="${input_2}"
  git_message="${input_3}"
  usage="sq 3 'Add fct xyz'"

  git reset --hard HEAD~"${backwards_steps}" && \
  git merge --squash HEAD@{1} && \
  git push origin HEAD --force && \
  git status && \
  git add -A && \
  git commit -m "${git_message} /squashed" && \
  git push;
}

function wip-pr {
  # tk work in progress
  # hub pull-request

  # pre-requirments
    #git checkout ghostv3-dev && git pull ghostv3-dev # I'm here
    #bashlava.sh push "my change dummy file"

  git checkout ghostv3-staging && git pull ghostv3-staging
  # hub sync
  git checkout -b mrg-dev-to-staging
  git merge --no-ff origin/ghostv3-dev # no fast forward
  git push -u origin mrg-dev-to-staging
}

function wip-release_latest {
  # tk work in progress
  # not working
  # find the latest release that was pushed on github

  App_GetVarFromDockerile

  if [[ -z "${app_name}" ]] ; then    #if empty
    clear
    my_message="Can't find APP_NAME in the Dockerfile (ERR5679)" App_Pink
    App_Stop
  elif [[ -z "${github_user}" ]] ; then    #if empty
    clear
    my_message="Can't find GITHUB_USER in the Dockerfile (ERR5680)" App_Pink
    App_Stop
  else
    my_message=$(curl -s https://api.github.com/repos/${github_user}/${app_name}/releases/latest | \
      grep tag_name | \
      awk -F ': "' '{ print $2 }' | \
      awk -F '",' '{ print $1 }')
    App_Blue
  fi
}

#
  #
    #
      #
        #
          #
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# CHILD APPS
#   (the user never directly call these)
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function App_Changelog_Update {
  # think update the CHANGELOG.md by define on which version we are
  # usage: bashlava.sh cl 3.5.1
  App_Is_Input2
  App_Is_master
  App_Is_changelog

   # give time to user to CTRL-C if he changes is mind
  clear && echo && \
  my_message="Update CHANGELOG.md to v${tag_version}:" App_Blue && sleep 1

  App_UpdateDockerfileVersion

  # reset files
  rm ~/temp/tmpfil* || true

  git_logs="$(git --no-pager log --abbrev-commit --decorate=short --pretty=oneline -n25 | \
    awk '/HEAD ->/{flag=1} /tag:/{flag=0} flag' | \
    sed -e 's/([^()]*)//g' | \
    awk '$1=$1')"

  # copy logs
  echo -e "${git_logs}" > ~/temp/tmpfile2

  # create URLs from git commits
  # --- find the number of line in this file
  number_of_lines=$(cat ~/temp/tmpfile2 | wc -l | awk '{print $1}')
  App_GetVarFromDockerile
  for lineID in $(seq 1 ${number_of_lines}); do
    hash_to_replace=$(cat ~/temp/tmpfile2 | sed -n "${lineID},${lineID}p;" | awk '{print $1}')
    # Unlike Ubuntu, OS X requires the extension to be explicitly specified.
    # The workaround is to set an empty string. Here we use ''
    sed -i '' "s/${hash_to_replace}/[${hash_to_replace}](https:\/\/github.com\/${github_user}\/${app_name}\/commit\/${hash_to_replace})/" ~/temp/tmpfile2
  done
  # add space at the begining of a line
  sed 's/^/ /' ~/temp/tmpfile2 > ~/temp/tmpfile3
  # add sign "-" at the begining of a line
  sed 's/^/-/' ~/temp/tmpfile3 > ~/temp/tmpfile4
  # create main file
  echo -e "" >> ~/temp/tmpfile
  # insert title version
  echo -e "## ${input_2}" >> ~/temp/tmpfile
  # insert title Updates
  echo -e "### ⚡️ Updates" >> ~/temp/tmpfile
  # insert our montage to the main file
  cat ~/temp/tmpfile4 >> ~/temp/tmpfile
  # Insert our release notes after pattern "# Release"
  bottle="$(cat ~/temp/tmpfile)"
  awk -vbottle="$bottle" '/# Releases/{print;print bottle;next}1' CHANGELOG.md > ~/temp/tmpfile
  cat ~/temp/tmpfile | awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' > CHANGELOG.md
  # clean
  rm ~/temp/tmpfil* || true

  # The system will open the CHANGELOG file, in case you have to edit it.
  # Manually edit CHANGELOG in terminal
  nano CHANGELOG.md

  # then run: release
}

function App_Is_master {
  currentBranch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "${currentBranch}" == "master" ]]; then
    echo "Good, lets continue" | 2>/dev/null
  else
    my_message="You must be on <master> branch to perform this action (ERR5681)" App_Pink
    my_message="Try: out-m" App_Blue && App_Stop
  fi
}
function App_Is_edge {
  currentBranch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "${currentBranch}" == "edge" ]]; then
    echo "Good, lets continue" | 2>/dev/null
  else
    my_message="You must be on <edge> branch to perform this action (ERR5682)" App_Pink
    my_message="Try: out-e" App_Blue && App_Stop
  fi
}
function App_Is_commit_unpushed {
  if [[ $(git status | grep -c "nothing to commit") == "1" ]]; then
    echo "Good, lets continue" | 2>/dev/null
  else
    my_message="You must push your commit(s) before doing a rebase (ERR5683)" App_Pink && App_Stop
  fi
}
function App_Is_dockerfile {
  if [ -f Dockerfile ]; then
    echo "Good, lets continue" | 2>/dev/null
  else
    my_message="Dockerfile does not exit. Let's create one (ERR5684)" App_Pink && init_dockerfile && App_Stop
  fi
}
function App_Is_changelog {
  if [ -f CHANGELOG.md ]; then
    echo "Good, lets continue" | 2>/dev/null
  else
    my_message="CHANGELOG.md does not exit. Let's create one (ERR5685)" App_Blue
    init_changelog && \
    App_Stop && echo
  fi
}
function App_Is_gitignore {
  if [ -f .gitignore ]; then
    echo "Good, lets continue" | 2>/dev/null
  else
    my_message=".gitignore does not exit. Let's create one (ERR5686)" App_Blue
    init_gitignore && \
    App_Stop && echo
  fi
}
function App_Is_hub_installed {
  if [[ $(hub version | grep -c "hub version") == "1" ]]; then
    echo && my_message="Hub is installed." App_Blue
  else
    echo && my_message="Hub is missing. https://github.com/firepress-org/bash-script-template#requirements" App_Pink
  fi
}
function App_Is_docker_installed {
  if [[ $(docker version | grep -c "Client: Docker Engine") == "1" ]]; then
    my_message="Docker is installed." App_Blue
  else
    my_message="Docker is missing. https://github.com/firepress-org/bash-script-template#requirements" App_Pink
  fi
}
function App_Is_Input2 {
# ensure the second attribute is not empty to continue
  if [[ "${input_2}" == "not-set" ]]; then
    my_message="You must provide a valid attribute (ERR5687)" App_Pink
    App_Stop
  fi
}
function App_Is_Input3 {
# ensure the third attribute is not empty to continue
  if [[ "${input_3}" == "not-set" ]]; then
    my_message="You must provide a valid attribute (ERR5688)" App_Pink
    App_Stop
  fi
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
function App_release_check_vars {
  if [[ -z "${app_name}" ]]; then
    my_message="ERROR: app_name is empty (ERR5691)" App_Pink App_Stop
  elif [[ -z "${app_version}" ]]; then
    my_message="ERROR: app_version is empty (ERR5692)" App_Pink App_Stop
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

function App_UpdateDockerfileVersion {
  # expect VAR: $tag_version
  # update ap VERSION  within the Dockerfile.

  # version before
  App_GetVarFromDockerile
  version_before=${app_version}

  # apply update
  tag_version_clean=$(echo $tag_version | sed 's/-r.*//g')
  # sometimes we push 3.15.2-r4, this will clean "-r4"
  sed -i '' "s/^ARG VERSION=.*$/ARG VERSION=\"$tag_version_clean\"/" Dockerfile

  # version after
  App_GetVarFromDockerile
  version_after=${app_version}

  # To debug if needed
      # confirm change was well executed (to dubug id needed)
      #App_GetVarFromDockerile
      #if [[ "${version_before}" == "${version_after}" ]]; then
      #  my_message="${version_before} <== Dockerfile version before" App_Pink
      #  my_message="${version_after} <== Dockerfile version after" App_Pink
      #  my_message="The versions did NOT changed. Is it ok?" App_Pink && sleep 5
      #else
      #  my_message="${version_before} <== Dockerfile version before" App_Green
      #  my_message="${version_after} <== Dockerfile version after" App_Green
      #fi
}

function App_GetVarFromDockerile {
  # Extract vars from our Dockerfile
  app_name=$(cat Dockerfile | grep APP_NAME= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  app_version=$(cat Dockerfile | grep VERSION= | head -n 1 | grep -o '".*"' | sed 's/"//g')
  github_user=$(cat Dockerfile | grep GITHUB_USER= | head -n 1 | grep -o '".*"' | sed 's/"//g')

  # set empty input (if any)
  if [[ -z "$app_name" ]]; then         #if empty
    app_name="not-set"
  elif [[ -z "$app_version" ]]; then    #if empty
    app_version="not-set"
  elif [[ -z "$github_user" ]]; then    #if empty
    github_user="not-set"
  fi

  # debug if needed
    # my_message="Available vars: ${app_name}, ${app_version}, ${github_user}" App_Blue && sleep 11
}

function App_figlet {
  docker_image="devmtl/figlet:1.0"
  docker run --rm ${docker_image} ${figlet_message}
}

function App_glow50 {
# markdown viewer for your terminal. Better than cat!
  docker run --rm -it \
    -v $(pwd):/sandbox \
    -w /sandbox \
    devmtl/glow:0.2.0 glow ${input_2} | sed -n 12,50p # show the first 60 lines
}

function App_glow {
  docker run --rm -it \
    -v $(pwd):/sandbox \
    -w /sandbox \
    devmtl/glow:0.2.0 glow ${input_2}
}

function App_Check_Custom_path {
  # Check if project's path is well defined. Is set via <App_Custom_path>
  if [ ! -f ${local_bashlava_path}/bashlava.sh ]; then
      my_message="Local path is not valid (ERR5672)" App_Pink && App_Stop
  else
      echo "Path is okay" | 2>/dev/null
      addon_fct_path="${local_bashlava_path}/add-on"
  fi
}

function App_Pink { echo -e "${col_pink} ERROR: ${my_message}"
}
function App_Blue { echo -e "${col_blue} ${my_message}"
}
function App_Green { echo -e "${col_green} ${my_message}"
}
function App_Stop { echo "——> exit 1" && echo && exit 1
}

#
  #
    #
      #
        #
          #
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# UTILITIES
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function test {
# test our script & fct. Idempotent bash script

  echo "\$1 value is: ${input_1}"
  echo "\$2 value is: ${input_2}"
  echo "\$3 value is: ${input_3}"
  # Useful when trying to find bad variables along 'set -o nounset'

  App_Is_hub_installed 
  App_Is_docker_installed 

  my_message="Date is: ${date_sec}" App_Blue
}

function which {
  # If needed, you can list your add-on function here as well. We don't list them by default to minimize cluter.
  help-which
  cat /usr/local/bin/bashlava.sh | awk '/function /' | awk '{print $2}' \
    | sort -k2 -n | sed '/App_/d' | sed '/main/d' | sed '/MYCONFIG/d' \
    | sed '/\/usr\/local\/bin\//d' | sed '/utility/d' | sed '/If/d' | sed '/tk/d' | sed '/add_on/d'
}

# password generator. See also "passgen_long" These char are not part of the password to minimize human error: i,I,L,l,o,O,0
function passgen { docker run ctr.run/github.com/firepress-org/alpine:master sh -c "/usr/local/bin/random3.sh";
}
function out-m { git checkout master # basic checkout to master
}
function out-e { git checkout edge   # basic checkout to edge
}
function log { git log --all --decorate --oneline --graph --pretty=oneline -n25
}
function hash { git rev-parse HEAD && git rev-parse --short HEAD 
}
function status { git status
}
function diff { git diff
}
function ci {
  # Valid for Github Actions CI. Usually the CI build our Dockerfiles
  # while loop for 8 min
  MIN="1" MAX="96"
  for action in $(seq ${MIN} ${MAX}); do
    hub ci-status -v $(git rev-parse HEAD) && echo && sleep 5;
  done
}

#
  #
    #
      #
        #
          #
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
#
# BASHLAVA engine (lol)
#   low-level logic
#
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
          #
        #
      #
    #
  #
#

function App_add_on {
  # think: every script that should not be under the main bashlava.sh shell script, should threated as an add-on.
  # This will make easier to maintain de project, minimise cluter, minimise break changes, easy to accept PR
  source "${addon_fct_path}/help.sh"
  source "${addon_fct_path}/alias.sh"
  source "${addon_fct_path}/examples.sh"
  source "${addon_fct_path}/templates.sh"
  source "${addon_fct_path}/docker.sh"
  source "${addon_fct_path}/utilities.sh"

  # Define your own custom add-on scripts. `custom_*.sh` files are in part .gitignore so they will not be commited.
  source "${addon_fct_path}/custom_scripts.sh"
}

function App_DefineVariables {
  #	Define color for echo prompts:
  export col_std="\e[39m——>\e[39m"
  export col_grey="\e[39m——>\e[39m"
  export col_blue="\e[34m——>\e[39m"
  export col_pink="\e[35m——>\e[39m"
  export col_green="\e[36m——>\e[39m"
  export col_white="\e[97m——>\e[39m"
  export col_def="\e[39m"

  #	Date generators
  date_nano="$(date +%Y-%m-%d_%HH%Ms%S-%N)";
    date_sec="$(date +%Y-%m-%d_%HH%Ms%S)";
    date_min="$(date +%Y-%m-%d_%HH%M)";
  date_hour="$(date +%Y-%m-%d_%HH)XX";
    date_day="$(date +%Y-%m-%d)";
  date_month="$(date +%Y-%m)-XX";
  date_year="$(date +%Y)-XX-XX";
            # 2017-02-22_10H24_14-500892448
            # 2017-02-22_10H24_14
            # 2017-02-22_10H24
            # 2017-02-22_10HXX
            # 2017-02-22
            # 2017-02-XX
            # 2017-XX-XX
}

function main() {
  # ENTRYPOINT

  trap script_trap_err ERR
  trap script_trap_exit EXIT
  source "$(dirname "${BASH_SOURCE[0]}")/.bashcheck.sh"  # shellcheck 

  # Load variables
  App_Custom_path
  App_DefineVariables
  App_add_on

  # set empty input. The user must provide 1 to 3 attributes
  input_1=$1
  if [[ -z "$1" ]]; then    #if empty
    clear
    my_message="You must provide at least one attribute (ERR5671)" App_Green
    my_message="Try: 'bashlava.sh help'" App_Green
    App_Stop
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

  # Safety run our bachscript (must be after setting the empty input)
  set -eou pipefail
  # set -o xtrace # <== to debug if needed / Trace the execution of the script

  script_init "$@"
  cron_init
  colour_init
  #lock_init system

  # Attribute #1. It accepts two more attributes
  # tk FEAT add logic to confirm the function exist or not
  clear
  $1
}

main "$@"
echo
