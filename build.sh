#!/bin/sh -ex

NAME=$1; shift
DIR=$1; shift
DEST=$1; shift

echo building $NAME in $DIR
mkdir -p $DIR/${NAME}_$DEST
tar xvfj tarballs/$NAME.tar.bz2 -C $DIR
cd $DIR/${NAME}_$DEST
../$NAME/configure $*

make
