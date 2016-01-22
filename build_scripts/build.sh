#!/bin/sh -ex


# TARNAME : name of the tarball (minus the file ending)
# NAME : name of the directory the tarball extracts to
# note that we need both variables as gmp comes as 6.0.0a but extracts to 6.0.0
# DIR : name of the base dir we are extracting the tarball into
# DEST: suffix for directory we build in
TARNAME=$1; shift
TAR_DIR=$1; shift;
NAME=$1; shift
DIR=$1; shift
DEST=$1; shift

suffix=`ls $TAR_DIR/$TARNAME.* | egrep -o -e "tar.(bz2|gz)"

echo building $NAME in $DIR
mkdir -p $DIR/${NAME}_$DEST
if [[ $suffix =~ .*gz.* ]]; then
  tar xfz $TAR_DIR/$TARNAME.$suffix -C $DIR
else
  tar xfj $TAR_DIR/$TARNAME.$suffix -C $DIR
fi
cd $DIR/${NAME}_$DEST
../$NAME/configure "$@"

make
