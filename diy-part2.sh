#!/bin/bash
# Description: OpenWrt DIY script part 2 (Configuration modification)

# 0. 自动定位上级目录/工作区根目录
BASE_DIR="${GITHUB_WORKSPACE:-..}"

# 1. 修改默认管理后台 IP 为 192.168.0.254
sed -i 's/192.168.1.1/192.168.0.254/g' package/base-files/files/bin/config_generate || true

# 2. 全路径精准注入 DTS / DTSI 到 target 文件树
mkdir -p target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/
mkdir -p target/linux/rockchip/dts/
if [ -d "$BASE_DIR/patches" ]; then
  cp -vf "$BASE_DIR/patches/rk3568-roc-k50s.dts"* target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/ 2>/dev/null || true
  cp -vf "$BASE_DIR/patches/rk3568-roc-k50s.dts"* target/linux/rockchip/dts/ 2>/dev/null || true
elif [ -d "patches" ]; then
  cp -vf patches/rk3568-roc-k50s.dts* target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/ 2>/dev/null || true
  cp -vf patches/rk3568-roc-k50s.dts* target/linux/rockchip/dts/ 2>/dev/null || true
fi

# 3. 注入 U-Boot 引导镜像
mkdir -p staging_dir/target-aarch64_generic_musl/image/
mkdir -p bin/targets/rockchip/armv8/

UBOOT_BIN=""
if [ -f "$BASE_DIR/k50s-rk3568-u-boot-rockchip.bin" ]; then
  UBOOT_BIN="$BASE_DIR/k50s-rk3568-u-boot-rockchip.bin"
elif [ -f "k50s-rk3568-u-boot-rockchip.bin" ]; then
  UBOOT_BIN="k50s-rk3568-u-boot-rockchip.bin"
fi

if [ -n "$UBOOT_BIN" ]; then
  echo "Injecting U-Boot from $UBOOT_BIN"
  cp -vf "$UBOOT_BIN" staging_dir/target-aarch64_generic_musl/image/k50s-rk3568-u-boot-rockchip.bin
  cp -vf "$UBOOT_BIN" staging_dir/target-aarch64_generic_musl/image/k50s-rk3568-u-boot.bin
  cp -vf "$UBOOT_BIN" bin/targets/rockchip/armv8/k50s-rk3568-u-boot-rockchip.bin || true
fi

# 4. 注册 ROCEOS K50S 设备定义到 armv8.mk
ARMV8_MAKEFILE="target/linux/rockchip/image/armv8.mk"
IMAGE_MAKEFILE="target/linux/rockchip/image/Makefile"

if [ -f "$IMAGE_MAKEFILE" ]; then
  if ! grep -q "define Build/boot-combine" "$IMAGE_MAKEFILE"; then
    sed -i '1i define Build/boot-combine\n\t@true\nendef\n' "$IMAGE_MAKEFILE"
  fi
fi

if [ -f "$ARMV8_MAKEFILE" ]; then
  sed -i '/define Device\/roceos_k50s/,/TARGET_DEVICES += roceos_k50s/d' "$ARMV8_MAKEFILE"
  cat << 'EOF' >> "$ARMV8_MAKEFILE"
define Device/roceos_k50s
  DEVICE_VENDOR := ROCEOS
  DEVICE_MODEL := K50S
  SOC := rk3568
  DEVICE_DTS := rockchip/rk3568-roc-k50s
  UBOOT_DEVICE_NAME := k50s-rk3568
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | gzip | append-metadata
  DEVICE_PACKAGES := kmod-r8125 kmod-r8169 kmod-phy-realtek kmod-usb-storage kmod-usb-storage-uas
endef
TARGET_DEVICES += roceos_k50s
EOF
fi
