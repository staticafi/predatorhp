#!/bin/bash

# This script makes three versions of predator in three different directories
# needs git, cmake, GCC, gcc-7-plugin-dev, etc. --  see README*

# number of processor units
NCPU="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"

# git repository checkout
cloneAndMerge() {
    BASEBRANCH=post-svcomp3
    DIR=$1
    BRANCH=$2
    (
    cd $DIR
    git init

    git config user.email "xjasek@fi.muni.cz"
    git config user.name "Tomas Jasek"

    git remote add origin https://github.com/staticafi/predator.git
    git fetch --depth 5
    git checkout $BASEBRANCH
    git merge -m "automatic merge commit" origin/$BRANCH
    )
}

# predator build
cd_make () {
  topdir=$(pwd)
  pushd $1

  grep -v "ctest" switch-host-llvm.sh > switch-host-llvm2.sh
  mv switch-host-llvm2.sh switch-host-llvm.sh
  chmod +x switch-host-llvm.sh
  ./switch-host-llvm.sh /var/tmp/xjasek/symbiotic/llvm-8.0.1/build/lib/cmake/llvm/

  pushd passes-src/passes
  grep -v "\-Wl" CMakeLists.txt > CMakeLists.new
  mv CMakeLists.new CMakeLists.txt
  popd

  ./switch-host-llvm.sh /var/tmp/xjasek/symbiotic/llvm-8.0.1/build/lib/cmake/llvm/
  pushd passes-src/passes_build
  make
  popd

  pushd sl_build
  patch check-property.sh $topdir/check-property.patch
  popd

  cp -r passes-src/passes_build .
  cp passes_build/libpasses.so sl_build/

  pushd build-aux
  echo "patching cclib"
  patch cclib.sh $topdir/cclib.patch
  popd

  popd
}

# delete already existing build-dirs
rm -rf predator predator-bfs predator-dfs
rm predator-build-ok

# copy
mkdir predator predator-dfs predator-bfs
cloneAndMerge predator     svcomp-orig
cloneAndMerge predator-dfs svcomp-dfs
cloneAndMerge predator-bfs svcomp-bfs

# make all versions of predators
cd_make predator && cd_make predator-bfs && cd_make predator-dfs
if [ $? != 0 ]; then
	echo "Instalation failed!"
	exit 1
fi
# mark successful completion
echo "Installation completed."
date >predator-build-ok

