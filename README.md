# LibWrt 京东云无线宝亚瑟 RE-SS-01 · Honk 双面板固件

`honk` 分支基于 [LibWrt](https://github.com/LiBwrt/LibWrt) 的 `25.12-nss` 分支，为京东云无线宝亚瑟 RE-SS-01 自动编译两套 [Honk](https://github.com/daeuniverse/honk) 固件：doona 标准面板版和 doona Lite 面板版。

## 设备信息

| 项目 | 值 |
|---|---|
| 设备 | 京东云无线宝 亚瑟 RE-SS-01 |
| SoC | Qualcomm IPQ6000 |
| Target | qualcommax / ipq60xx |
| 内存 / 闪存 | 512MB / 128G eMMC |
| 分区 | 2G 大分区 + Hugo Uboot |

## 内置功能

- **代理**：Honk `v0.1.0-beta.6`，含 eBPF 数据路径、原生 API、Clash API 和内嵌 doona 面板。
- **代理服务管理**：`luci-app-honk`，在 LuCI 中启动、停止、设置开机启动和编辑配置。
- **异地组网**：VNT2。
- **DDNS**：DDNS-GO。
- **界面**：Liquid 主题。

本分支移除 Run 安装器、dae / daed 软件包。Honk 所需的 eBPF、BTF、cgroup、网络命名空间和 NFQUEUE 内核支持保留在两套固件中。

Honk 软件包使用 [daeuniverse 官方 OpenWrt 源](https://github.com/daeuniverse/openwrt-packages)，固定在提交 `e104a4930c5fc4f625f3355257626495685424f5`。构建时读取 Honk 源码固定的 Rust 工具链和 bpf-linker 版本，并校验 bpf-linker 与面板下载的 SHA-256。Honk 当前为上游 Beta 版本。

DDNS-GO 前端和后端使用 LibWrt 默认的 ImmortalWrt 软件源。额外软件源只按需安装 VNT2、Honk、Honk 的 LuCI 前端和共享库、内置 BTF 占位包；已移除 kenzok8/small-package 软件源，避免重复包与不兼容的 Kconfig 定义。配置阶段会检查循环依赖和必需软件包，产物阶段会再次核对固件清单。

## 默认登录信息

- 后台地址：`http://192.168.50.1`
- 用户名：`root`
- 密码：`admin@cd`

## Honk 面板

1. 进入 LuCI「服务 → honk」，启动服务，并按需开启开机启动。
2. 访问 `http://192.168.50.1:9527/`，首次访问创建面板管理员。面板账号独立于 LuCI 的 root 账号。
3. 添加节点或订阅、代理组和路由规则。默认配置使用 `br-lan`、WAN 自动识别和全直连路由。

Honk 配置在 `/etc/honk/config.dae`，状态数据在 `/etc/honk/data`。日志在 LuCI 服务页面或 `logread -e honk` 中查看。默认面板监听端口 9527，沿用 OpenWrt 防火墙的 LAN 访问范围。

## 固件说明

每次 CI 构建产出两个面板版本，每个版本包含首次刷机和在线升级镜像，共四个 `.bin` 文件：

| 面板版本 | 默认 Honk UI 配置 | 文件名前缀 | Actions Artifact |
|---|---|---|---|
| doona 标准版 | `ui: 'embedded'` | `honk-doona-standard-` | `jdcloud_re-ss-01_honk_doona_standard` |
| doona Lite 版 | `ui: 'embedded-lite'` | `honk-doona-lite-` | `jdcloud_re-ss-01_honk_doona_lite` |

两套固件使用相同的完整 Honk 后端和软件包，差别是默认面板。上游 `native-ui` 同时内嵌标准版和 Lite 版资源；Lite 固件仍包含两套资源，在 `/etc/honk/config.dae` 中修改 `ui` 后重启 Honk 可切换面板。

RE-SS-01 的内核 FIT 镜像使用 LibWrt 的 LZMA 压缩规则，以减小带 BTF 的内核体积；内核上限仍为 `6144k`，factory 镜像的根文件系统偏移沿用设备定义。若内核仍超限，构建会失败。编译失败时，Actions 的 `honk-diagnostics-standard` 或 `honk-diagnostics-lite` Artifact 会保留编译日志、配置日志和构建配置。

- **`*-squashfs-factory.bin`**：U-Boot 刷入版本（Hugo Uboot + 原厂 CDT + 大分区 GPT，首次刷机用）。
- **`*-squashfs-sysupgrade.bin`**：在线升级版本（已刷 LibWrt 后，LuCI 内不保留配置升级用）。

两个版本构建成功后统一发布到 **Releases**，标签为 `honk-v<构建编号>`。每个版本还附带软件包清单、完整构建配置、Honk 默认配置、版本记录和 `SHA256SUMS`。若其中一版失败，成功版仍可从 Actions 下载，Release 等两版都成功后发布。

> 刷机方法：进入 Hugo Uboot，选择 `squashfs-factory.bin` 刷入；首次刷完约 5 分钟，之后重启 15 秒开机。

## 如何重新触发编译

- 手动触发：仓库 `Actions` → `Build LibWrt JDCloud RE-SS-01 Honk` → `Run workflow`，选择 `honk` 分支。
- 推送代码到 `honk` 分支也会自动触发两套面板固件的构建。
- 更新 Honk 时，同步调整工作流中的 `HONK_GIT_TAG`、apk 格式的 `HONK_VERSION` 和对应软件包源提交 `HONK_FEED_COMMIT`。

## 文件结构

```
.
├── .github/workflows/build.yml   # 标准版 / Lite 版构建矩阵与统一发布
├── .config                       # 设备、Honk 和内核支持配置
├── diy.sh                        # IP、密码、Liquid 主题、默认 doona 版本
└── README.md
```
