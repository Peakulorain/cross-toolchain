#!/bin/bash

set -e

sh preprocess.sh

ROOT_DIR=`pwd`/..
PREFIX=$ROOT_DIR/Install
SYSROOT=$PREFIX/sysroot

GMP=gmp-6.1.2
MPFR=mpfr-4.0.2
MPC=mpc-1.1.0
ISL=isl-0.21
BINUTILS=binutils-2.32
KERNEL_HEADS=linux-4.4
GCC=gcc-9.1.0
GLIBC=glibc-2.28

BUILD=`gcc -dumpmachine`
HOST=`gcc -dumpmachine`
TARGET=aarch64-linux

rm -rf $ROOT_DIR/Obj/build-gmp
mkdir -p $ROOT_DIR/Obj/build-gmp
cd $ROOT_DIR/Obj/build-gmp
../$GMP/configure --prefix=$PREFIX/host-lib --disable-shared 
make -j && make install
cd -

rm -rf $ROOT_DIR/Obj/build-mpfr
mkdir -p $ROOT_DIR/Obj/build-mpfr
cd $ROOT_DIR/Obj/build-mpfr
../$MPFR/configure --prefix=$PREFIX/host-lib --with-gmp=$PREFIX/host-lib --disable-shared
make && make install
cd -

rm -rf $ROOT_DIR/Obj/build-mpc
mkdir -p $ROOT_DIR/Obj/build-mpc
cd $ROOT_DIR/Obj/build-mpc
../$MPC/configure --prefix=$PREFIX/host-lib --with-gmp=$PREFIX/host-lib --with-mpfr=$PREFIX/host-lib --disable-shared
make && make install
cd -

rm -rf $ROOT_DIR/Obj/build-isl
mkdir -p $ROOT_DIR/Obj/build-isl
cd $ROOT_DIR/Obj/build-isl
CFLAGS="-O2 -I$PREFIX/host-lib/include -L$PREFIX/host-lib/lib" ../$ISL/configure --prefix=$PREFIX/host-lib --with-gmp=$PREFIX/host-lib --disable-shared
make && make install
cd -

rm -rf $ROOT_DIR/Obj/build-binutils
mkdir -p $ROOT_DIR/Obj/build-binutils
cd $ROOT_DIR/Obj/build-binutils
../$BINUTILS/configure --prefix=$PREFIX --build=$BUILD --host=$HOST --target=$TARGET 
make && make install
cd -

rm -rf $ROOT_DIR/Obj/build-kernel
mkdir -p $ROOT_DIR/Obj/build-kernel
cd $ROOT_DIR/Obj/build-kernel
make -C ../$KERNEL_HEADS ARCH=arm64 INSTALL_HDR_PATH=$SYSROOT/usr headers_install
cd -

rm -rf $ROOT_DIR/Obj/build-gcc
mkdir -p $ROOT_DIR/Obj/build-gcc
cd $ROOT_DIR/Obj/build-gcc
CFLAGS="-O2 -I$PREFIX/host-lib/include -L$PREFIX/host-lib/lib" \
CXXFLAGS="-O2 -I$PREFIX/host-lib/include -L$PREFIX/host-lib/lib" \
../$GCC/configure --prefix=$PREFIX --build=$BUILD --host=$HOST --target=$TARGET --enable-languages=c,c++ --disable-multilib --disable-libsanitizer \
       --with-gmp=$PREFIX/host-lib --with-mpfr=$PREFIX/host-lib --with-mpc=$PREFIX/host-lib --with-isl=$PREFIX/host-lib \
       --with-sysroot=$SYSROOT --with-build-sysroot=$SYSROOT
make CFLAGS_FOR_TARGET=--sysroot=$SYSROOT prefix=$PREFIX exec_prefix=$PREFIX -j4 all-gcc
make install-gcc
cd -

#build  c header files
rm -rf $ROOT_DIR/Obj/build-glibc-head
mkdir -p $ROOT_DIR/Obj/build-glibc-head
cd $ROOT_DIR/Obj/build-glibc-head
CC="$PREFIX/bin/$TARGET-gcc" \
CFLAGS="-O2 -Wno-error -Wno-missing-attributes" \
../$GLIBC/configure --prefix=$SYSROOT/usr --build=$BUILD --host=$TARGET --target=$TARGET \
        --with-headers=$SYSROOT/usr/include --disable-multilib libc_cv_forced_unwind=yes  --disable-compile-warnings libc_cv_c_cleanup=yes --disable-profile 
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
mkdir -p $SYSROOT/usr/lib/
cp -rf csu/crt1.o csu/crti.o csu/crtn.o $SYSROOT/usr/lib/
$PREFIX/bin/$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $SYSROOT/usr/lib/libc.so
touch $SYSROOT/usr/include/gnu/stubs.h
cd -

#build target libgcc
cd $ROOT_DIR/Obj/build-gcc
make CFLAGS_FOR_TARGET=--sysroot=$SYSROOT prefix=$PREFIX exec_prefix=$PREFIX -j4 all-target-libgcc
make install-target-libgcc
cd -

#build standard c lib
rm -rf $ROOT_DIR/Obj/build-glibc
mkdir -p $ROOT_DIR/Obj/build-glibc
cd $ROOT_DIR/Obj/build-glibc
CC="$PREFIX/bin/$TARGET-gcc" \
CFLAGS="-O2 -Wno-error -Wno-missing-attributes" \
../$GLIBC/configure --prefix=/usr --build=$BUILD --host=$TARGET --target=$TARGET \
        --with-headers=$SYSROOT/usr/include --disable-multilib libc_cv_forced_unwind=yes  --disable-compile-warnings libc_cv_c_cleanup=yes --disable-profile
make -j4 
make install_root=$SYSROOT install
cd -

#build target libstdc++
cd $ROOT_DIR/Obj/build-gcc
make -j4 
make install
cd -
