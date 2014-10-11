#! /bin/sh -xe
cd /srv/gluon-<%= @community %>

[ -d .git ] || git init

git remote rm origin || true
git remote add origin https://github.com/freifunk-gluon/gluon.git

git pull origin master

make update
make $*
