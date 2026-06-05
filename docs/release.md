# Making Releases

Example, release a new version: `99.9.9`

1. Git operations

```sh
git checkout main
git pull
git fetch --prune  # updates everything from remote
git status # verify everything is up-to-date with no changes/conflicts
git checkout -b rel-v99.9.9
$EDITOR mix.exs # edit to update `version`
$EDITOR CHANGELOG.md # edit to document changes in release with ticket numbers
git add mix.exs CHANGELOG.md
git commit -m "v99.9.9 release" # commit all changes
git push -u origin rel-v99.9.9 # push branch "upstream"
```

2. Create a PR and wait for approvals

3. Git operations

```sh
git checkout main
git merge --ff-only rel-v99.9.9 # fast-forward only for safety
git tag -a v99.9.9 -m "v99.9.9 release"
```

4. Publish hex package

```sh
mix hex.publish package  # if no docs, else `mix hex.publish`
MIX_ENV=docs mix hex.publish docs # To only update the docs
```

If there's an error, delete the tag (e.g. `git tag -d rel-v99.9.9`) and go back to step 1.

5. Git operations

```sh
git push --tags # push all new and changed tags
git branch # verify still on main
git push -u origin main # push upstream at least once
git branch -d rel-v99.9.9 # delete local release branch
```

6. Create release for GitHub project with description containing updated changelog contents
