#!/bin/sh -ex

DIR=$1; shift
FILE=$1; shift



cd $DIR; 
install_name_tool -id "@rpath/$FILE" $FILE; 
