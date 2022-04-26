---

# I) Dev workflow

from `main branch` >>

- `e` ............ create a branch `edge` from `main branch`
- `c` ............ commit | usage: c "my feature is great"
- `pr` ........... create pull request
- `ci` ........... check CI on GitHub Actions (GUI)
- `mrg` .......... gh cli ask few questions
- `m` ............ checkout to `main branch` + fetch updates from remote

At this point we can ...

- go to: `e`
- go to: `release`

# II) Release workflow

from `main branch` >>

- `v 1.2.3` ...... create a commit automatically
- `t` ............ tag the commits from the version + opens the release page GUI on GitHub

# III) More commands

- `h` ............ help
- `test` ......... test if requirements for bashLaVa are meet
- `sq` ........... squash commits | usage: sq 3 "my feature is great"
- `l` ............ log - show me the latest commits
- `s` ............ status
- `h` ............ help about bashlava
- `oe` ........... checkout to branch edge
- `om` ........... checkout to mainbranch
- `diff` ......... show diff in my code
- `mdv` .......... markdown viewer | usage: mdv README.md
- `tr` ........... tag read tag on mainbranch
- `vr` ........... version read show app's version from Dockerfile
- `rr` ........... release read latest from Github
- `hash` ......... hash Show me the latest hash commit
- `gitio` ........ git.io shortner, works only with GitHub repos

https://github.com/firepress-org/bashlava
