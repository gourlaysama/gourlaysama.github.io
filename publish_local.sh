#!/usr/bin/env bash

set -eu -o pipefail

root_dir="$(git rev-parse --show-toplevel)"
pushd $root_dir

tmp_dir="$(mktemp -d)"
sha="$(git rev-parse --short @)"

git checkout sources
bundle exec jekyll build -d "$tmp_dir"
git checkout rendered
rm -rf *
cp --preserve --recursive "$tmp_dir"/* .
git add *
git commit --message="from $sha"
git checkout sources

popd