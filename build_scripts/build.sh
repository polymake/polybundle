#!/bin/sh -ex


# TARNAME : name of the tarball (minus the file ending)
# NAME : name of the directory the tarball extracts to 
# note that we need both variables as gmp comes as 6.0.0a but extracts to 6.0.0
# DIR : name of the base dir we are extracting the tarball into
# DEST: suffix for directory we build in
TARNAME=$1; shift
NAME=$1; shift
DIR=$1; shift
DEST=$1; shift

echo building $NAME in $DIR
mkdir -p $DIR/${NAME}_$DEST
tar xvfj src/$TARNAME.tar.bz2 -C $DIR
cd $DIR/${NAME}_$DEST
../$NAME/configure $*

make
