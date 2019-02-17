#!/bin/sh -ex

NAME=$1; shift
DIR=$1; shift
DEST=$1; shift

echo installing $NAME from $DIR
cd $DIR/${NAME}_$DEST

make install
