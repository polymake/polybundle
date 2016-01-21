
#!/bin/sh -ex

DIR=$1; shift
LIBDIR=$1; shift
FILE=$1; shift
LIBNAME=$1; shift
RELPATH=$1; shift;



cd $DIR;
install_name_tool -change "$LIBDIR/$LIBNAME" "@rpath/$LIBNAME" $FILE; 
