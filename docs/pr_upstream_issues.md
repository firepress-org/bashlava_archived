# issue about origin

Sometime this error happens:

> pull request create failed: GraphQL error: Head sha can't be blank, Base sha can't be blank, No commits between ralish:master and firepress-org:edge, Base ref must be a branch

- https://github.com/cli/cli/issues/2300
- https://github.com/cli/cli/issues/1820
- https://github.com/cli/cli/issues/1762

debug mode

`git remote -v`

output:

```
origin git@github.com:firepress-org/bashlava.git (fetch)
origin git@github.com:firepress-org/bashlava.git (push)
upstream git@github.com:firepress-org/bashlava.git (fetch)
upstream git@github.com:firepress-org/bashlava.git (push)
```

reset but it does not work 2022-04-29

`git config --local --get-regexp '\.gh-resolved$' | cut -f1 -d' ' | xargs -L1 git config --unset`

## reset-the-git-master-branch-to-the-upstream-branch-in-a-forked-reposito

You can reset your local master branch to the upstream version and push it to your origin repository. Assuming that "upstream" is the original repository and "origin" is your fork

ensures current branch is master

`git checkout master`

pulls all new commits made to upstream/master

`git pull upstream master`

this will delete all your local changes to master

`git reset --hard upstream/master`

take care, this will delete all your changes on your forked master

`git push origin master --force`

source: https://stackoverflow.com/questions/42332769/how-do-i-reset-the-git-master-branch-to-the-upstream-branch-in-a-forked-reposito
