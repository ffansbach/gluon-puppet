GLUON_SITE_PACKAGES := \
	gluon-alfred \
	gluon-announced \
	gluon-autoupdater \
	gluon-config-mode-core \
	gluon-config-mode-autoupdater \
	gluon-config-mode-hostname \
	gluon-config-mode-mesh-vpn \
	gluon-config-mode-geo-location \
	gluon-config-mode-contact-info \
	gluon-ebtables-filter-multicast \
	gluon-ebtables-filter-ra-dhcp \
	gluon-luci-admin \
	gluon-luci-autoupdater \
	gluon-luci-portconfig \
	gluon-luci-private-wifi \
	gluon-mesh-batman-adv-14 \
	gluon-mesh-vpn-fastd \
	gluon-next-node \
	gluon-radvd \
	gluon-setup-mode \
	gluon-status-page \
	iwinfo \
	iptables \
	haveged \
	ffol-configurator \
	ffol-nodewatcher

# The Version string should be appended seperated by a plus sign
# so it doesn't interfere with the upstream version.  This is how
# "opkg compare-version" works ...
# DEFAULT_GLUON_RELEASE := <%= @gluon_version %>+$(shell date '+%Y%m%d')

# ... however with Gluon 2015.1 we pushed 2015.1.20150910 et al
# that way 2015.1.2.20150920 is considered older however :(
# Stick to old versioning scheme til we upgread to 2015.2 soon.
DEFAULT_GLUON_RELEASE := 2015.1.$(shell date '+%Y%m%d')


# Allow overriding the release number from the command line
GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)

GLUON_PRIORITY ?= 0
GLUON_LANGS ?= de en
