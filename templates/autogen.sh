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
git checkout v<%= @gluon_version %>

make update
export GLUON_RELEASE=$(make show-release)
for TARGET in $(make list-targets); do
  make GLUON_BRANCH="$branch" GLUON_TARGET=$TARGET  $*
done

./propagate.sh "$branch"
