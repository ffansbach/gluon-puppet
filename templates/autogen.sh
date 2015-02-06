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

git pull origin master

make update
make GLUON_BRANCH="$branch" $*
make manifest GLUON_BRANCH="$branch"

<% if @auto_update_seckey_file %>
contrib/sign.sh <%= @auto_update_seckey_file %> "images/sysupgrade/$branch.manifest"
<% end %>

mkdir -p /srv/firmware-<%= @community %>/$branch/
cp -Rapv images/* /srv/firmware-<%= @community %>/$branch/

