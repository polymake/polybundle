#!/bin/bash -ex

DIR=$1; shift;
RESDIR=$1; shift;
RELPATH=$1; shift;
SUFFIX=$1; shift;

# possibly remove trailing slash
RESDIR=${RESDIR%/}
echo $RESDIR;

if [ -d $DIR ]; then
	cd $DIR;

	for f in *$SUFFIX; do
		if [ -f $f  -a ! -h $f ]; then
			if file $f | grep -m1 Mach; then
				# there is only one bundle where we nee to replace an @rpath: Gnu.bundle
				# this is because we had to set an rpath during compilation
				if otool -L $f | egrep -o -e "(/Users|@rpath).*dylib" ; then
					dl=`otool -L $f | egrep -o -e "(/Users|@rpath).*dylib"`;
					for d in $dl; do
						echo "found lib:" $d;
						if [[ "$d" =~ ^$RESDIR ]] || [[ "$d" =~ "@rpath" ]]; then
  							lib=${d##*/};    # get the libname
							echo $lib;
							path=${d%/*};    # and the path to it
							path=${path#$RESDIR/}
							echo $path;
							chmod u+w $f;
							install_name_tool -change "$d" "@loader_path/$RELPATH/$lib" $f;
							chmod u-w $f;
						fi;
					done;
				fi;
			fi;
		fi;
	done;
fi;
