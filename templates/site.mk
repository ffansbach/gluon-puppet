GLUON_SITE_PACKAGES := \
	gluon-respondd \
	gluon-autoupdater \
	gluon-config-mode-core \
	gluon-config-mode-autoupdater \
	gluon-config-mode-hostname \
	gluon-config-mode-mesh-vpn \
	gluon-config-mode-geo-location \
	gluon-config-mode-contact-info \
	gluon-ebtables-filter-multicast \
	gluon-ebtables-filter-ra-dhcp \
	gluon-web-admin \
	gluon-web-autoupdater \
	gluon-web-network \
	gluon-web-private-wifi \
	gluon-mesh-batman-adv-14 \
	gluon-mesh-vpn-fastd \
	gluon-radvd \
	gluon-setup-mode \
	gluon-status-page \
	iwinfo \
	iptables \
	haveged \
	ffol-configurator \
	ffol-nodewatcher \
	ath9k-broken-wifi-workaround

ifeq ($(GLUON_TARGET),x86-generic)
GLUON_SITE_PACKAGES += \
    kmod-usb-core \
    kmod-usb2 \
    kmod-usb-hid \
    kmod-usb-net \
    kmod-usb-net-asix \
    kmod-usb-net-dm9601-ether \
    kmod-r8169
endif

# The Version string should be appended seperated by a plus sign
# so it doesn't interfere with the upstream version.  This is how
# "opkg compare-version" works ...
# Probable issue still is the upstream versioning which is sometimes
# YYYY.M and sometimes YYYY.M.D (D=digit)
DEFAULT_GLUON_RELEASE := <%= @gluon_version %>+$(shell date '+%Y%m%d')

# Allow overriding the release number from the command line
GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)

GLUON_ATH10K_MESH ?= 11s
GLUON_PRIORITY ?= 0
GLUON_LANGS ?= de en
GLUON_REGION ?= eu
