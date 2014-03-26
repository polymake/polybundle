
# this Makefile is for OS X 10.8 or 10.9
# includes compilation of a proper gcc

### change into the base directory
###BASEPATH := $( (cd -P $(dirname $0) && pwd) )
SED := "/usr/bin/sed"
TMP := $(CURDIR)/tmp
PERL := /usr/bin/perl

MACVERSION := $(shell sw_vers | grep -o "10[.][0-9]")
PERLVERSION := $(shell $(PERL) --version | grep -o "5[.][0-9]*[.][0-9]")

PREFIX := $(CURDIR)/polymake.app/Contents/Resources


### pick the right gcc
CC := $(PREFIX)/bin/gcc
CXX :=$(PREFIX)/bin/g++

### only 64bit, first for gcc, second for perl (with gcc)
#CFLAGS="-arch x86_64"
#ARCHFLAGS='-arch x86_64'
CFLAGS="  -m64 -mtune=generic"
CXXFLAGS="  -m64 -mtune=generic"

.PHONY: all skeleton boost ppl gcc rpath perl gmp readline mpfr ant singular polymake-prepare polymake-compile dmg clean clean-install polymake-install polymake-docs relative-paths doc polymake-executable xsexternal_error

### default target
all : skeleton gmp_build gmp mpfr_build mpfr ppl_build ppl readline_build readline perl boost ant singular polymake-prepare polymake-compile polymake-install polymake_env_var polymake_name polymake_rpath polymake-executable clean-install doc dmg  

xsexternal_error : polymake-compile polymake-install polymake_env_var polymake_name polymake_rpath polymake-executable clean-install doc dmg

### create the polymake package skeleton
skeleton : 
	@mkdir -p polymake.app/Contents/Resources
	@mkdir -p polymake.app/Contents/MacOS


	@cd scripts; $(SED) 's/REPLACE_PERLVERSION/${PERLVERSION}/g' polymake.start > polymake.start.tmp; 
	@cd scripts; $(SED) 's/REPLACE_PERLVERSION/${PERLVERSION}/g' polymake.debug > polymake.debug.tmp; 
	@install -m 550 scripts/polymake polymake.app/Contents/MacOS/
	@install -m 550 scripts/polymake.start.tmp polymake.app/Contents/MacOS/polymake.start
	@install -m 550 scripts/polymake.debug.tmp polymake.app/Contents/MacOS/polymake.debug
	@install -m 550 scripts/debug.commands polymake.app/Contents/Resources/
	@cd scripts; rm polymake.start.tmp;
	@cd scripts; rm polymake.debug.tmp;

	@cp scripts/Info.plist polymake.app/Contents/
	@cp scripts/*.icns polymake.app/Contents/Resources/

gmp_build :
	@./build.sh gmp-5.1.3 "$(TMP)" build \
	--prefix=$(PREFIX) --enable-cxx=yes

gmp_install :
	@./install.sh gmp-5.1.3 "$(TMP)" build
	
gmp_name :
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libgmpxx.4.dylib" "libgmp.10.dylib"
##############
	@./fix_libname.sh "$(PREFIX)/lib" "libgmpxx.4.dylib" 
	@./fix_libname.sh "$(PREFIX)/lib" "libgmp.10.dylib"
	
gmp : gmp_install gmp_name
 
mpfr_build : 
	@./build.sh mpfr-3.1.2 "$(TMP)" build \
	--prefix=$(PREFIX) --with-gmp=$(PREFIX) LDFLAGS="-Wl,-rpath,$(PREFIX)/lib"

mpfr_install : 
	@./install.sh mpfr-3.1.2 "$(TMP)" build

mpfr_name :
		@./fix_libname.sh "$(PREFIX)/lib" "libmpfr.4.dylib" 
	
mpfr : mpfr_install mpfr_name

ppl_build : 
	@./build.sh ppl-1.1 "$(TMP)" build \
	  --prefix=$(PREFIX) --with-gmp=$(PREFIX) --with-mpfr=$(PREFIX) LDFLAGS="-Wl,-rpath,$(PREFIX)/lib"

ppl_install : 
	@./install.sh ppl-1.1 "$(TMP)" build

ppl_name :
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libppl.13.dylib" "libppl_c.4.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libppl_c.4.dylib" "libppl.13.dylib"
##############
	@./fix_libname.sh "$(PREFIX)/lib" "libppl_c.4.dylib" 
	@./fix_libname.sh "$(PREFIX)/lib" "libppl.13.dylib" 

ppl : ppl_install ppl_name

ant : 
	@tar xvfj tarballs/apache-ant-1.9.3-bin.tar.bz2 -C $(PREFIX)

readline_build :
	@echo building readline in $(TMP) 
	@mkdir -p $(TMP)
	@tar xvfz tarballs/readline-6.2.tar.gz -C $(TMP)
### fix the arch flag settings for compilation
	@${SED} -i '' -e 's|-arch_only `/usr/bin/arch`|-dynamiclib|g' $(TMP)/readline-6.2/support/shobj-conf
	@cd $(TMP)/readline-6.2; ./configure --prefix=$(PREFIX)
	@make -C $(TMP)/readline-6.2
	@make -C $(TMP)/readline-6.2 install

readline :
	@cd $(PREFIX)/lib; chmod u+w libreadline.6.2.dylib;  chmod u+w libhistory.6.2.dylib
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libreadline.6.2.dylib" "libgcc_s.1.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libhistory.6.2.dylib" "libgcc_s.1.dylib"	
##############
	@./fix_libname.sh "$(PREFIX)/lib" "libreadline.6.2.dylib" 
	@./fix_libname.sh "$(PREFIX)/lib" "libhistory.6.2.dylib" 


### XML-LibXSLT
### Term-Gnu-Readline
perl : 
	@tar xvfz tarballs/XML-LibXSLT-1.71.tar.gz -C $(TMP)
	@cd $(TMP)/XML-LibXSLT-1.71; ARCHFLAGS='-arch x86_64' /usr/bin/perl Makefile.PL PREFIX=$(PREFIX)  
	@make -C $(TMP)/XML-LibXSLT-1.71
	@make -C $(TMP)/XML-LibXSLT-1.71 install
### term-readline-gnu
	@tar xvfz tarballs/Term-ReadLine-Gnu-1.20.tar.gz -C $(TMP)
### have to pass ARCHFLAG again?
	@cd $(TMP)/Term-ReadLine-Gnu-1.20; ARCHFLAGS='-arch x86_64' $(PERL) Makefile.PL PREFIX=$(PREFIX) CXXFLAGS="-Wl,-rpath,$(PREFIX)/lib" --includedir=$(PREFIX)/include --libdir=$(PREFIX)/lib 
	@make -C $(TMP)/Term-ReadLine-Gnu-1.20
	@make -C $(TMP)/Term-ReadLine-Gnu-1.20 install 

boost : 
	@tar xfj tarballs/boost_1_47_0.tar.bz2 -C polymake.app/Contents/Resources/include
### remove junk
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/doc
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/tools
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/status
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/more
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/libs
	
singular :
	@cd $(TMP); mkdir -p singular
	@cd $(TMP)/singular; if [ ! -d Sources/.git ]; then git clone https://github.com/Singular/Sources; fi
	@cd $(TMP)/singular/Sources; git checkout master
	# we patch a file, so we should fix the revision we use
	@cd $(TMP)/singular/Sources; git checkout 75a95804a920c32ef1483488eebbcb533a7f701a
	@cd $(TMP)/singular/Sources; $(SED) 's|exec_prefix=${prefix}/${ac_cv_singuname}|exec_prefix=${prefix}|g' configure > configure.tmp; mv configure.tmp configure; chmod a+x configure
	#@cd $(TMP)/singular/Sources; patch -p0 < ../../../scripts/singular-patch
	@cd $(TMP)/singular/Sources; $(PERL5LIB) CPPFLAGS="-fpic -DPIC -DLIBSINGULAR" LDFLAGS="-L$(PREFIX)/lib/ -Wl,-rpath,$(PREFIX)/lib" CFLAGS="-I$(PREFIX)/include/ -fpic -DPIC -DLIBSINGULAR" ./configure --without-dynamic-kernel --without-MP --prefix=$(PREFIX)
	@make -C $(TMP)/singular/Sources install-libsingular
	@./fix_libname.sh "$(PREFIX)/lib" "libsingular.dylib" 
	

### fix the snapshot we use: This is necessary as we apply patches obtained from latest trunk. This will fail for newer snapshots
polymake-prepare : 
	@cd $(TMP); mkdir -p polymake-beta; cd polymake-beta; svn checkout --username "guest" --password "" http://polymake.mathematik.tu-darmstadt.de/svn/polymake/snapshots/20131128/ .
	@cd $(TMP)/polymake-beta; patch -p0 < ../../scripts/java_configure_pl-patch
	@cd $(TMP)/polymake-beta; patch -p0 < ../../scripts/libnormaliz_configure_pl-patch
	cd $(TMP)/polymake-beta; LD_LIBRARY_PATH=$(PREFIX)/lib PERL5LIB=$(PREFIX)/lib/perl5/site_perl/$(PERLVERSION)/darwin-thread-multi-2level/:$(PREFIX)/lib/perl5/ ./configure  --without-fink --with-readline=$(PREFIX)/lib --prefix=$(PREFIX)/polymake --with-jni-headers=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$(MACVERSION).sdk/System/Library/Frameworks/JavaVM.framework/Headers --with-boost=$(PREFIX)/include/boost_1_47_0/ --with-gmp=$(PREFIX)/ --with-ppl=$(PREFIX)/  --with-mpfr=$(PREFIX)/ --with-ant=$(PREFIX)/apache-ant-1.9.3/bin/ant PERL=$(PERL) --with-singular=$(PREFIX) CXXFLAGS="-I$(PREFIX)/include" LDFLAGS="-L$(PREFIX)/lib/ -stdlib=libstdc++"  CXXFLAGS="-Wl,-rpath,$(PREFIX)/lib -m64 -mtune=generic -I/usr/include/c++/4.2.1" CFLAGS=" -m64 -mtune=generic" 

polymake-compile :
	@make -j2 -C $(TMP)/polymake-beta

polymake-docs :
	@make -j2 -C $(TMP)/polymake-beta docs

polymake-install : 
	@make -C $(TMP)/polymake-beta install

polymake_env_var :
### adjust the polymake script to the new paths
	@cd $(PREFIX)/polymake/bin; chmod u+w polymake; $(SED) 's/.*InstallTop=.*/   $$InstallTop=\"$$ENV\{POLYMAKE_BASE_PATH\}\/share\/polymake\";/' polymake | $(SED) 's/.*InstallArch=.*/   $$InstallArch=\"$$ENV\{POLYMAKE_BASE_PATH\}\/lib\/polymake\";/' | $(SED) '/.*addlibs=.*/d' > polymake.tmp; mv polymake.tmp polymake
	@cd $(PREFIX)/polymake/bin; chmod u+w polymake-config; $(SED) 's/.*InstallArch=.*/   $$InstallArch=\"$$ENV\{POLYMAKE_BASE_PATH\}\/lib\/polymake\";/' polymake-config > polymake-config.tmp; mv polymake-config.tmp polymake-config
### and adjust conf.make for polymake and all bundled extensions
# FIXME using \S etc. in a regexp apparently does not work for Mac's sed, so we assume that the path to the current directory is not too strange
	@cd $(PREFIX)/polymake/lib/polymake; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake/bundled/group; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake/bundled/java; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake/bundled/jreality; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake/bundled/libnormaliz; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake/bundled/nauty; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake/bundled/ppl; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
# fun thing: ppl puts its path into the header
	@cd $(PREFIX)/include; \
	chmod u+w ppl.hh; \
	$(SED) 's/\# .*//g' ppl.hh | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/\./g' > ppl.hh.tmp; mv ppl.hh.tmp ppl.hh
	
polymake_name :
	@chmod u+w $(PREFIX)/polymake/lib/libpolymake.dylib
	@chmod u+w $(PREFIX)/polymake/lib/libpolymake-apps.dylib
	@chmod u+w $(PREFIX)/polymake/lib/libpolymake-apps.2.12.dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake.dylib" $(PREFIX)/polymake/lib/libpolymake.dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake-apps.dylib" $(PREFIX)/polymake/lib/libpolymake-apps.dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake-apps.2.12.dylib" $(PREFIX)/polymake/lib/libpolymake-apps.2.12.dylib
#########	
	@chmod u+w $(PREFIX)/lib/perl5/site_perl/$(PERLVERSION)/darwin-thread-multi-2level/auto/Term/ReadLine/Gnu/Gnu.bundle; install_name_tool -change "$(PREFIX)/lib/libreadline.6.2.dylib" "@rpath/libreadline.6.2.dylib" $(PREFIX)/lib/perl5/site_perl/$(PERLVERSION)/darwin-thread-multi-2level/auto/Term/ReadLine/Gnu/Gnu.bundle
	@chmod u+w $(PREFIX)/polymake/lib/polymake/lib/*.bundle 
	@chmod u+w $(PREFIX)/polymake/lib/polymake/perlx/$(PERLVERSION)/darwin-thread-multi-2level/auto/Polymake/Ext/Ext.bundle
	@chmod u+w $(PREFIX)/polymake/lib/polymake/lib/jni/libpolymake_java.jnilib
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/libpolymake.dylib
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/libpolymake.dylib	
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/common.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/common.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/core.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/core.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/graph.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/graph.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/group.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/group.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/matroid.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/matroid.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/polytope.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/polytope.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/topaz.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/topaz.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/tropical.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/tropical.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.4.dylib" "@rpath/libmpfr.4.dylib" $(PREFIX)/polymake/lib/polymake/lib/fan.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/polymake/lib/polymake/lib/fan.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/lib/libppl_c.4.dylib
	@install_name_tool -change "$(PREFIX)/lib/libppl.13.dylib" "@rpath/libppl.13.dylib" $(PREFIX)/lib/libppl_c.4.dylib
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/lib/libppl.13.dylib
	@install_name_tool -change "$(PREFIX)/lib/libgmp.10.dylib" "@rpath/libgmp.10.dylib" $(PREFIX)/lib/libmpfr.4.dylib

polymake_rpath :
	@chmod u+w $(PREFIX)/polymake/lib/libpolymake.dylib
	@chmod u+w $(PREFIX)/polymake/lib/polymake/lib/*.bundle 
	@chmod u+w $(PREFIX)/polymake/lib/polymake/perlx/$(PERLVERSION)/darwin-thread-multi-2level/auto/Polymake/Ext/Ext.bundle
	@chmod u+w $(PREFIX)/polymake/lib/polymake/bundled/*/lib/*.bundle 
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/libpolymake.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/common.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/core.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/fan.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/graph.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/group.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/matroid.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/polytope.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/topaz.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/tropical.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/ideal.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/perlx/$(PERLVERSION)/darwin-thread-multi-2level/auto/Polymake/Ext/Ext.bundle
# bundled extensions
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/group/lib/common.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/group/lib/group.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/group/lib/polytope.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/group/lib/topaz.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/java/lib/common.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/java/lib/graph.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/java/lib/polytope.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/libnormaliz/lib/polytope.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/nauty/lib/graph.bundle
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/bundled/ppl/lib/polytope.bundle
#leftovers
	@install_name_tool -rpath "$(PREFIX)/lib" "../Res			ources/lib" $(PREFIX)/lib/libmpfr.4.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libppl.13.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libppl_c.4.dylib

	
### make polymake script executable
### shouldn't this already be the case?
polymake-executable :
	@chmod u+x $(PREFIX)/polymake/bin/polymake


### remove junk
clean-install :
	@cd polymake.app; find . -name "*.pod" -exec rm -rf {} \;
	@cd polymake.app; find . -name "*.3pm" -exec rm -rf {} \;
	@cd polymake.app; find . -name "*.packlist" -exec rm -rf {} \;
	@cd polymake.app; find . -name "*.la" -exec rm -rf {} \;


dmg : 
	@echo "creating a disk image needs administrator rights. You will be asked for your password..."
	@./scripts/diskimage


clean : 
	@rm -rf polymake.app
	@rm -rf tmp
	@rm -f polybundle.dmg
	@rm -f tmp.dmg
	@rm -f README.pdf

doc : 
	@cd scripts; pdflatex README
	@cd scripts; pdflatex README
	@cd scripts; rm -f README.aux README.log README.out

