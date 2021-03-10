#!/usr/bin/env bash
dpkg --add-architecture i386
apt-get update -y
apt-get -y install flex bison ncurses-dev texinfo gcc gperf patch libtool automake g++ libncurses5-dev gawk expat libexpat1-dev python-all-dev binutils-dev libgcc1:i386 bc libgnutls28-dev libcap-dev autoconf autoconf-archive libgmp-dev build-essential gcc-multilib g++-multilib pkg-config libmpc-dev libmpfr-dev autopoint gettext liblzma-dev libssl-dev libz-dev

# CurrentMainPath="$(pwd)"
rm -rf .git

PushChanges(){
    dumpGCCVer="$(./bin/aarch64-linux-gnu-gcc -dumpversion)"
    GitBranch="${dumpGCCVer}-$(date +"%Y%m%d")"
    GCCVer="$(./bin/aarch64-linux-gnu-gcc --version | head -n 1)"
    git checkout -b "${GitBranch}"
    git add . && git commit -s -m "aarch64 GCC '$GCCVer' | Date : $(date +"%Y-%m-%d")" && git push -f origin "${GitBranch}"
}

PushChangesArm(){
    dumpGCCVer="$(./bin/arm-linux-gnueabi-gcc -dumpversion)"
    GitBranch="${dumpGCCVer}-$(date +"%Y%m%d")"
    GCCVer="$(./bin/arm-linux-gnueabi-gcc --version | head -n 1)"
    git checkout -b "${GitBranch}"
    git add . && git commit -s -m "arm GCC '$GCCVer' | Date : $(date +"%Y-%m-%d")" && git push -f origin "${GitBranch}"
}

./build -a arm64 -s gnu -v 10

cd aarch64-linux-gnu
git init && git remote add origin https://${GIT_SECRETB}@github.com/ZyCromerZ/aarch64-linux-gnu.git
PushChanges
cd ..

./build -a arm -s gnu -v 10

cd arm-linux-gnueabi
git init && git remote add origin https://${GIT_SECRETB}@github.com/ZyCromerZ/arm-linux-gnueabi.git
PushChangesArm
cd ..

rm -rf *