# ROCEOS K50S OpenWrt 25.12.5 固件定制项目

本项目基于 [OpenWrt 官方源码](https://github.com/openwrt/openwrt)（分支：`v25.12.5`，Linux 6.12 内核），针对 **ROCEOS K50S (Rockchip RK3568)** 网络软路由硬件进行设备树（DTS）补丁注入、网卡驱动适配及 GPT 引导打包。

---

## 硬件规格与接口映射

* **SoC 主控**：Rockchip RK3568 (Quad-Core Cortex-A55 @ 2.0GHz)
* **内存/存储**：板载 LPDDR4x + eMMC / TF (MicroSD) 卡槽
* **扩展接口**：M.2 NVMe 扩展槽（JMicron JMS583 PCIe-USB3 桥接方案）
* **物理网口排布与默认网络映射**：

| 物理面板标识 | 控制器与总线 | PHY / 驱动 | 接口名 | 默认网络角色 | 默认 IP / DHCP |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LAN0**（电口） | PCIe3x2 (`&pcie3x2`) | RTL8125BG (2.5G) | `eth0` | **LAN** (桥接 `br-lan`) | `192.168.0.254`（开启 DHCP） |
| **LAN1**（电口） | PCIe3x1 (`&pcie3x1`) | RTL8125BG (2.5G) | `eth1` | **LAN** (桥接 `br-lan`) | `192.168.0.254`（开启 DHCP） |
| **LAN2**（电口） | PCIe2x1 (`&pcie2x1`) | RTL8125BG (2.5G) | `eth2` | **LAN** (桥接 `br-lan`) | `192.168.0.254`（开启 DHCP） |
| **ETH3**（上光口） | GMAC0 (`&gmac0`) | RTL8211F (千兆 SFP) | `eth3` | **WAN** | DHCP 客户端（自动获取外网 IP） |
| **ETH4**（下光口） | GMAC1 (`&gmac1`) | RTL8211F (千兆 SFP) | `eth4` | **WAN6 / 预留 WAN2** | 可配置双宽带并发 (Multi-WAN) |

---

## 固件特性与关键修复

1. **引导修复（Bootloader Fix）**：采用瑞芯微官方原生 `rockchip-gpt-img` 打包宏，将 RK3568 U-Boot 与 GPT 分区签名注入第 64 扇区，彻底解决启动不引导、RUN 绿灯不亮的问题。
2. **根分区扩容**：RootFS 扩容至 **1024MB**，Kernel 分区扩容至 **64MB**，预留充足插件空间。
3. **M.2 扩展支持**：集成 `kmod-usb-storage`、`kmod-usb-storage-uas`、`e2fsprogs` 与 `fdisk`，原生支持 JMS583 M.2 扩展盘。
4. **开箱即用体验**：集成 LuCI 简体中文 Web 界面，默认管理后台地址为 `http://192.168.0.254`。

---

## 快速上手与刷机指南

### 方式一：TF卡 / MicroSD 启动（推荐首选，零风险）

1. 从本仓库 **Releases** 下载最新生成的 `*squashfs-sysupgrade.img.gz`。
2. 使用 7-Zip 或 WinRAR 解压得到 `.img` 镜像文件。
3. 打开 **Rufus**（版本 4.0+）或 **BalenaEtcher**：
   * 选择 TF 卡盘符与解压出的 `.img` 镜像。
   * Rufus 提示时选择 **以 DD 镜像模式写入**。
4. 写入完成后安全弹出 TF 卡，平整插入 ROCEOS K50S 的 TF 卡槽，接通电源。
5. **开机验证**：上电约 10~15 秒后，机身 **RUN 绿灯** 将进入规律的心跳闪烁（Heartbeat）。
6. 用网线连接机身 **LAN0 电口**，浏览器访问 `http://192.168.0.254` 登录后台（默认用户名 `root`，密码为空）。

### 方式二：RKDevTool 线刷入板载 eMMC

1. 打开 **RKDevTool**（瑞芯微开发工具 v2.84+），安装驱动助手。
2. K50S 断电，按住 RST 键插入双公头 USB 数据线并通电，进入 **MASKROM** 模式。
3. 切换至 **【下载镜像】** 标签页：
   * 勾选第 1 行 `Loader`，选择 `k50s-rk3568-u-boot-rockchip.bin`。
   * 勾选第 2 行 `System`，地址填 `0x00000000`，选择解压后的 `.img` 文件。
   * 勾选 **强制按地址写**，点击 **【执行】** 即可完成写入。

---

## 项目编译流程

本项目已配置 GitHub Actions 全自动云编译流水线：

1. Fork 或 Clone 本仓库。
2. 进入 GitHub 仓库的 **Actions** 页面。
3. 选择 **Build OpenWrt 25.12.5 for ROCEOS K50S** 工作流。
4. 点击 **Run workflow** 即可全自动编译并发布 Release 固件。
