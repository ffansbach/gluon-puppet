#! /bin/sh -xe
cd /srv/gluon-<%= @community %>

[ -d .git ] || git init

git remote rm origin || true
git remote add origin https://github.com/freifunk-gluon/gluon.git

git pull origin master

make update
make GLUON_BRANCH=stable $*
make manifest GLUON_BRANCH=stable

<% if @auto_update_seckey_file %>
contrib/sign.sh <%= @auto_update_seckey_file %> images/sysupgrade/stable.manifest
<% end %>
