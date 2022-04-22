#!/usr/bin/env bash

gh pr create \
  --fill \
  --assignee "@me" \
  --base firepress-org/bashlava


###

git remote -v

  origin  git@github.com:firepress-org/bashlava.git (fetch)
  origin  git@github.com:firepress-org/bashlava.git (push)
  upstream        https://github.com/ralish/bash-script-template.git (fetch)
  upstream        https://github.com/ralish/bash-script-template.git (push)

git remote set-url upstream git@github.com:firepress-org/bashlava.git

