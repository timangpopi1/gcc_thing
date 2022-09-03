#!/usr/bin/env bash
# shellcheck disable=SC1117
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
#
echo "cmds : ${@}"
dpkg --add-architecture i386
apt-get update -y
apt-get -y install flex bison ncurses-dev texinfo gcc gperf patch libtool automake g++ libncurses5-dev gawk expat libexpat1-dev python-all-dev binutils-dev libgcc1:i386 bc libgnutls28-dev libcap-dev autoconf autoconf-archive libgmp-dev build-essential gcc-multilib g++-multilib pkg-config libmpc-dev libmpfr-dev autopoint gettext liblzma-dev libssl-dev libz-dev curl cmake ninja-build clang lld
BuildDate="$(date +%Y-%m-%d)"
git config --global user.name "greenforce-auto-build"
git config --global user.email "greenforce-auto-build@users.noreply.github.com"
mkdir -p ~/.git/hooks
git config --global core.hooksPath ~/.git/hooks
curl -Lo ~/.git/hooks/commit-msg https://review.lineageos.org/tools/hooks/commit-msg
chmod u+x ~/.git/hooks/commit-msg
CURRENTMAINPATH="$(pwd)"
rm -rf .git
GCCType="${1}"
GCCVersion="${2}"
GCCTarget="${3}"

cd sources/gcc
SHORT="$(cat gcc/BASE-VER | cut -c 1-2)"
echo "Gf Cross v${SHORT}" > gcc/DEV-PHASE
git rev-parse --short HEAD 2>&1 | tee /tmp/hash_head
git log --pretty="format:%s" | head -n1 2>&1 | tee /tmp/commit_msg
cd $CURRENTMAINPATH
./build -a "${GCCTarget}" -s gnu -v ${GCCVersion} -p gz -V
cd $CURRENTMAINPATH
if [[ ! -e $CURRENTMAINPATH/fail.info ]] && [[ -d ${GCCType} ]];then
    if [[ "${GCCTarget}" == "arm64" ]]; then
        gcc_repo="gcc-arm64"
    elif [[ "${GCCTarget}" == "arm" ]]; then
        gcc_repo="gcc-arm32"
    else
        echo "Can't define what the repo is!"
        exit 1
    fi
    git clone https://${GH_TOKEN}@github.com/greenforce-project/${GCCTarget} -b main $(pwd)/FromGithub --depth=1
    rm -fr $(pwd)/FromGithub/*
    cp -af ${GCCType}/* $(pwd)/FromGithub && cd $(pwd)/FromGithub
    ./bin/${GCCType}-gcc -v 2>&1 | tee /tmp/gcc-version
    ./bin/${GCCType}-ld -v 2>&1 | tee /tmp/ld-version
    gccv=$(cat /tmp/gcc-version | grep "gcc version")
    ldv=$(cat /tmp/ld-version | head -n1)
    hash_head=$(cat /tmp/hash_head)
    commit_msg=$(cat /tmp/commit_msg)
    git add . -f
    template=$(echo -e "
    GCC version: $gccv
    Binutils version: $ldv
    GCC repo commit: $commit_msg
    Link: https://github.com/gcc-mirror/gcc/commit/$hash_head
    ")
    git commit -m "greenforce: Bump to $(date '+%Y%m%d') build" -m "${template}"
    git push -f
    cd $CURRENTMAINPATH
fi
