&nbsp;

<p align="center">
  <a href="https://github.com/firepress-org/bashlava">
    <img src="https://user-images.githubusercontent.com/6694151/74113494-746ee100-4b72-11ea-9601-bd7b1d786b41.jpg" width="1024px" alt="FirePress" />
  </a>
</p>

&nbsp;

> BashLaVa makes your bash scripts a bunch of pieces of cakes.

# BashLava

BashLaVa is a utility-first bash framework. The idea is to abstract your workflow to minimize the time to do some repetitive actions.

It's for developers that use git commands regularly. BashLaVa makes following git workflow a breeze without having to leave your terminal or use GitHub GUI.

In other word, the the **agile release cycle** should be something you master. BashLaVa helps you big time to get there.

&nbsp;

## See BashLaVa in Action

**This section in not done yet**. 2022-05-01_21h44

- Features
  - open webpage on Github Actions CI
  - open webpage on Github Actions PR
- How to Installation
- Using git-crypt + gnupg
- /private directory
- Go thru the code

**It also allows you**:

- quickly set your custom scripts
- quickly write help function
- hack around as it's all built with bash

## Installation

- 1. git **clone** this repo
- 2. **create a symlink** to your PATH for both files.

```
ln -s /Volumes/myuser/Github/firepress-org/bashlava/bashlava.sh /usr/local/bin/bashlava.sh

ln -s /Volumes/myuser/Github/firepress-org/bashlava/.bashcheck.sh /usr/local/bin/.bashcheck.sh
```

Assuming your $path is `/usr/local/bin`

- 4. Create a file named `/components/_entrypoint.sh`. [Here is how to use it.](https://github.com/firepress-org/bashlava/issues/50)

- 4. **Test your installation**. run: `bashlava.sh test`

## Requirements

- A Mac OS: I didn't test BashLaVa on other systems. _Let's me know if you want to help for this :)_
- [Docker](https://docs.docker.com/install/): (needed for markdown viewer, password generator, lint checker, etc.)
- [gh (github cli)](https://cli.github.com/): needed to create PR on GitHub

## Website hosting

If you are looking for an alternative to WordPress, [Ghost](https://firepress.org/en/faq/#what-is-ghost) might be the CMS you are looking for. Check out our [hosting plans](https://firepress.org/en).

![ghost-v2-review](https://user-images.githubusercontent.com/6694151/64218253-f144b300-ce8e-11e9-8d75-312a2b6a3160.gif)

## Why, Contributing, License

<details><summary>Click to expand this section.</summary>
<p>

## Why all this work?

Our [mission](https://firepress.org/en/our-mission/) is to empower freelancers and small organizations to build an outstanding mobile-first website.

Because we believe your website should speak up in your name, we consider our mission completed once your site has become your impresario.

Find me on Twitter [@askpascalandy](https://twitter.com/askpascalandy).

— [The FirePress Team](https://firepress.org/) 🔥📰

## Contributing

The power of communities pull request and forks means that `1 + 1 = 3`. You can help to make this repo a better one! Here is how:

1. Fork it
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request

Check this post for more details: [Contributing to our Github project](https://pascalandy.com/blog/contributing-to-our-github-project/). Also, by contributing you agree to the [Contributor Code of Conduct on GitHub](https://pascalandy.com/blog/contributor-code-of-conduct-on-github/).

## License

- This git repo is under the **GNU V3** license.

</p>
</details>
