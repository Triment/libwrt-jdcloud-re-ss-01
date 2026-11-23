include $(TOPDIR)/rules.mk

PKG_NAME:=meow
PKG_VERSION:=0.29.0
PKG_RELEASE:=1

PKG_SOURCE:=meow-rs-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/meow-rs/meow-rs/tar.gz/refs/tags/v$(PKG_VERSION)?
PKG_HASH:=e92c0979cd95f16246bfb763da7cab8d66f23a8ec914b61e5dd5813b29b68a11
PKG_BUILD_DIR:=$(BUILD_DIR)/meow-rs-$(PKG_VERSION)

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

MEOW_BINARY_ARCHIVE:=meow-v$(PKG_VERSION)-aarch64-unknown-linux-musl.tar.gz

define Download/meow-binary
  FILE:=$(MEOW_BINARY_ARCHIVE)
  URL:=https://github.com/meow-rs/meow-rs/releases/download/v$(PKG_VERSION)
  HASH:=6fa37f13ddeaafae605e65bc9f2ab0c538b9ab3fad11c8b12180f0a52b4c06b7
endef
$(eval $(call Download,meow-binary))

define Package/meow
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Meow Rust proxy with embedded web dashboard
  URL:=https://github.com/meow-rs/meow-rs
  DEPENDS:=@aarch64 +ca-bundle +ip-full +nftables-json +kmod-tun \
    +kmod-nft-nat +kmod-nft-fib +kmod-nft-socket +kmod-nft-tproxy
endef

define Package/meow/description
 Meow is a mihomo-compatible Rust proxy. This package uses the official
 static aarch64 musl release and its matching OpenWrt service files.
endef

define Package/luci-app-meow
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for Meow
  URL:=https://github.com/meow-rs/meow-rs
  PKGARCH:=all
  DEPENDS:=+luci-base +meow +curl +jsonfilter +rpcd-mod-file
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	mkdir -p $(PKG_BUILD_DIR)/.prebuilt
	tar -xzf $(DL_DIR)/$(MEOW_BINARY_ARCHIVE) -C $(PKG_BUILD_DIR)/.prebuilt --strip-components=1
	test -s $(PKG_BUILD_DIR)/.prebuilt/meow
endef

define Build/Compile
endef

define Package/meow/conffiles
/etc/config/meow
/etc/meow/config.yaml
endef

define Package/meow/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d $(1)/etc/config $(1)/etc/meow
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/.prebuilt/meow $(1)/usr/bin/meow
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openwrt/meow/files/meow.init $(1)/etc/init.d/meow
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openwrt/meow/files/meow-arp.init $(1)/etc/init.d/meow-arp
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/openwrt/meow/files/meow.config $(1)/etc/config/meow
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/openwrt/meow/files/config.yaml $(1)/etc/meow/config.yaml
	$(INSTALL_DIR) $(1)/usr/share/meow $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openwrt/meow/files/gateway.sh $(1)/usr/share/meow/gateway.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openwrt/meow/files/arp-hijack.sh $(1)/usr/share/meow/arp-hijack.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openwrt/meow/files/meow.uci-defaults $(1)/etc/uci-defaults/80_meow
	$(INSTALL_DIR) $(1)/usr/share/licenses/meow $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/LICENSE $(1)/usr/share/licenses/meow/LICENSE
	printf '%s\n' '/etc/meow/' > $(1)/lib/upgrade/keep.d/meow
endef

define Package/meow/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
if [ -f /etc/uci-defaults/80_meow ]; then
  sh /etc/uci-defaults/80_meow || exit 1
  rm -f /etc/uci-defaults/80_meow
fi
/etc/init.d/meow enable
/etc/init.d/meow-arp enable
exit 0
endef

define Package/meow/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
/etc/init.d/meow-arp stop 2>/dev/null || true
/etc/init.d/meow-arp disable 2>/dev/null || true
/etc/init.d/meow stop 2>/dev/null || true
/etc/init.d/meow disable 2>/dev/null || true
exit 0
endef

define Package/luci-app-meow/install
	$(INSTALL_DIR) $(1)/www
	$(CP) $(PKG_BUILD_DIR)/openwrt/luci-app-meow/htdocs/. $(1)/www/
	$(CP) $(PKG_BUILD_DIR)/openwrt/luci-app-meow/root/. $(1)/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openwrt/luci-app-meow/root/usr/libexec/meow-api $(1)/usr/libexec/meow-api
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openwrt/luci-app-meow/root/usr/libexec/meow-validate $(1)/usr/libexec/meow-validate
endef

define Package/luci-app-meow/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
rm -f /tmp/luci-indexcache* 2>/dev/null
/etc/init.d/rpcd reload 2>/dev/null || true
exit 0
endef

$(eval $(call BuildPackage,meow))
$(eval $(call BuildPackage,luci-app-meow))
