##	GLUON_FEATURES
#		Specify Gluon features/packages to enable;
#		Gluon will automatically enable a set of packages
#		depending on the combination of features listed
GLUON_FEATURES := \
	autoupdater \
	ebtables-filter-multicast \
	ebtables-filter-ra-dhcp \
	ebtables-limit-arp \
	mesh-batman-adv-14 \
	mesh-vpn-fastd \
	radvd \
	radv-filterd \
	respondd \
	status-page \
	web-advanced \
	web-wizard

##	GLUON_SITE_PACKAGES
#		Specify additional Gluon/LEDE packages to include here;
#		A minus sign may be prepended to remove a packages from the
#		selection that would be enabled by default or due to the
#		chosen feature flags
GLUON_SITE_PACKAGES := \
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

GLUON_MULTIDOMAIN ?= 0
GLUON_ATH10K_MESH ?= 11s
GLUON_PRIORITY ?= 0
GLUON_LANGS ?= de en
GLUON_REGION ?= eu
