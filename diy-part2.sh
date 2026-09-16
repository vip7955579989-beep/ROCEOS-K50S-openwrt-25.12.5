#!/bin/bash
# Description: OpenWrt 25.12.5 DIY script part 2 (Target: ROCEOS K50S)

# 1. 统一管理后台 IP 为 192.168.0.254
sed -i 's/192.168.1.1/192.168.0.254/g' package/base-files/files/bin/config_generate || true

# 2. 设备树注入到 rockchip 平台目录
mkdir -p target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/
cp -f patches/rk3568-roc-k50s.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/ || true
cp -f patches/rk3568-roc-k50s.dtsi target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/ || true

# 3. 准备 U-Boot 引导镜像至编译目录与产物输出目录
mkdir -p staging_dir/target-aarch64_generic_musl/image/
mkdir -p bin/targets/rockchip/armv8/
if [ -f k50s-rk3568-u-boot-rockchip.bin ]; then
    cp -f k50s-rk3568-u-boot-rockchip.bin staging_dir/target-aarch64_generic_musl/image/k50s-rk3568-u-boot-rockchip.bin || true
    cp -f k50s-rk3568-u-boot-rockchip.bin staging_dir/target-aarch64_generic_musl/image/k50s-rk3568-u-boot.bin || true
    cp -f k50s-rk3568-u-boot-rockchip.bin staging_dir/target-aarch64_generic_musl/image/k50s-rk3568-boot.bin || true
fi

# 4. 注册 ROCEOS K50S 设备定义到 armv8.mk（使用 rockchip-gpt-img 宏）
ARMV8_MAKEFILE="target/linux/rockchip/image/armv8.mk"

if [ -f "$ARMV8_MAKEFILE" ]; then
    # 防止重复追加
    sed -i '/define Device\/roceos_k50s/,/TARGET_DEVICES += roceos_k50s/d' "$ARMV8_MAKEFILE"

    cat << 'EOF' >> "$ARMV8_MAKEFILE"

define Device/roceos_k50s
  DEVICE_VENDOR := ROCEOS
  DEVICE_MODEL := K50S
  SOC := rk3568
  DEVICE_DTS := rockchip/rk3568-roc-k50s
  UBOOT_DEVICE_NAME := k50s-rk3568
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | rockchip-gpt-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-r8125 kmod-r8169 kmod-phy-realtek kmod-usb-storage kmod-usb-storage-uas
endef
TARGET_DEVICES += roceos_k50s
EOF
fi
