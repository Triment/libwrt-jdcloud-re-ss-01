# LibWrt 京东云无线宝亚瑟 RE-SS-01 · Meow 固件

`meow` 分支基于 [LibWrt](https://github.com/LiBwrt/LibWrt) 的 `25.12-nss` 分支，为京东云无线宝亚瑟 RE-SS-01 构建内置 [meow-rs](https://github.com/meow-rs/meow-rs) 的固件。

## 设备信息

| 项目 | 值 |
|---|---|
| 设备 | 京东云无线宝亚瑟 RE-SS-01 |
| SoC | Qualcomm IPQ6000 |
| Target | qualcommax / ipq60xx |
| 内存 / 闪存 | 512MB / 128G eMMC |
| 分区 | 2G 大分区 + Hugo Uboot |

## 内置功能

- **代理**：Meow `v0.29.0` 官方完整静态 musl 核心，兼容 mihomo / Clash Meta 配置，内嵌 Web 面板。
- **代理管理**：`luci-app-meow`，提供服务状态、订阅与节点管理、YAML 配置、透明代理设置和日志。
- **透明代理**：nftables TCP REDIRECT + UDP TPROXY，包含所需内核模块、`ip-full` 和 TUN 支持。
- **异地组网**：VNT2。
- **DDNS**：DDNS-GO，使用 LibWrt 默认 ImmortalWrt 软件源。
- **界面**：Liquid 主题。

本分支移除 Honk、doona、dae/daed、Run 安装器及其软件源、面板矩阵和专用构建工具链，取消 BTF、cgroup BPF、NFQUEUE 和旧 v2ray geodata 的显式选择。Meow 的透明代理使用 nftables。

原生软件包定义位于 `package/meow/Makefile`，注册 `meow` 和 `luci-app-meow`。核心使用官方 aarch64 静态发布文件，服务脚本和 LuCI 文件来自同一个 `v0.29.0` 标签；两份下载均固定 SHA-256，由 OpenWrt 下载流程校验。固件在 GitHub Actions 中编译。

## 默认登录信息

- 后台地址：`http://192.168.50.1`
- 用户名：`root`
- 密码：`admin@cd`

## 使用 Meow

1. 进入 LuCI「服务 → meow」，添加订阅或编辑 `/etc/meow/config.yaml` 中的节点、代理组和规则。
2. 启用并启动 Meow。默认规则为 `MATCH,DIRECT`，服务默认关闭。
3. 在「面板」页面管理代理，或访问 `http://192.168.50.1:9090/ui`。首次启动前的初始化会生成 API 密钥；从 LuCI 进入面板时会自动携带密钥。
4. 按需在设置中启用「透明代理」，默认使用逻辑接口 `lan`、代理端口 7893 和 DNS 端口 1053。透明代理默认关闭，TCP+UDP 模式使用 IPv4。

普通 HTTP/SOCKS5 混合代理端口为 7890。Meow 配置、缓存和状态保存在 `/etc/meow/`，服务设置在 `/etc/config/meow`，日志可在 LuCI 中查看或执行 `logread -e meow`。Meow 的 ARP 客户端转发功能沿用上游默认关闭状态。

## 固件产物

每次构建产出一套 Meow 固件，包含两个镜像：

- **`meow-*-squashfs-factory.bin`**：Hugo U-Boot 首次刷入。
- **`meow-*-squashfs-sysupgrade.bin`**：LuCI 在线升级。

RE-SS-01 内核使用 LZMA FIT 压缩，保留设备定义的 `6144k` 内核上限和 factory 根文件系统偏移。两种镜像均会检查 Meow 软件包和 nftables/TUN 内核支持，并检查旧代理组件是否被选入。

Actions Artifact 名称为 `jdcloud_re-ss-01_meow`，Release 标签为 `meow-v<构建编号>`。同时附带软件包清单、完整构建配置、版本记录和 `meow-SHA256SUMS`。构建失败时，`meow-diagnostics` Artifact 保存编译日志、配置日志及构建配置。

## 触发编译与更新

- 推送到 `meow` 分支会自动触发构建。
- 手动触发：Actions → `Build LibWrt JDCloud RE-SS-01 Meow` → `Run workflow`，选择 `meow` 分支。
- 更新 Meow 时，同步修改 `package/meow/Makefile` 的版本与两份 SHA-256，以及工作流的 `MEOW_VERSION`。工作流会检查版本一致性。

## 文件结构

```text
.
├── .github/workflows/build.yml   # Meow 构建与发布
├── .config                       # 设备、Meow 和透明代理模块配置
├── package/meow/Makefile          # 官方核心与 LuCI 的原生软件包定义
├── diy.sh                        # IP、密码、Liquid 主题和内核压缩
└── README.md
```
