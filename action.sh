#!/bin/bash
set -ex
function cleanup() {
	if [ -f /swapfile ];then
		sudo swapoff /swapfile
		sudo rm -rf /swapfile
	fi
	sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
	command -v docker && docker rmi $(docker images -q)
	sudo apt-get -y purge \
		azure-cli* \
		ghc* \
		zulu* \
		hhvm* \
		llvm* \
		firefox* \
		google* \
		dotnet* \
		openjdk* \
		mysql* \
		php*
	sudo apt autoremove --purge -y
}

function init() {
	[ -f sources.list ] && (
		sudo cp -rf sources.list /etc/apt/sources.list
		sudo rm -rf /etc/apt/sources.list.d/* /var/lib/apt/lists/*
		sudo apt-get clean all
	)
	sudo apt-get update
	sudo apt-get -y install subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc zip
	wget -O- https://raw.githubusercontent.com/friendlyarm/build-env-on-ubuntu-bionic/master/install.sh | bash
	sudo apt-get autoremove --purge -y
	sudo apt-get clean
	sudo timedatectl set-timezone Asia/Shanghai
	git config --global user.name "GitHub Action"
	git config --global user.email "action@github.com"
}

function build() {
	if [ -d openwrt ];then
		pushd openwrt
		git pull
		popd
	else
		git clone https://github.com/openwrt/openwrt.git ./openwrt
		[ -f ./feeds.conf.default ] && cat ./feeds.conf.default >> ./openwrt/feeds.conf.default
	fi
	pushd openwrt
	./scripts/feeds update -a
	./scripts/feeds install -a
	[ -d ../patches ] && git am -3 ../patches/*.patch
	[ -d ../files ] && cp -fr ../files ./files
	[ -f ../config ] && cp -fr ../config ./.config
	make defconfig
	make download -j$(nproc)
	make -j$(nproc)
	popd
}

function artifact() {
	ls -a
	mkdir -p ./openwrt-r2s-squashfs-img
	cp ./openwrt/bin/targets/rockchip/armv8/openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-squashfs-sysupgrade.img.gz ./openwrt-r2s-squashfs-img
  	cp ./openwrt/bin/targets/rockchip/armv8/config.buildinfo ./openwrt-r2s-squashfs-img
	zip -r openwrt-r2s-squashfs-img.zip ./openwrt-r2s-squashfs-img

	mkdir -p ./openwrt-r2s-ext4-img
	cp ./openwrt/bin/targets/rockchip/armv8/openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-ext4-sysupgrade.img.gz ./openwrt-r2s-ext4-img
  	cp ./openwrt/bin/targets/rockchip/armv8/config.buildinfo ./openwrt-r2s-ext4-img
	zip -r openwrt-r2s-ext4-img.zip ./openwrt-r2s-ext4-img
}

function auto() {
	cleanup
	init
	build
	artifact
}

$@