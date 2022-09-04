#!/usr/bin/env bash
# shellcheck disable=SC1117
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
#
echo "cmds : ${@}"

CURRENTMAINPATH="$(pwd)"

GCCType="${1}"
GCCVersion="${2}"
GCCTarget="${3}"

bash build -a "${GCCTarget}" \
        -s gnu \
        -v ${GCCVersion} \
        -p gz -V

if [[ ! -e $CURRENTMAINPATH/fail.info ]] && [[ -d ${GCCType} ]];then
    if [[ "${GCCTarget}" == "arm64" ]]; then
        gcc_repo="gcc-arm64"
    elif [[ "${GCCTarget}" == "arm" ]]; then
        gcc_repo="gcc-arm32"
    else
        echo "Can't define what the repo is!"
        exit 1
    fi
    git clone https://${GH_TOKEN}@github.com/greenforce-project/${gcc_repo} -b main
    cd ${gcc_repo} && git reset --hard c74c2b1a048d842337ff503a3cd4c057a880188f && cd ..
    rm -fr $(pwd)/${gcc_repo}/*
    cp -af ${GCCType}/* "$(pwd)/${gcc_repo}" && cd "$(pwd)/${gcc_repo}"
    ./bin/${GCCType}-gcc -v 2>&1 | tee /tmp/gcc-version
    ./bin/${GCCType}-ld -v 2>&1 | tee /tmp/ld-version
    gccv=$(cat /tmp/gcc-version | grep "gcc version")
    ldv=$(cat /tmp/ld-version | head -n1)
    hash_head=$(cat /tmp/hash_head)
    commit_msg=$(cat /tmp/commit_msg)
    git add . -f
    template=$(echo -e "GCC version: $gccv
Binutils version: $ldv
GCC repo commit: $commit_msg
Link: https://github.com/gcc-mirror/gcc/commit/$hash_head")
    git commit -m "greenforce: Bump to $(date '+%Y%m%d') build" -m "${template}" --signoff
    git push -f
fi
