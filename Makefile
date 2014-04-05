
# this Makefile is for OS X 10.8 or 10.9
# includes compilation of a proper gcc

### change into the base directory
###BASEPATH := $( (cd -P $(dirname $0) && pwd) )
SED := "/usr/bin/sed"
TMP := $(CURDIR)/tmp
PERL := /usr/bin/perl
DATE := `date +'%Y-%m-%d'`

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

.PHONY: all skeleton boost ppl gcc rpath perl gmp readline mpfr ant singular polymake-prepare polymake-compile dmg clean clean-install polymake-install polymake-docs relative-paths doc polymake-executable xsexternal_error flint ftit singularfour singularfournames

### default target
all : skeleton gmp_build gmp mpfr_build mpfr ppl_build ppl readline_build readline perl boost ant flint ftit singularfour singularfournames polymake-prepare polymake-compile polymake-install polymake_env_var polymake_name polymake_rpath polymake-executable clean-install doc dmg  

allold : skeleton gmp_build gmp mpfr_build mpfr ppl_build ppl readline_build readline perl boost ant singular polymake-prepare polymake-compile polymake-install polymake_env_var polymake_name polymake_rpath polymake-executable clean-install doc dmg  


xsexternal_error : polymake-compile polymake-install polymake_env_var polymake_name polymake_rpath polymake-executable clean-install doc dmg

### create the polymake package skeleton
skeleton : 
	@echo "creating skeleton"
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
	@echo "building gmp"
	@./build.sh gmp-5.1.3 "$(TMP)" build \
	--prefix=$(PREFIX) --enable-cxx=yes

gmp_install :
	@echo "installing gmp"
	@./install.sh gmp-5.1.3 "$(TMP)" build
	
gmp_name :
		@echo "fixing names in gmp"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libgmpxx.4.dylib" "libgmp.10.dylib"
##############
	@./fix_libname.sh "$(PREFIX)/lib" "libgmpxx.4.dylib" 
	@./fix_libname.sh "$(PREFIX)/lib" "libgmp.10.dylib"
	
gmp : gmp_install gmp_name
 
mpfr_build : 
	@echo "building mpfg"
	@./build.sh mpfr-3.1.2 "$(TMP)" build \
	--prefix=$(PREFIX) --with-gmp=$(PREFIX) LDFLAGS="-Wl,-rpath,$(PREFIX)/lib"

mpfr_install : 
	@echo "installing mpfr"
	@./install.sh mpfr-3.1.2 "$(TMP)" build

mpfr_name :
	@echo "fixing names in mpfr"
	@./fix_libname.sh "$(PREFIX)/lib" "libmpfr.4.dylib" 
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libmpfr.4.dylib
		
mpfr : mpfr_install mpfr_name

ppl_build : 
	@echo "building ppl"
	@./build.sh ppl-1.1 "$(TMP)" build \
	  --prefix=$(PREFIX) --with-gmp=$(PREFIX) --with-mpfr=$(PREFIX) LDFLAGS="-Wl,-rpath,$(PREFIX)/lib"

ppl_install : 
	@echo "installing ppl"
	@./install.sh ppl-1.1 "$(TMP)" build

ppl_name :
	@echo "fixing names in ppl"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libppl.13.dylib" "libppl_c.4.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libppl_c.4.dylib" "libppl.13.dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libppl_c.4.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libppl.13.dylib
	##############
	@./fix_libname.sh "$(PREFIX)/lib" "libppl_c.4.dylib" 
	@./fix_libname.sh "$(PREFIX)/lib" "libppl.13.dylib" 
	@./fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ppl-config" "libppl.13.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ppl_pips" "libppl.13.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ppl_lcdd" "libppl.13.dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/ppl-config
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/ppl_pips
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/ppl_lcdd

ppl : ppl_install ppl_name

ant : 
	@echo "extracting ant"
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
	@echo "fixing names in readline"
		@cd $(PREFIX)/lib; chmod u+w libreadline.6.2.dylib;  chmod u+w libhistory.6.2.dylib
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libreadline.6.2.dylib" "libgcc_s.1.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libhistory.6.2.dylib" "libgcc_s.1.dylib"	
##############
	@./fix_libname.sh "$(PREFIX)/lib" "libreadline.6.2.dylib" 
	@./fix_libname.sh "$(PREFIX)/lib" "libhistory.6.2.dylib" 


### XML-LibXSLT
### Term-Gnu-Readline
perl : 
	@echo "building perl modules"
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
	@echo "extracting boost"
	@tar xfj tarballs/boost_1_47_0.tar.bz2 -C polymake.app/Contents/Resources/include
### remove junk
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/doc
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/tools
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/status
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/more
	@rm -rf polymake.app/Contents/Resources/include/boost_1_47_0/libs
	
singular :
	@echo "building singular"
	@cd $(TMP); mkdir -p singular
	@cd $(TMP)/singular; if [ ! -d Sources/.git ]; then git clone https://github.com/Singular/Sources; fi
	@cd $(TMP)/singular/Sources; git checkout master
	# we patch a file, so we should fix the revision we use
### apparently checking out a revision does not work, try by date	
	@cd $(TMP)/singular/Sources; git checkout `git rev-list -n 1 --before="2014-03-25 00:00" master`
	@cd $(TMP)/singular/Sources; git archive master | bzip2 > ../../../tarballs/singular-github-version-branch-spielwiese-20140325.tar.bz2
	@cd $(TMP)/singular/Sources; $(SED) 's|exec_prefix=${prefix}/${ac_cv_singuname}|exec_prefix=${prefix}|g' configure > configure.tmp; mv configure.tmp configure; chmod a+x configure
### we must check whether patch has been applied already
	@cd $(TMP)/singular/Sources; patch -p0 -N --dry-run --silent < ../../../scripts/singular-patch 2>/dev/null; if [ $$? -eq 0 ]; then patch -p0 < ../../../scripts/singular-patch; else echo "configure already patched"; fi
	@cd $(TMP)/singular/Sources; PERL5LIB=$(PERL5LIB) CPPFLAGS="-fpic -DPIC -DLIBSINGULAR" LDFLAGS="-L$(PREFIX)/lib/ -Wl,-rpath,$(PREFIX)/lib" CFLAGS="-I$(PREFIX)/include/ -fpic -DPIC -DLIBSINGULAR" ./configure --without-dynamic-kernel --without-MP --prefix=$(PREFIX)
	@make -C $(TMP)/singular/Sources install-libsingular
	@./fix_libname.sh "$(PREFIX)/lib" "libsingular.dylib" 
	
flint :
	@echo "building flint"
	@cd $(TMP); mkdir -p flint
	@cd $(TMP)/flint; if [ ! -d .git ]; then git clone https://github.com/wbhart/flint2.git .; fi
	@cd $(TMP)/flint; git archive trunk | bzip2 > ../../tarballs/flint-github-$(DATE).tar.bz2	
	@cd $(TMP)/flint; PERL5LIB=$(PERL5LIB) CPPFLAGS="-fpic -DPIC -DLIBSINGULAR" LDFLAGS="-L$(PREFIX)/lib/ -Wl,-rpath,$(PREFIX)/lib" CFLAGS="-I$(PREFIX)/include/ -fpic -DPIC -DLIBSINGULAR" ./configure  --with-gmp=$(PREFIX)/ --with-mpfr=$(PREFIX)/ --disable-shared --prefix=$(PREFIX)
	@make -C $(TMP)/flint/
	@make -C $(TMP)/flint/ install
	
ftit :
	@echo "building 4ti2"
	@tar xvfz tarballs/4ti2-1.6.2.tar.gz -C $(TMP)
	@cd $(TMP)/4ti2-1.6.2; ./configure --prefix=$(PREFIX)
	@cd $(TMP)/4ti2-1.6.2; make
	@cd $(TMP)/4ti2-1.6.2; make install
	
singularfour :
	@echo "building singular 4"
	@cd $(TMP); mkdir -p singular
	@cd $(TMP)/singular; if [ ! -d Sources/.git ]; then git clone https://github.com/Singular/Sources; fi
	@cd $(TMP)/singular/Sources; git archive spielwiese | bzip2 > ../../../tarballs/singular-github-version-branch-spielwiese-$(DATE).tar.bz2
	@cd $(TMP)/singular/Sources; ./autogen.sh
	@cd $(TMP)/singular/Sources; PERL5LIB=$(PERL5LIB) CPPFLAGS="-fpic -DPIC -DLIBSINGULAR" LDFLAGS="-L$(PREFIX)/lib/ -Wl,-rpath,$(PREFIX)/lib" CFLAGS="-I$(PREFIX)/include/ -fpic -DPIC -DLIBSINGULAR" ./configure --without-dynamic-kernel --without-MP --prefix=$(PREFIX) --with-flint=$(PREFIX) --enable-gfanlib --with-gmp=$(PREFIX)
	@cd $(TMP)/singular/Sources; make
	@cd $(TMP)/singular/Sources; make install
	
singularfournames :
### binaries
	@./fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ESingular" "libomalloc-0.9.6.dylib" 
	@./fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ESingular" "libresources-4.0.0.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "TSingular" "libomalloc-0.9.6.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "TSingular" "libresources-4.0.0.dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/Singular
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/ESingular
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/TSingular
### libs
	@./fix_libname.sh "$(PREFIX)/lib" "libSingular-4.0.0.dylib"	
	@./fix_libname.sh "$(PREFIX)/lib" "libfactory-4.0.0.dylib"
	@./fix_libname.sh "$(PREFIX)/lib" "libomalloc-0.9.6.dylib"
	@./fix_libname.sh "$(PREFIX)/lib" "libpolys-4.0.0.dylib"
	@./fix_libname.sh "$(PREFIX)/lib" "libresources-4.0.0.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.0.dylib" "libresources-4.0.0.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.0.dylib" "libomalloc-0.9.6.dylib" 
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.0.dylib" "libfactory-4.0.0.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.0.dylib" "libpolys-4.0.0.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libfactory-4.0.0.dylib" "libresources-4.0.0.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libfactory-4.0.0.dylib" "libomalloc-0.9.6.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libpolys-4.0.0.dylib" "libresources-4.0.0.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libpolys-4.0.0.dylib" "libomalloc-0.9.6.dylib"
	@./fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libpolys-4.0.0.dylib" "libfactory-4.0.0.dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libSingular-4.0.0.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libfactory-4.0.0.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libomalloc-0.9.6.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libpolys-4.0.0.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libresources-4.0.0.dylib
	
		
polymake-prepare : 
	@echo "preparing polymake build"
	@cd $(TMP); mkdir -p polymake; 
	@cd $(TMP)/polymake;  if [ ! -d .git ]; then git clone https://github.com/polymake/polymake.git .; fi
	@cd $(TMP)/polymake; git archive Releases | bzip2 > ../../tarballs/polymake-2.13.tar.bz2
	@cd $(TMP)/polymake; LD_LIBRARY_PATH=$(PREFIX)/lib PERL5LIB=$(PREFIX)/lib/perl5/site_perl/$(PERLVERSION)/darwin-thread-multi-2level/:$(PREFIX)/lib/perl5/ ./configure  --without-fink --with-readline=$(PREFIX)/lib --prefix=$(PREFIX)/polymake --with-jni-headers=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$(MACVERSION).sdk/System/Library/Frameworks/JavaVM.framework/Headers --with-boost=$(PREFIX)/include/boost_1_47_0/ --with-gmp=$(PREFIX)/ --with-ppl=$(PREFIX)/  --with-mpfr=$(PREFIX)/ --with-ant=$(PREFIX)/apache-ant-1.9.3/bin/ant PERL=$(PERL) --with-singular=$(PREFIX) CXXFLAGS="-I$(PREFIX)/include" LDFLAGS="-L$(PREFIX)/lib/ -stdlib=libstdc++"  CXXFLAGS="-Wl,-rpath,$(PREFIX)/lib -m64 -mtune=generic -I/usr/include/c++/4.2.1" CFLAGS=" -m64 -mtune=generic" 

polymake-compile :
	@echo "building polymake"
	@make -j2 -C $(TMP)/polymake

polymake-docs :
	@echo "creating polymake docs"
	@make -j2 -C $(TMP)/polymake docs

polymake-install : 
	@echo "installing polymake"
	@make -C $(TMP)/polymake install

polymake_env_var :
	@echo "fixing variables in polymake"
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
	@echo "fixing names in polymake"
	@chmod u+w $(PREFIX)/polymake/lib/libpolymake.dylib
	@chmod u+w $(PREFIX)/polymake/lib/libpolymake-apps.dylib
	@chmod u+w $(PREFIX)/polymake/lib/libpolymake-apps.2.13.dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake.dylib" $(PREFIX)/polymake/lib/libpolymake.dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake-apps.dylib" $(PREFIX)/polymake/lib/libpolymake-apps.dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake-apps.2.13.dylib" $(PREFIX)/polymake/lib/libpolymake-apps.2.13.dylib
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
	@echo "fixing names in polymake"
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
	
### make polymake script executable
### shouldn't this already be the case?
polymake-executable :
	@echo "making polymake executable"
	@chmod u+x $(PREFIX)/polymake/bin/polymake


### remove junk
clean-install :
	@echo "clean install"
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
	@echo "create readme"
	@cd scripts; pdflatex README
	@cd scripts; pdflatex README
	@cd scripts; rm -f README.aux README.log README.out

