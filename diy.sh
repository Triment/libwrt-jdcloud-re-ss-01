#!/bin/bash
# ==============================================
# LibWrt 定制脚本 - 京东云亚瑟 RE-SS-01
# 1. 默认后台地址改为 192.168.50.1
# 2. 默认 root 密码改为指定哈希
# 3. 默认主题改为 Liquid
# 4. 压缩 RE-SS-01 内核，使带 BTF 的 FIT 镜像适配 6 MiB 上限
# 5. 设置 Honk 的 doona 面板版本
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

# 4. 使用上游 LZMA FIT 规则，保留 6144k 内核上限和 factory 根文件系统偏移。
JD_IMAGE_MK=target/linux/qualcommax/image/Makefile
JD_IMAGE_RULES=target/linux/qualcommax/image/ipq60xx.mk
grep -Fxq 'define Device/FitImageLzma' "$JD_IMAGE_MK" || { echo "[diy] upstream LZMA FIT rule missing" >&2; exit 1; }
if ! awk '
  /^define Device\/jdcloud_re-ss-01$/ { in_device = 1 }
  /^endef$/ { in_device = 0 }
  in_device && /\$\(call Device\/FitImage(Lzma)?\)/ {
    sub(/Device\/FitImage\)/, "Device/FitImageLzma)")
    count++
  }
  in_device && /^[[:space:]]*KERNEL_SIZE[[:space:]]*:=[[:space:]]*6144k[[:space:]]*$/ { limit_ok = 1 }
  { print }
  END { if (count != 1 || !limit_ok) exit 1 }
' "$JD_IMAGE_RULES" > "$JD_IMAGE_RULES.tmp"; then
  echo "[diy] expected one RE-SS-01 FIT rule with a 6144k kernel limit" >&2
  exit 1
fi
mv "$JD_IMAGE_RULES.tmp" "$JD_IMAGE_RULES"
echo "[diy] RE-SS-01 kernel: LZMA FIT, limit 6144k"

# 5. 选择默认面板，保留官方配置中的接口、认证和直连路由默认值。
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
