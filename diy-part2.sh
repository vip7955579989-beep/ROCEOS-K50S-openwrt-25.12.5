#!/bin/bash
# Description: OpenWrt DIY script part 2 (Configuration modification)

# 1. 修改默认管理后台 IP 为 192.168.0.254
sed -i 's/192.168.1.1/192.168.0.254/g' package/base-files/files/bin/config_generate || true

# 2. 注入 DTS 设备树到 rockchip 对应目录
mkdir -p target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/
cp -f patches/rk3568-roc-k50s.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/ || true
cp -f patches/rk3568-roc-k50s.dtsi target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/ || true

# 3. 注入 U-Boot 镜像到编译临时目录
mkdir -p staging_dir/target-aarch64_generic_musl/image/
mkdir -p bin/targets/rockchip/armv8/
if [ -f k50s-rk3568-u-boot-rockchip.bin ]; then
    cp -f k50s-rk3568-u-boot-rockchip.bin staging_dir/target-aarch64_generic_musl/image/k50s-rk3568-u-boot-rockchip.bin || true
    cp -f k50s-rk3568-u-boot-rockchip.bin staging_dir/target-aarch64_generic_musl/image/k50s-rk3568-u-boot.bin || true
fi

# 4. 注册 ROCEOS K50S 设备定义到 armv8.mk（采用官方原生打包规则）
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
