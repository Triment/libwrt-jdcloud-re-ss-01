#!/bin/bash
# ==============================================
# LibWrt 定制脚本 - 京东云亚瑟 RE-SS-01
# 1. 默认后台地址改为 192.168.50.1
# 2. 默认 root 密码改为指定哈希
# 3. 默认主题改为 Liquid
# 4. 设置 Honk 的 doona 面板版本
# ==============================================
set -e

# 1. 修改默认 LAN IP（192.168.1.1 -> 192.168.50.1）
sed -i 's/192\.168\.1\.1/192.168.50.1/g' package/base-files/files/bin/config_generate

# 2. 修改默认 root 密码
sed -i 's|^root:[^:]*:|root:$5$FEvKqB47IGg0kMEb$0L5AE92U9CgakKhWSKdBuK/vAzL/GaOqmEkR1oxUbd5:|' package/base-files/files/etc/shadow

# 3. 设置默认主题为liquid
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-custom << 'EOF'
#!/bin/sh
uci set luci.main.mediaurlbase='/luci-static/liquid'
uci commit luci
exit 0
EOF
chmod +x files/etc/uci-defaults/99-custom

# 4. 选择默认面板，保留官方配置中的接口、认证和直连路由默认值。
case "${HONK_EDITION:-standard}" in
  standard) HONK_UI=embedded ;;
  lite) HONK_UI=embedded-lite ;;
  *) echo "[diy] unsupported Honk edition: ${HONK_EDITION}" >&2; exit 1 ;;
esac
HONK_CONFIG=feeds/daeuniverse/honk/files/config.dae
if ! awk -v ui="$HONK_UI" '
  $1 == "ui:" { $0 = "        ui: \047" ui "\047"; count++ }
  { print }
  END { if (count != 1) exit 1 }
' "$HONK_CONFIG" > "$HONK_CONFIG.tmp"; then
  echo "[diy] expected exactly one active ui setting in $HONK_CONFIG" >&2
  exit 1
fi
mv "$HONK_CONFIG.tmp" "$HONK_CONFIG"
echo "[diy] Honk UI: $HONK_UI"

echo "[diy] customize done"
