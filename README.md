# Octopus :octopus:

A tool for bulk analysis and mass refactor of system wide configuration files.

Download 1000+ Jenkinsfiles from all repos in your org in under a minute, update half of them, and have your pull requests automatically opened before your tea turns cold.

![](http://www.reactiongifs.com/r/2013/02/nope.gif)

## Setup
`./bin/setup`

To run tests, do `rake`

## Usage

```shell
Usage: ./octopus.rb [options]
    -u, --username=USERNAME          Bitbucket username.
    -p, --password=PASSWORD          Bitbucket password.
    -c, --command=COMMAND            Octopus command: [fetch, update].
    -d, --directory=DIRECTORY        Directory to fetch files into / to read files for update.
        --url=URL                    SCM host URL.
        --scm-provider=PROVIDER      SCM provider. Available options: bitbucket. Default: bitbucket
        --thread-count=COUNT         Thread count. Default: 500.
    -f, --files=FILENAME             A comma-separated list of files to fetch/update.
    -m, --message=MESSAGE            Commit message.
    -t, --title=TITLE                Pull request title.
    -b, --branch=BRANCH              Branch name. Optional for "fetch" command. In the context of "update" - a branch that will contain changes.
        --description=DESCRIPTION    Pull request descriptions.
```

To download all Jenkinsfiles and Dockerfiles from all Bitbucket repositories from their respective default branches do the following:
```shell
ruby octopus.rb \
--directory=./jenkinsfiles \
--files=Jenkinsfile,Dockerfile \
--command=fetch \
--url=https://git.uptake.com \
--username=akaupanin \
--password=$BITBUCKET_PASSWORD
```

You can optionally specify branch name which might be useful to validate your previous bulk changes in isolation or iterate on them:
```shell
ruby octopus.rb \
--directory=./jenkinsfiles \
--files=Jenkinsfile,Dockerfile \
--command=fetch \
--branch="octopus/my-previous-refactor" \
--url=https://git.uptake.com \
--username=akaupanin \
--password=$BITBUCKET_PASSWORD
```

Once all files are downloaded, you can grep/sed them all you want. To open pull requests for all updated Jenkinsfiles and Dockerfiles:

```shell
ruby octopus.rb \
--directory=./jenkinsfiles \
--files=Jenkinsfile,Dockerfile \
--command=update \
--url=https://git.uptake.com \
--username=akaupanin \
--password=$BITBUCKET_PASSWORD \
--branch="octopus/refactor" \
--message="Octopus commit message" \
--title="PR title" \
--description=":octopus: here goes your pull request description. Can be multiline."
```

Note that because `octopus` essentially utilized "inline edit" funcitonality, each pull request will have one commit per file updated.

If a pull request from feature branch against the default branch already exists, it will be amended if you've made other changes to the target file. Otherwise, nothing will happen.

## Important Caveats

- Pull requests are created against default branches only.
- No new branches nor any other changes will be made for repos which files were not changed on local. It means that it's perfectly fine to download 500 files via `fetch` command, edit 20 of them and run `update` pointing to the same directory where the files were downloaded.
- You can use `update` without `fetch`. What's important is that you follow the convention: each top-level folder represents a project key, low-level folder represents a repository slug.

## SCM Providers

Since we use Bitbucket here at Uptake, the project orignally had support for Bitbucket API only. However, we tried to make it more extensible and generic. Contributions with GitHub/GitLab clients are welcome!

## Questions, concerns, feature requests.
You are more than welcome to express questions and concerns by creating an issue, and feature requests by cutting a PR.
