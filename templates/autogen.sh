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
make GLUON_BRANCH="$branch" GLUON_TARGET="ar71xx-tiny"  $*
make GLUON_BRANCH="$branch" GLUON_TARGET="ar71xx-generic"  $*
make GLUON_BRANCH="$branch" GLUON_TARGET="ar71xx-nand" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="ipq806x" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="mpc85xx-generic" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="ramips-mt7620" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="ramips-mt7621" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="ramips-mt7628" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="ramips-rt305x" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="sunxi" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="x86-64" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="x86-generic" $*
make GLUON_BRANCH="$branch" GLUON_TARGET="x86-geode" $*

./propagate.sh "$branch"
