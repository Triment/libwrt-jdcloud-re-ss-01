#!/bin/bash
# ==============================================
# LibWrt 定制脚本 - 京东云亚瑟 RE-SS-01
# 1. 默认后台地址改为 192.168.50.1
# 2. 默认 root 密码改为指定哈希
# 3. 默认主题改为 Liquid
# 4. 使用 LZMA 内核压缩，保留 RE-SS-01 镜像布局
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

echo "[diy] customize done"
