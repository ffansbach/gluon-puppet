#! /bin/sh -xe
cd /srv/gluon-<%= @community %>

if [ "$1" = "" ]; then
  branch=stable
else
  branch="$1"; shift
fi

rm -f output/images/sysupgrade/*.manifest
if [ "$NOUPDATE" != "1" ]; then
  make manifest GLUON_BRANCH="$branch"
<% if @auto_update_seckey_file %>
  contrib/sign.sh <%= @auto_update_seckey_file %> "output/images/sysupgrade/$branch.manifest"
<% end %>
fi
rm -rf /srv/firmware-<%= @community %>/$branch
mkdir -p /srv/firmware-<%= @community %>/$branch/
cp -Rapv output/images/* /srv/firmware-<%= @community %>/$branch/
cp -Rapv output/packages/ /srv/firmware-<%= @community %>/$branch/
