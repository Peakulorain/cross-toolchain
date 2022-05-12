#!/bin/bash 

set -e

ROOT_DIR=`pwd`/../
rm -rf $ROOT_DIR/Source/*

cd $ROOT_DIR/Source/

######Download source packages from net
wget https://ftp.gnu.org/gnu/gmp/gmp-6.2.0.tar.xz
if [ ! -f "gmp-6.2.0.tar.xz" ]; then
	echo "download link unavailable. please download gmp from other site."
	exit 1
fi

wget https://ftp.gnu.org/gnu/mpc/mpc-1.2.0.tar.gz
if [ ! -f "mpc-1.2.0.tar.gz" ]; then
        echo "download link unavailable. please download mpc from other site."
        exit 1
fi

wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.1.0.tar.gz
if [ ! -f "mpfr-4.1.0.tar.gz" ]; then
        echo "download link unavailable. please download mpfr from other site."
        exit 1
fi

wget https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2
if [ ! -f "isl-0.24.tar.bz2" ]; then
        echo "download link unavailable. please download isl from other site."
        exit 1
fi

wget https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.gz
if [ ! -f "gcc-10.2.0.tar.gz" ]; then
        echo "download link unavailable. please download gcc from other site."
        exit 1
fi

wget https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.gz
if [ ! -f "binutils-2.38.tar.gz" ]; then
        echo "download link unavailable. please download binutils from other site."
        exit 1
fi

#wget https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/linux-4.19.209.tar.gz
#if [ ! -f "linux-4.19.209.tar.gz" ]; then
#        echo "download link unavailable. please download linux kernel from other site."
#        exit 1
#fi

wget https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.16.tar.gz
if [ ! -f "linux-5.16.tar.gz" ]; then
        echo "download link unavailable. please download linux kernel from other site."
        exit 1
fi

wget https://ftp.gnu.org/gnu/glibc/glibc-2.32.tar.gz
if [ ! -f "glibc-2.32.tar.gz" ]; then
        echo "download link unavailable. please download glibc from other site."
        exit 1
fi

cd -
