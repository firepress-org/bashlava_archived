#!/usr/bin/env bash

function Prompt_All_Available_Fct { #Side_
  # when you code a fct, often you dont know by heart condition name
  # help advanced
  # it also helps me to see all functions at high level
  # useful to debug

  Core_Check_Which_File_Exist

  _doc_name="Prompt_All_Available_Fct.md" && clear && Show_Docs && sleep 1
  echo

  read -r month
  case ${month} in
    1 | a)
      echo "0o0o";;
    2 | b)
      echo "0o0o";;
    3 | c)
      echo "0o0o";;
    *)
      echo "cancel" && exit 1;;
  esac
  

  # code optimization 0o0o CASE per function's category

  my_message="sidecars" && Print_Blue && echo
  my_message="$(cat ${_path_components}/sidecars.sh | grep "{ #Side_" | awk '{print $2}')" && Print_Gray && echo

  my_message="alias" && Print_Blue && echo
  my_message="$(cat ${_path_components}/alias.sh | grep "function " | awk '{print $2}')" && Print_Gray && echo

  my_message="example" && Print_Blue && echo
  my_message="$(cat ${_path_components}/example.sh | grep "function " | awk '{print $2}')" && Print_Gray && echo

  my_message="User" && Print_Blue && echo
  my_message="$(cat ${_path_bashlava}/bashlava.sh | grep "{ # User_" | awk '{print $2}')" && Print_Gray && echo

  my_message="Condition" && Print_Blue && echo
  my_message="$(cat ${_path_bashlava}/bashlava.sh | grep "function Condition_" | awk '{print $2}')" && Print_Gray && echo

  my_message="Show" && Print_Blue && echo
  my_message="$(cat ${_path_bashlava}/bashlava.sh | grep "function Show_" | awk '{print $2}')" && Print_Gray && echo

  my_message="Print" && Print_Blue && echo
  my_message="$(cat ${_path_bashlava}/bashlava.sh | grep "function Print_" | awk '{print $2}')" && Print_Gray && echo

  my_message="Prompt" && Print_Blue && echo
  my_message="$(cat ${_path_bashlava}/bashlava.sh | grep "function Prompt_" | awk '{print $2}')" && Print_Gray && echo

  my_message="App" && Print_Blue && echo
  my_message="$(cat ${_path_bashlava}/bashlava.sh | grep "function App_" | awk '{print $2}')" && Print_Gray && echo

  my_message="Core" && Print_Blue && echo
  my_message="$(cat ${_path_bashlava}/bashlava.sh | grep "function Core_" | awk '{print $2}')" && Print_Gray && echo

  # cat ${_path_bashlava}/bashlava.sh | awk '/#util> /' | sed '$ d' | awk '{$1="";$3="";$4="";print $0}' | sort -k2 -n | sed '/\/usr\/local\/bin\//d' && echo

  # code optimization 0o0o / Add logic for private script
}

function passgen { #Side_
  docker run --rm devmtl/alpine:3.11_2020-02-26_08H42s20_dec5798 sh "random7.sh"
}

function App_random_6 { #Side_
  openssl rand -hex 3
}

function App_array { #Side_
  arr=( "Hello" "Mr Andy" )
  for i in "${arr[@]}"; do
    my_message="${i}" && Print_Gray
  done
}

function hello { #Side_
  echo && my_message="NEXT MOVE suggestion: Say hello to a living soul." Print_Green
}

function App_Curl_url { #Side_
# must receive var: url_to_check
  UPTIME_TEST=$(curl -Is ${url_to_check} | grep -io OK | head -1);
  MATCH_UPTIME_TEST1="OK";
  MATCH_UPTIME_TEST2="ok";
  if [[ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST1" ]] || [[ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST2" ]]; then
    my_message="${url_to_check} <== is online" && Print_Green
  elif [[ "$UPTIME_TEST" != "$MATCH_UPTIME_TEST1" ]] || [[ "$UPTIME_TEST" = "$MATCH_UPTIME_TEST2" ]]; then
    my_message="${url_to_check} <== is offline" && Print_Warning
    my_message="The git up repo URL is not responding." && Print_Fatal
  fi
}

function App_init_readme { #Side_
cat << EOF > README_template.md
This README is still empty.
EOF
}

# optional as not everyone needs this option
function App_init_dockerignore { #Side_
cat << EOF > .dockerignore_template
.cache
coverage
dist
node_modules
npm-debug
.git
EOF
}

function App_init_license { #Side_
# two things two update here
# project URL
# URL to LICENSE.md (you should fork it)
cat << EOF > LICENSE_template
Copyright (C) 2022
by Pascal Andy | https://pascalandy.com/blog/now/

Project:
https://github.com/owner-here/project-here

At the essence, you have to credit the author AND you have
to keep the code free AND you have to keep the code open-source AND you 
cannot repackage this code for any commercial endeavour.

Find the GNU General Public License V3 at:
https://github.com/pascalandy/GNU-GENERAL-PUBLIC-LICENSE/blob/master/LICENSE.md
EOF
my_message="File created: ${local_path_bashlava}/LICENSE_template" Print_Green
}

function App_init_dockerfile { #Side_
cat << EOF > Dockerfile_template
###################################
# REQUIRED for bashLaVa https://github.com/firepress-org/bashlava
# REQUIRED for Github Action CI template https://github.com/firepress-org/ghostfire/tree/master/.github/workflows
###################################

ARG APP_NAME="notset"
ARG VERSION="notset"
ARG RELEASE="notset"
ARG GITHUB_USER="notset"
ARG DEFAULT_BRANCH="notset"
ARG GITHUB_ORG="notset"
ARG DOCKERHUB_USER="notset"
ARG GITHUB_REGISTRY="notset"

###################################
# Start you Dockerfile from here (if any)
###################################

EOF
my_message="File created: ${local_path_bashlava}/Dockerfile_template" Print_Green
}

function App_init_gitignore { #Side_
cat <<EOF > .gitignore_template
# Files
############
custom_*.sh
env_local_path.sh
.env
.cache
coverage
dist
node_modules
npm-debug

# Directories
############
/tmp
/temp

# Compiled source #
###################
*.com
*.class
*.dll
*.exe
*.o
*.so

# Packages #
############
# it's better to unpack these files and commit the raw source
# git has its own built in compression methods
*.7z
*.dmg
*.gz
*.iso
*.jar
*.rar
*.tar
*.zip

# Logs and databases #
######################
*.log
*.sql
*.sqlite

# OS generated files #
######################
.DS_Store
.DS_Store?
custom_*.sh
.vscode
.Trashes
ehthumbs.db
Thumbs.db
.AppleDouble
.LSOverride
.metadata_never_index

# Thumbnails
############
._*

# Icon must end with two \r
###########################
Icon

# Files that might appear in the root of a volume
#################################################
.DocumentRevisions-V100
.fseventsd
.dbfseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.trash
.VolumeIcon.icns
.com.apple.timemachine.donotpresent
.com.apple.timemachine.supported
.PKInstallSandboxManager
.PKInstallSandboxManager-SystemSoftware
.file
.hotfiles.btree
.quota.ops.user
.quota.user
.quota.ops.group
.quota.group
.vol
.efi

# Directories potentially created on remote AFP share
#####################################################
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk
.Mobile*
.disk_*

# Sherlock files
################
TheFindByContentFolder
TheVolumeSettingsFolder
.FBCIndex
.FBCSemaphoreFile
.FBCLockFolder
EOF
my_message="File created: ${local_path_bashlava}/App_init_gitignore" Print_Green
}
