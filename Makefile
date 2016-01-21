
# this Makefile is for OS X Yosemite
# prior installation of Xcode command line tools and java required

POLYMAKEVERSION := "2.14"
ANTVERSION       := "1.9.6"
MPFRVERSION      := "3.1.3"
GMPVERSION       := "6.1.0"
GMPMINORVERSION  := ""
POLYMAKEVERSION  := "2.14"
NTLVERSION       := "9.6.2"
BOOSTVERSION     := "1_59_0"
BOOSTVERSIONDIR  := "1.59.0"
READLINEVERSION  := "6.3"
CDDLIBVERSION    := "094h"
GLPKVERSION      := "4.57"
4TI2VERSION      := "1.6.7"
LIBTOOLVERSION   := "2.4"
AUTOCONFVERSION  := "2.69"
AUTOMAKEVERSION  := "1.14"
TERMRLGNUVERSION := "1.24"
LIBXSLTVERSION   := "1.92"

LIBNTLVERSION    := "18"
LIBGMPVERSION    := "10"
LIBGMPXXVERSION  := "4"
LIBMPFRVERSION   := "4"
LIBPPLVERSION    := "13"
LIBPPLCVERSION   := "4"

### change into the base directory
###BASEPATH := $( (cd -P $(dirname $0) && pwd) )
SED := "/usr/bin/sed"
TMP := $(CURDIR)/tmp/
PERL := /usr/bin/perl
DATE := `date +'%Y-%m-%d'`
PATH := /usr/bin:$(PATH)
JNIHEADERS = "/System/Library/Frameworks/JavaVM.framework/Headers/		"

MACVERSION := $(shell sw_vers | grep -o "10[.][0-9]")
PERLVERSION := $(shell $(PERL) --version | grep -o "5[.][0-9]*[.][0-9]")

PREFIX := $(CURDIR)/polymake.app/Contents/Resources

# fix the compiler
CC  := /usr/bin/cc
CXX := /usr/bin/g++

### only 64bit, first for gcc, second for perl (with gcc)
#CFLAGS="-arch x86_64"
#ARCHFLAGS='-arch x86_64'
CFLAGS   =  -m64 -mcpu=generic -march=x86-64
CXXFLAGS =  -m64 -mcpu=generic -march=x86-64

.PHONY: all fetch_sources skeleton boost ppl gcc rpath perl gmp readline mpfr ant polymake-prepare polymake-compile dmg clean clean-install polymake-install polymake-docs relative-paths doc polymake-executable flint ftit ntl singularfour singularfournames bundle compile gnu_auto_stuff autoconf automake libtool

### default target
all : fetch_sources compile

compile : skeleton gmp_build gmp mpfr_build mpfr readline_build readline perl boost ant ftit gnu_auto_stuff ppl_build ppl ntl singularfour singularfournames polymake-prepare polymake-compile polymake-install polymake_env_var polymake_name polymake_rpath polymake-executable clean-install doc

bundle : compile dmg

# get all sources not obtained from github
# rebuilds the src-directory, except for flint and singular, which are obtained from github in their specific targets below
fetch_sources :
	@mkdir -p src
	@echo "fetching ant"
	@cd src; curl -O http://artfiles.org/apache.org//ant/binaries/apache-ant-$(ANTVERSION)-bin.tar.bz2
	@echo "fetching 4ti2"
	@cd src; curl -O http://www.4ti2.de/version_$(4TI2VERSION)/4ti2-$(4TI2VERSION).tar.gz
	@echo "fetching term-readline-gnu"
	@cd src; curl -O -L http://search.cpan.org/CPAN/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-$(TERMRLGNUVERSION).tar.gz
	@echo "fetching libxslt"
	@cd src; curl -O -L http://search.cpan.org/CPAN/authors/id/S/SH/SHLOMIF/XML-LibXSLT-$(LIBXSLTVERSION).tar.gz
	@echo "fetching boost"
	@cd src; curl -O -L http://sourceforge.net/projects/boost/files/boost/$(BOOSTVERSIONDIR)/boost_$(BOOSTVERSION).tar.bz2
	@echo "fetching gmp"
	@cd src; curl -O https://gmplib.org/download/gmp/gmp-$(GMPVERSION)$(GMPMINORVERSION).tar.bz2
	@echo "fetching mpfr"
	@cd src; curl -O http://www.mpfr.org/mpfr-current/mpfr-$(MPFRVERSION).tar.bz2
	@echo "fetching readline"
	@cd src; curl -O ftp://ftp.cwru.edu/pub/bash/readline-$(READLINEVERSION).tar.gz
	@echo "fetching autoconf"
	@cd src; curl --remote-name http://ftp.gnu.org/gnu/autoconf/autoconf-$(AUTOCONFVERSION).tar.gz
	@echo "fetching automake"
	@cd src; curl --remote-name http://ftp.gnu.org/gnu/automake/automake-$(AUTOMAKEVERSION).tar.gz
	@echo "fetching libtool"
	@cd src; curl --remote-name http://ftp.gnu.org/gnu/libtool/libtool-$(LIBTOOLVERSION).tar.gz
	@echo "fetching ntl"
	@cd src; curl --remote-name http://www.shoup.net/ntl/ntl-$(NTLVERSION).tar.gz
	@echo "fetching cddlib"
	@cd src; curl -O ftp://ftp.ifor.math.ethz.ch/pub/fukuda/cdd/cddlib-$(CDDLIBVERSION).tar.gz
	@echo "fetching glpk"
	@cd src; curl -O http://ftp.gnu.org/gnu/glpk/glpk-$(GLPKVERSION).tar.gz


### create the polymake package skeleton
skeleton :
	@echo "creating skeleton"
	@mkdir -p polymake.app/Contents/Resources
	@mkdir -p polymake.app/Contents/MacOS

	@cd bundle_scripts; $(SED) 's/REPLACE_PERLVERSION/${PERLVERSION}/g' polymake.start > polymake.start.tmp;
	@cd bundle_scripts; $(SED) 's/REPLACE_PERLVERSION/${PERLVERSION}/g' polymake.debug > polymake.debug.tmp;
	@install -m 550 bundle_scripts/polymake polymake.app/Contents/MacOS/
	@install -m 550 bundle_scripts/polymake.start.tmp polymake.app/Contents/MacOS/polymake.start
	@install -m 550 bundle_scripts/polymake.debug.tmp polymake.app/Contents/MacOS/polymake.debug
	@install -m 550 bundle_scripts/debug.commands polymake.app/Contents/Resources/
	@cd bundle_scripts; rm polymake.start.tmp;
	@cd bundle_scripts; rm polymake.debug.tmp;
	@cp bundle_scripts/Info.plist polymake.app/Contents/
	@cp bundle_scripts/*.icns polymake.app/Contents/Resources/
	@install -m 550 bundle_scripts/Singular polymake.app/Contents/MacOS/


### boost
boost :
	@echo "extracting boost"
	@tar xfj src/boost_$(BOOSTVERSION).tar.bz2 -C polymake.app/Contents/Resources/include
### remove junk
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSION)/doc
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSION)/tools
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSION)/status
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSION)/more
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSION)/libs

### ant
ant :
	@echo "extracting ant"
	@tar xvfj src/apache-ant-$(ANTVERSION)-bin.tar.bz2 -C $(PREFIX)

### readline
readline_build :
	@echo building readline in $(TMP)
	@mkdir -p $(TMP)
	@tar xvfz src/readline-$(READLINEVERSION).tar.gz -C $(TMP)
### fix the arch flag settings for compilation
	@if [ "$(MACVERSION)" = "10.8" ]; then \
	${SED} -i '' -e 's|-arch_only `/usr/bin/arch`|-dynamiclib|g' $(TMP)/readline-$(READLINEVERSION)/support/shobj-conf; \
	else \
	${SED} -i '' -e "s|SHOBJ_ARCHFLAGS=|SHOBJ_ARCHFLAGS=\'-dynamiclib\'|g" $(TMP)/readline-$(READLINEVERSION)/support/shobj-conf; \
	fi
	@cd $(TMP)/readline-$(READLINEVERSION); CFLAGS="$(CLFAGS)" CPPFLAGS="$(CXXFLAGS)"  ./configure --prefix=$(PREFIX)
	@make -C $(TMP)/readline-$(READLINEVERSION)
	@make -C $(TMP)/readline-$(READLINEVERSION) install

readline :
	@echo "fixing names in readline"
	@cd $(PREFIX)/lib; chmod u+w libreadline.$(READLINEVERSION).dylib;  chmod u+w libhistory.$(READLINEVERSION).dylib
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libreadline.$(READLINEVERSION).dylib" "libgcc_s.1.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libhistory.$(READLINEVERSION).dylib" "libgcc_s.1.dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libreadline.$(READLINEVERSION).dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libhistory.$(READLINEVERSION).dylib"


### gmp build
gmp_build :
	@echo "building gmp"
	@mkdir -p $(TMP)/gmp-$(GMPVERSION)_build;
	@tar xvfj src/gmp-$(GMPVERSION)$(GMPMINORVERSION).tar.bz2 -C $(TMP);
	@cd $(TMP)gmp-$(GMPVERSION)_build; CFLAGS="$(CFLAGS)" CPPFLAGS="$(CXXFLAGS)" \
	../gmp-$(GMPVERSION)/configure --prefix=$(PREFIX) --enable-cxx=yes

gmp_install :
	@echo "installing gmp"
	@./build_scripts/install.sh gmp-$(GMPVERSION) "$(TMP)" build

gmp_name :
		@echo "fixing names in gmp"
	@./build_scripts/fix_lc_load_dylib.sh \
		"$(PREFIX)/lib" "$(PREFIX)/lib" "libgmpxx.$(LIBGMPXXVERSION).dylib" "libgmp.$(LIBGMPVERSION).dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libgmpxx.$(LIBGMPXXVERSION).dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libgmp.$(LIBGMPVERSION).dylib"

gmp : gmp_install gmp_name

### mpfr build
mpfr_build :
	@echo "building mpfg"
	@./build_scripts/build.sh mpfr-$(MPFRVERSION) mpfr-$(MPFRVERSION) "$(TMP)" build \
	--prefix=$(PREFIX) --with-gmp=$(PREFIX) LDFLAGS="-Wl,-rpath,$(PREFIX)/lib"

mpfr_install :
	@echo "installing mpfr"
	@./build_scripts/install.sh mpfr-$(MPFRVERSION) "$(TMP)" build

mpfr_name :
	@echo "fixing names in mpfr"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libmpfr.$(LIBMPFRVERSION).dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib

mpfr : mpfr_install mpfr_name

### XML-LibXSLT
### Term-Gnu-Readline
perl :
	@echo "building perl modules"
	@tar xvfz src/XML-LibXSLT-$(LIBXSLTVERSION).tar.gz -C $(TMP)
	@cd $(TMP)/XML-LibXSLT-$(LIBXSLTVERSION); ARCHFLAGS='-arch x86_64' $(PERL) Makefile.PL PREFIX=$(PREFIX)
	@make -C $(TMP)/XML-LibXSLT-$(LIBXSLTVERSION)
	@make -C $(TMP)/XML-LibXSLT-$(LIBXSLTVERSION) install
### term-readline-gnu
	@tar xvfz src/Term-ReadLine-Gnu-$(TERMRLGNUVERSION).tar.gz -C $(TMP)
### FIXME this is a rather crude hack to add an rpath to rlver, as I don't know how to add an env variable to the call to Makefile.PL in the following line
	@${SED} -i '' -e "s|Config{cc}|Config{cc} -Wl,-rpath,\$(PREFIX)/lib|g" $(TMP)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION)/Makefile.PL
### have to pass ARCHFLAG again?
	@cd $(TMP)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION);  ARCHFLAGS='-arch x86_64' $(PERL) Makefile.PL PREFIX=$(PREFIX) --includedir=$(PREFIX)/include --libdir=$(PREFIX)/lib
	@make -C $(TMP)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION)
	@make -C $(TMP)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION) install


### preparations for singular
flint :
	@echo "building flint"
	@cd $(TMP); mkdir -p flint
	@cd $(TMP)/flint; if [ ! -d .git ]; then git clone https://github.com/wbhart/flint2.git .; fi
	@cd $(TMP)/flint; git archive trunk | bzip2 > ../../src/flint-github-$(DATE).tar.bz2
	@cd $(TMP)/flint; \
	PERL5LIB=$(PERL5LIB) \
	   CPPFLAGS="-fpic -DPIC -DLIBSINGULAR" \
	   LDFLAGS="-L$(PREFIX)/lib/ -Wl,-rpath,$(PREFIX)/lib" \
	   CFLAGS="-I$(PREFIX)/include/ -fpic -DPIC -DLIBSINGULAR" \
	./configure  --with-gmp=$(PREFIX)/ \
	             --with-mpfr=$(PREFIX)/ \
				 --disable-shared \
				 --prefix=$(PREFIX)
	@make -C $(TMP)/flint/
	@make -C $(TMP)/flint/ install

ftit :
	@echo "building 4ti2"
	@tar xvfz src/4ti2-1.6.2.tar.gz -C $(TMP)
	@cd $(TMP)/4ti2-1.6.2; ./configure --prefix=$(PREFIX)
	@cd $(TMP)/4ti2-1.6.2; make
	@cd $(TMP)/4ti2-1.6.2; make install

gnu_auto_stuff : autoconf automake libtool

autoconf :
	@echo "building autoconf"
	@mkdir -p $(TMP)/local
	@tar xvfz src/autoconf-2.69.tar.gz -C $(TMP)
	@cd $(TMP)/autoconf-2.69 && \
		./configure --prefix=$(TMP)/local && \
		make && make install

automake :
	@echo "building automake"
	@tar xvfz src/automake-1.14.tar.gz -C $(TMP)
	@cd $(TMP)/automake-1.14 && \
		PATH=$(TMP)/local/bin:${PATH} ./configure --prefix=$(TMP)/local && \
		make && make install

libtool :
	@echo "building libtool"
	@tar xvfz src/libtool-2.4.tar.gz -C $(TMP)
	@cd $(TMP)/libtool-2.4 && \
		PATH=$(TMP)/local/bin:${PATH} ./configure --prefix=$(TMP)/local && \
		make && make install


### ppl build
ppl_build :
	@echo "building ppl"
	@cd $(TMP); mkdir -p ppl
	@cd $(TMP)/ppl; if [ ! -d .git ]; then git clone git://git.cs.unipr.it/ppl/ppl.git .; else git pull; fi
	@cd $(TMP)/ppl; git archive trunk | bzip2 > ../../src/ppl-github-$(DATE).tar.bz2
	@cd $(TMP)/ppl; PATH=$(TMP)/local/bin:${PATH} libtoolize --force && \
		PATH=$(TMP)/local/bin:${PATH} autoreconf -fi && \
		./configure --prefix=$(PREFIX) --with-gmp=$(PREFIX) --with-mpfr=$(PREFIX) LDFLAGS="-Wl,-rpath,$(PREFIX)/lib" && make

ppl_install :
	@echo "installing ppl"
	@./build_scripts/install.sh ppl "$(TMP)" build

ppl_name :
	@echo "fixing names in ppl"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libppl.$(LIBPPLVERSION).dylib" "libppl_c.$(LIBPPLCVERSION).dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libppl_c.$(LIBPPLCVERSION).dylib" "libppl.$(LIBPPLVERSION).dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libppl_c.$(LIBPPLCVERSION).dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libppl.$(LIBPPLVERSION).dylib
	##############
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libppl_c.$(LIBPPLCVERSION).dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libppl.$(LIBPPLVERSION).dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ppl-config" "libppl.$(LIBPPLVERSION).dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ppl_pips" "libppl.$(LIBPPLVERSION).dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ppl_lcdd" "libppl.$(LIBPPLVERSION).dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/ppl-config
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/ppl_pips
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/ppl_lcdd

ppl : ppl_install ppl_name

ntl :
	@echo "building ntl"
	@tar xvfz src/ntl-$(NTLVERSION).tar.gz -C $(TMP)
### Caveat: The configure is not a configure but a shell script, we need to source it
###         as such it also does not care about extra CXXFLAGS, so we need to modify the makefile
	@cd $(TMP)/ntl-$(NTLVERSION)/src && \
		PATH=$(TMP)/local/bin:${PATH} . ./configure PREFIX=$(PREFIX) SHARED=on NTL_GMP_LIP=on GMP_PREFIX=$(PREFIX) && \
		${SED} -i '' -e "s|CXXFLAGS=-g -O2|CXXFLAGS=-g -O2 -I\$(PREFIX)/include -Wl,-rpath,\$(PREFIX)/lib|g" $(TMP)/ntl-$(NTLVERSION)/src/makefile && \
		make && make install
### cleanup: remove unwanted static lib
	@rm $(PREFIX)/lib/libntl.a
### fix name of lib
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libntl.$(LIBNTLVERSION).dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libntl.$(LIBNTLVERSION).dylib


### singular
singularfour :
	@echo "building singular 4"
	@cd $(TMP); mkdir -p singular
	@cd $(TMP)/singular; if [ ! -d Sources/.git ]; then git clone https://github.com/Singular/Sources Sources; fi
###	@cd $(TMP)/singular/Sources && git checkout `git rev-list -n 1 --before="2014-04-22 00:00" spielwiese` &&
		cd $(TMP)/singular/Sources && git checkout spielwiese && \
		git archive spielwiese | bzip2 > $(CURDIR)/src/singular-github-version-$(DATE).tar.bz2 && \
		PATH=$(TMP)/local/bin:${PATH} \
		./autogen.sh && \
		   PATH=$(TMP)/local/bin:${PATH} \
		   PERL5LIB=$(PERL5LIB) \
		   CPPFLAGS="-fpic -DPIC -DLIBSINGULAR $(CXXFLAGS)" \
		   LDFLAGS="-L$(PREFIX)/lib/ -Wl,-rpath,$(PREFIX)/lib" \
		   CFLAGS="-I$(PREFIX)/include/ -fpic -DPIC -DLIBSINGULAR $(CFLAGS)" \
		./configure --without-dynamic-kernel \
		            --without-MP \
					--disable-static \
					--with-ntl=$(PREFIX) \
					--prefix=$(PREFIX) \
					--disable-gfanlib \
					--without-flint \
					--with-gmp=$(PREFIX) && \
		  PATH=$(TMP)/local/bin:${PATH} \
		make -j2 && make install

		###		            --with-flint=$(PREFIX) \

singularfournames :
### binaries
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "Singular" "libSingular-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "Singular" "libpolys-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "Singular" "libfactory-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "Singular" "libresources-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "Singular" "libomalloc-0.9.6.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "Singular" "libresources-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ESingular" "libomalloc-0.9.6.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "ESingular" "libresources-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "TSingular" "libomalloc-0.9.6.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/bin" "$(PREFIX)/lib" "TSingular" "libresources-4.0.2.dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/Singular
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/ESingular
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/bin/TSingular
### libs
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libSingular-4.0.2.dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libfactory-4.0.2.dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libomalloc-0.9.6.dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libpolys-4.0.2.dylib"
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" "libresources-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.2.dylib" "libresources-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.2.dylib" "libomalloc-0.9.6.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.2.dylib" "libfactory-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.2.dylib" "libpolys-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libfactory-4.0.2.dylib" "libresources-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libfactory-4.0.2.dylib" "libomalloc-0.9.6.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libpolys-4.0.2.dylib" "libresources-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libpolys-4.0.2.dylib" "libomalloc-0.9.6.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libpolys-4.0.2.dylib" "libfactory-4.0.2.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libSingular-4.0.2.dylib" "libntl.9.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libpolys-4.0.2.dylib" "libntl.9.dylib"
	@./build_scripts/fix_lc_load_dylib.sh "$(PREFIX)/lib" "$(PREFIX)/lib" "libfactory-4.0.2.dylib" "libntl.9.dylib"
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libSingular-4.0.2.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libfactory-4.0.2.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libomalloc-0.9.6.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libpolys-4.0.2.dylib
	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/lib/libresources-4.0.2.dylib



### polymake
polymake-prepare :
	@echo "preparing polymake build"
	@cd $(TMP); mkdir -p polymake;
	@cd $(TMP)/polymake;  if [ ! -d .git ]; then git clone -b Releases https://github.com/polymake/polymake.git .; fi
	@cd $(TMP)/polymake; git archive Releases | bzip2 > ../../src/polymake-releases-$(DATE).tar.bz2
	cd $(TMP)/polymake; \
	  LD_LIBRARY_PATH=$(PREFIX)/lib \
	  PERL5LIB=$(PREFIX)/lib/perl5/site_perl/$(PERLVERSION)/darwin-thread-multi-2level/:$(PREFIX)/lib/perl5/ \
	  ./configure  --without-fink \
	               --with-readline=$(PREFIX)/lib \
	               --prefix=$(PREFIX)/polymake \
				   --with-jni-headers=$(JNIHEADERS) \
				   --with-boost=$(PREFIX)/include/boost_$(BOOSTVERSIONDIR)/ \
				   --with-gmp=$(PREFIX)/ \
				   --with-ppl=$(PREFIX)/  \
				   --with-mpfr=$(PREFIX)/ \
				   --with-singular=$(PREFIX)/ \
				   --with-ant=$(PREFIX)/apache-ant-$(ANTVERSION)/bin/ant PERL=$(PERL) \
				   --with-java=/usr/bin/java \
				   LDFLAGS="-L$(PREFIX)/lib/ -stdlib=libc++"  \
				   CXXFLAGS="$(CXXFLAGS) -I$(PREFIX)/include -Wl,-rpath,$(PREFIX)/lib -I$(PREFIX)/include/boost_$(BOOSTVERSIONDIR)/ -stdlib=libc++" \
				   CFLAGS="$(CFLAGS)" \
				   CC=$(CC) CXX=$(CXX) \
				   PERL=$(PERL)

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
	@cd $(PREFIX)/polymake/lib/polymake/bundled/singular; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake/bundled/cdd; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	@cd $(PREFIX)/polymake/lib/polymake/bundled/lrs; \
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
	@chmod u+w $(PREFIX)/polymake/lib/libpolymake-apps.$(POLYMAKEVERSION).dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake.dylib" $(PREFIX)/polymake/lib/libpolymake.dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake-apps.dylib" $(PREFIX)/polymake/lib/libpolymake-apps.dylib
	@install_name_tool -id "@rpath/../polymake/lib/libpolymake-apps.2.14.dylib" $(PREFIX)/polymake/lib/libpolymake-apps.2.14.dylib
#########
	@chmod u+w $(PREFIX)/lib/perl5/site_perl/$(PERLVERSION)/darwin-thread-multi-2level/auto/Term/ReadLine/Gnu/Gnu.bundle; install_name_tool -change "$(PREFIX)/lib/libreadline.$(READLINEVERSION).dylib" "@rpath/libreadline.$(READLINEVERSION).dylib" $(PREFIX)/lib/perl5/site_perl/$(PERLVERSION)/darwin-thread-multi-2level/auto/Term/ReadLine/Gnu/Gnu.bundle
	@chmod u+w $(PREFIX)/polymake/lib/polymake/lib/*.bundle
	@chmod u+w $(PREFIX)/polymake/lib/polymake/perlx/$(PERLVERSION)/darwin-thread-multi-2level/auto/Polymake/Ext/Ext.bundle
	@chmod u+w $(PREFIX)/polymake/lib/polymake/lib/jni/libpolymake_java.jnilib
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/libpolymake.dylib
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/libpolymake.dylib
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/common.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/common.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/core.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/core.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/graph.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/graph.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/group.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/group.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/matroid.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/matroid.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/polytope.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/polytope.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/topaz.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/topaz.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/tropical.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/tropical.bundle
	@install_name_tool -change "$(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib" "@rpath/libmpfr.$(LIBMPFRVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/fan.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/polymake/lib/polymake/lib/fan.bundle
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/lib/libppl_c.$(LIBPPLCVERSION).dylib
	@install_name_tool -change "$(PREFIX)/lib/libppl.$(LIBPPLVERSION).dylib" "@rpath/libppl.$(LIBPPLVERSION).dylib" $(PREFIX)/lib/libppl_c.$(LIBPPLCVERSION).dylib
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/lib/libppl.$(LIBPPLVERSION).dylib
	@install_name_tool -change "$(PREFIX)/lib/libgmp.$(LIBGMPVERSION).dylib" "@rpath/libgmp.$(LIBGMPVERSION).dylib" $(PREFIX)/lib/libmpfr.$(LIBMPFRVERSION).dylib

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
#	@install_name_tool -rpath "$(PREFIX)/lib" "../Resources/lib" $(PREFIX)/polymake/lib/polymake/lib/ideal.bundle
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
	@cd polymake.app; find . -name "*.pc" -exec rm -rf {} \;
	@cd polymake.app; rm -f Contents/Resources/bin/libpolys-config
	@cd polymake.app; rm -f Contents/Resources/bin/libsingular-config
	@cd polymake.app; rmdir Contents/Resources/lib/pkgconfig/



dmg :
	@echo "creating a disk image needs administrator rights. You will be asked for your password..."
	@./build_scripts/diskimage


clean :
	@rm -rf polymake.app
	@rm -rf tmp
	@rm -f polybundle.dmg
	@rm -f tmp.dmg
	@rm -f build_scripts/README.pdf

doc :
	@echo "create readme"
	@cd build_scripts; if [[ README.tex -nt ../README.pdf ]]; then pdflatex README &&  pdflatex README &&  mv README.pdf ../ && rm -f README.aux README.log README.out; fi;
