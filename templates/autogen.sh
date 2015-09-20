#! /bin/sh -xe
cd /srv/gluon-<%= @community %>

[ -d .git ] || git init

if [ "$1" = "" ]; then
  branch=stable
else
  branch="$1"; shift
fi

git remote rm origin || true
git remote add origin https://github.com/freifunk-gluon/gluon.git

git fetch origin
git checkout v2015.1.1

make update
make GLUON_BRANCH="$branch" GLUON_TARGET="ar71xx-generic" $*

./propagate.sh "$branch"
