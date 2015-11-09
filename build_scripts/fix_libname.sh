#!/bin/sh -ex

DIR=$1; shift
SUFFIX=$1; shift
RELPATH=$1; shift


cd $DIR; 
for f in *$SUFFIX; do
	if [ -f $f  -a ! -h $f ]; then
		if file $f | grep -m1 Mach; then 
			chmod u+w $f
			if [ -s $RELPATH ]; then 
				install_name_tool -id "@rpath/$RELPATH/$f" $f; 
			else
				install_name_tool -id "@rpath/$f" $f; 
			fi;			
			chmod u-w $f
		fi;
	fi;
done;