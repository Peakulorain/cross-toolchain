## What's a cross-toolchain?

Let's show some conceptions below,

- Build:	The machine you are building compiler on.
- Host:	The machine that you are building compiler for.
- Target:	The machine that compiler will produce code for.

If build, host, and target are all the same, this is called a *native*. If build and host are the same but target is different, that is called a *cross*.[^1]



## How to build a cross-toolchain?

Next, we will use the construction of an arm64(aarch64) cross-toolchain based on GCC as an example.

| Machine | Architecture-OS |
| ------- | --------------- |
| Build   | x86_64-linux    |
| Host    | x86_64-linux    |
| Target  | aarch64-linux   |

##### 1. Work Env

Ubuntu 18.04.2 LTS

```shell
$ lsb_release -a
Distributor ID: Ubuntu
Description:    Ubuntu 18.04.2 LTS
Release:        18.04
Codename:       bionic
```

##### 2. Prerequisites

​	[gmp-6.1.2.tar.bz2](<https://ftp.gnu.org/gnu/gmp/>)
​	[mpfr-4.0.2.tar.gz](https://ftp.gnu.org/gnu/mpfr/)
​	[mpc-1.1.0.tar.gz](https://ftp.gnu.org/gnu/mpc/)
​	[isl-0.21.tar.gz](http://isl.gforge.inria.fr/)
​	[binutils-2.32.tar.gz](https://ftp.gnu.org/gnu/binutils/)
​	[linux-4.4.tar.gz](https://cdn.kernel.org/pub/linux/kernel/v4.x/)
​	[gcc-9.1.0.tar.gz](https://ftp.gnu.org/gnu/gcc/)
​	[glibc-2.28.tar.gz](https://ftp.gnu.org/gnu/glibc/)

Firstly, we should create directories in a root directory,

```shell
mkdir -p Build  Obj  Source
```

Directory *Build*  is for Linux Shell scripts. Directory *Obj*  is for Temporary Files.  Directory *Source* is for Source Code Packages.

To build a whole cross-toolchains, some common declares for my *build.sh* in *Build* directory were listed as below:

```shell
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
```

##### 3. Build Dependent Libraries

###### gmp

GMP is a free library for arbitrary precision arithmetic, operating on signed integers, rational numbers, and floating-point numbers.[^2]

```shell
../$GMP/configure --prefix=$PREFIX/host-lib --disable-shared
make -j && make install
```

###### mpfr

The MPFR library is a C library for multiple-precision floating-point computations with *correct rounding*. [^3] And MPFR depends on GMP.

```shell
../$MPFR/configure --prefix=$PREFIX/host-lib --with-gmp=$PREFIX/host-lib --disable-shared
make && make install
```

###### mpc

GNU MPC is a C library for the arithmetic of complex numbers with arbitrarily high precision and correct rounding of the result.[^4] And it is upon MPFR.

```shell
CFLAGS="-O2 -I$PREFIX/host-lib/include -L$PREFIX/host-lib/lib" ../$ISL/configure --prefix=$PREFIX/host-lib --with-gmp=$PREFIX/host-lib --disable-shared
make && make install
```

###### isl

isl is a library for manipulating sets and relations of integer points bounded by linear constraints.[^5]
GCC will execute loop structure analysis by enable isl part.

```shell
CFLAGS="-O2 -I$PREFIX/host-lib/include -L$PREFIX/host-lib/lib" ../$ISL/configure --prefix=$PREFIX/host-lib --with-gmp=$PREFIX/host-lib --disable-shared
make && make install
```

##### 4. Build Cross Assembler and Cross Linker

The GNU Binutils are a collection of binary tools.[^6]

```shell
../$BINUTILS/configure --prefix=$PREFIX --build=$BUILD --host=$HOST --target=$TARGET
make && make install
```

##### Install Target linux kernel headers

While building a target program,  it's necessary to obtain the interface definition of the target kernel. 

```shell
make -C ../$KERNEL_HEADS ARCH=arm64 INSTALL_HDR_PATH=$SYSROOT/usr headers_install

```

We can install headers to a specialized directory named *sysroot* for cross-toolchain. The C library headers and binary lib files will also be installed there. The *sysroot* directory is a target program building dependency.

##### 5. Build C/C++ Compiler and Standard Target C library

It's easy to build a **C/C++ Compiler** binary files, but it's difficult to build the **Target**  libraries without target dependent run-time libraries.This part we will discuss how to build the   **Target**  libraries step by step.

###### Step 1

We need to build  C/C++ Compiler by using gcc source codes, but the result just include C/C++ Compiler binary files which can run on host environment while can produce target program without any links to target run-time libraries.

```shell
../$GCC/configure --prefix=$PREFIX --build=$BUILD --host=$HOST --target=$TARGET --enable-languages=c,c++ --disable-multilib --disable-libsanitizer \
       --with-gmp=$PREFIX/host-lib --with-mpfr=$PREFIX/host-lib --with-mpc=$PREFIX/host-lib --with-isl=$PREFIX/host-lib \
       --with-sysroot=$SYSROOT --with-build-sysroot=$SYSROOT
make CFLAGS_FOR_TARGET=--sysroot=$SYSROOT prefix=$PREFIX exec_prefix=$PREFIX -j4 all-gcc
make install-gcc

```

Assign *--build=$BUILD --host=$HOST --target=$TARGET* to build a cross compiler.
Assign *make all-gcc* to do not build target libraries.

###### Step 2

Use Compiler buit in **Step 1** to build Glibc headers.

```shell
../$GLIBC/configure --prefix=$SYSROOT/usr --build=$BUILD --host=$TARGET --target=$TARGET --with-headers=$SYSROOT/usr/include --disable-multilib libc_cv_forced_unwind=yes  --disable-compile-warnings libc_cv_c_cleanup=yes --disable-profile
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
mkdir -p $SYSROOT/usr/lib/
cp -rf csu/crt1.o csu/crti.o csu/crtn.o $SYSROOT/usr/lib/
$PREFIX/bin/$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $SYSROOT/usr/lib/libc.so

```

This step we installed Glibc headers and a **NULL** libc.so because that building a target libgcc will link to libc.so in source scripts, but libgcc does not depend on libc.so.

###### Step 3

Build Target libgcc.

```shell
make CFLAGS_FOR_TARGET=--sysroot=$SYSROOT prefix=$PREFIX exec_prefix=$PREFIX -j4 all-target-libgcc
make install-target-libgcc

```

Assign *make all-target-libgcc* to  build target libgcc.
The glibc denpends on libgcc.

###### Step 4

Build Taget Glibc, the whole Standard Target C library.

```shell
../$GLIBC/configure --prefix=/usr --build=$BUILD --host=$TARGET --target=$TARGET \
        --with-headers=$SYSROOT/usr/include --disable-multilib libc_cv_forced_unwind=yes  --disable-compile-warnings libc_cv_c_cleanup=yes --disable-profile
make -j4
make install_root=$SYSROOT install

```

We installed library files to *sysroot*.

###### Step 5

Build all target libraries in GCC.

```shell
cd $ROOT_DIR/Obj/build-gcc
make -j4
make install
cd -

```

At this point, the cross-toolchain was built entirely.

## Project Address

You can see more in .

## Others

This project refers to many other people's practices. If there are infringements, please contact me. If you have any questions, welcome to communicate with me by 

------

[^1]: <https://gcc.gnu.org/onlinedocs/gccint/Configure-Terms.html>
[^2]: <https://gmplib.org/>
[^3]: <https://www.mpfr.org/>
[^4]: <http://www.multiprecision.org/mpc/>
[^5]: <http://isl.gforge.inria.fr/>
[^6]: <https://www.gnu.org/software/binutils/>

