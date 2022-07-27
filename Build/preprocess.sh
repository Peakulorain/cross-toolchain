#!/bin/bash 

set -e

ROOT_DIR=`pwd`/../

###Download first.
#sh download.sh


sh env_install.sh

rm -rf $ROOT_DIR/Obj/*
mkdir -p $ROOT_DIR/Obj/
cp -rf $ROOT_DIR/Source/* $ROOT_DIR/Obj/

cd $ROOT_DIR/Obj/
for f in *.tar*; do tar xvf $f; done
cd -
