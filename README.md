# LibWrt 京东云无线宝亚瑟 RE-SS-01 云编译

基于 [LibWrt](https://github.com/LiBwrt/LibWrt)（分支 `25.12-nss`，满血 NSS）为京东云无线宝亚瑟（RE-SS-01 / IPQ6000 / 512MB / 64G eMMC）自动编译固件。

## 设备信息

| 项目 | 值 |
|---|---|
| 设备 | 京东云无线宝 亚瑟 RE-SS-01 |
| SoC | Qualcomm IPQ6000 |
| Target | qualcommax / ipq60xx |
| 内存 / 闪存 | 512MB / 64G eMMC |
| 分区 | 2G 大分区 + Hugo Uboot |

## 内置功能

- **科学上网**：PassWall2
- **文件共享**：Samba4 + USB/eMMC 自动挂载（ext4/ntfs/exfat/vfat）
- **内网穿透 / DDNS**：DDNS-GO + 传统 DDNS（阿里云 / DNSPod）
- **VPN**：WireGuard
- **网络**：UPnP、dnsmasq-full
- **界面 / 工具**：Argon 主题、ttyd 网页终端、FileBrowser 网页文件管理

## 默认登录信息

- 后台地址：`http://10.0.0.1`
- 用户名：`root`
- 密码：`root`

## 固件说明

编译产物在 **Releases**（或 Actions 的 Artifacts）中，两个版本：

- **`squashfs-factory.bin`** —— uboot 刷入版本（Hugo Uboot + 原厂 CDT + 大分区 GPT，首次刷机用）
- **`squashfs-sysupgrade.bin`** —— 在线升级版本（已刷 LibWrt 后，LuCI 内不保留配置升级用）

> 刷机方法：进入 Hugo Uboot，选择 `squashfs-factory.bin` 刷入；首次刷完约 5 分钟，之后重启 15 秒开机。

## 如何重新触发编译

- 手动触发：仓库 `Actions` → `Build LibWrt JDCloud RE-SS-01` → `Run workflow`
- 推送代码到 `main` 分支也会自动触发

## 文件结构

```
.
├── .github/workflows/build.yml   # GitHub Actions 编译流程
├── .config                       # OpenWrt 种子配置（目标 + 软件包）
├── diy.sh                        # 定制脚本（IP/密码/主题）
└── README.md
```
