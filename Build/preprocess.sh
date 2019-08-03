#!/bin/bash 

set -e

ROOT_DIR=`pwd`/../

rm -rf $ROOT_DIR/Obj/*
cp -rf $ROOT_DIR/Source/* $ROOT_DIR/Obj

cd $ROOT_DIR/Obj/
for f in *.tar*; do tar xf $f; done
cd -
