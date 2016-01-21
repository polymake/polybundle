#
# (c) Silke Horn, Andreas Paffenholz, 2016
#     polymake.org
#
# Published under GPL v3
#
# this Makefile is for OS X Yosemite
# prior installation of Xcode command line tools and java required

TAR_DIR           := $(CURDIR)/src

POLYMAKEVERSION  := "3.0"
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
SINGULARVERSION  := "4.0.2"


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

CFLAGS   =  -m64 -mcpu=generic -march=x86-64
CXXFLAGS =  -m64 -mcpu=generic -march=x86-64

.PHONY: all fetch_sources skeleton boost ppl gcc rpath perl gmp readline mpfr ant polymake-prepare polymake-compile dmg clean clean-install polymake-install polymake-docs doc polymake-executable flint ftit ntl singular_compile singular_configure singular_install bundle compile gnu_auto_stuff autoconf automake libtool glpk polymake_env_var polymake_run_script

### default target
all : fetch_sources compile

compile : skeleton ant boost \
						readline \
						autoconf automake libtool \
						perl \
					  gmp_build gmp_install \
						mpfr_build mpfr_install
						glpk ftit \
						ppl_build ppl_install \
						ntl \
						singular_configure singular_compile singular_install \
						polymake-prepare polymake-compile polymake-install polymake_run_script polymake_env_var polymake-executable \
						fix_names \
						clean-install doc

bundle : compile dmg



##################################
##################################
# get all sources not obtained from github
# rebuilds the src-directory, except for flint and singular, which are obtained from github in their specific targets below
fetch_sources :
	@mkdir -p $(TAR_DIR)
	@echo "fetching ant"
	@cd $(TAR_DIR); curl -O http://artfiles.org/apache.org//ant/binaries/apache-ant-$(ANTVERSION)-bin.tar.bz2
	@echo "fetching 4ti2"
	@cd $(TAR_DIR); curl -O http://www.4ti2.de/version_$(4TI2VERSION)/4ti2-$(4TI2VERSION).tar.gz
	@echo "fetching term-readline-gnu"
	@cd $(TAR_DIR); curl -O -L http://search.cpan.org/CPAN/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-$(TERMRLGNUVERSION).tar.gz
	@echo "fetching libxslt"
	@cd $(TAR_DIR); curl -O -L http://search.cpan.org/CPAN/authors/id/S/SH/SHLOMIF/XML-LibXSLT-$(LIBXSLTVERSION).tar.gz
	@echo "fetching boost"
	@cd $(TAR_DIR); curl -O -L http://sourceforge.net/projects/boost/files/boost/$(BOOSTVERSIONDIR)/boost_$(BOOSTVERSION).tar.bz2
	@echo "fetching gmp"
	@cd $(TAR_DIR); curl -O https://gmplib.org/download/gmp/gmp-$(GMPVERSION)$(GMPMINORVERSION).tar.bz2
	@echo "fetching mpfr"
	@cd $(TAR_DIR); curl -O http://www.mpfr.org/mpfr-current/mpfr-$(MPFRVERSION).tar.bz2
	@echo "fetching readline"
	@cd $(TAR_DIR); curl -O ftp://ftp.cwru.edu/pub/bash/readline-$(READLINEVERSION).tar.gz
	@echo "fetching autoconf"
	@cd $(TAR_DIR); curl --remote-name http://ftp.gnu.org/gnu/autoconf/autoconf-$(AUTOCONFVERSION).tar.gz
	@echo "fetching automake"
	@cd $(TAR_DIR); curl --remote-name http://ftp.gnu.org/gnu/automake/automake-$(AUTOMAKEVERSION).tar.gz
	@echo "fetching libtool"
	@cd $(TAR_DIR); curl --remote-name http://ftp.gnu.org/gnu/libtool/libtool-$(LIBTOOLVERSION).tar.gz
	@echo "fetching ntl"
	@cd $(TAR_DIR); curl --remote-name http://www.shoup.net/ntl/ntl-$(NTLVERSION).tar.gz
	@echo "fetching cddlib"
	@cd $(TAR_DIR); curl -O ftp://ftp.ifor.math.ethz.ch/pub/fukuda/cdd/cddlib-$(CDDLIBVERSION).tar.gz
	@echo "fetching glpk"
	@cd $(TAR_DIR); curl -O http://ftp.gnu.org/gnu/glpk/glpk-$(GLPKVERSION).tar.gz


##################################
##################################
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


##################################
##################################
### boost
boost :
	@echo "extracting boost"
	@tar xfj $(TAR_DIR)/boost_$(BOOSTVERSION).tar.bz2 -C polymake.app/Contents/Resources/include
### remove junk
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSIONDIR)/doc
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSIONDIR)/tools
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSIONDIR)/status
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSIONDIR)/more
	@rm -rf polymake.app/Contents/Resources/include/boost_$(BOOSTVERSIONDIR)/libs


##################################
##################################
### ant
ant :
	@echo "extracting ant"
	@tar xvfj $(TAR_DIR)/apache-ant-$(ANTVERSION)-bin.tar.bz2 -C $(PREFIX)


##################################
##################################
### readline
### FIXME: we need to fix the arch flag settings for compilation
readline :
	@echo building readline in $(TMP)
	@mkdir -p $(TMP)
	@tar xvfz $(TAR_DIR)/readline-$(READLINEVERSION).tar.gz -C $(TMP)
	@if [ "$(MACVERSION)" = "10.8" ]; then \
		${SED} -i '' -e 's|-arch_only `/usr/bin/arch`|-dynamiclib|g' $(TMP)/readline-$(READLINEVERSION)/support/shobj-conf; \
	else \
		${SED} -i '' -e "s|SHOBJ_ARCHFLAGS=|SHOBJ_ARCHFLAGS=\'-dynamiclib\'|g" \ $(TMP)/readline-$(READLINEVERSION)/support/shobj-conf; \
	fi
	@cd $(TMP)/readline-$(READLINEVERSION); CFLAGS="$(CLFAGS)" CPPFLAGS="$(CXXFLAGS)"  ./configure --prefix=$(PREFIX)
	@make -C $(TMP)/readline-$(READLINEVERSION)
	@make -C $(TMP)/readline-$(READLINEVERSION) install


##################################
##################################
### gmp build
gmp_build :
	@echo "building gmp"
	@mkdir -p $(TMP)/gmp-$(GMPVERSION)_build;
	@tar xvfj $(TAR_DIR)/gmp-$(GMPVERSION)$(GMPMINORVERSION).tar.bz2 -C $(TMP);
	@cd $(TMP)gmp-$(GMPVERSION)_build; CFLAGS="$(CFLAGS)" CPPFLAGS="$(CXXFLAGS)" \
			../gmp-$(GMPVERSION)/configure --prefix=$(PREFIX) --enable-cxx=yes


##################################
##################################
gmp_install :
	@echo "installing gmp"
	@./build_scripts/install.sh gmp-$(GMPVERSION) "$(TMP)" build


##################################
##################################
### mpfr build
mpfr_build :
	@echo "building mpfg"
	@./build_scripts/build.sh mpfr-$(MPFRVERSION) mpfr-$(MPFRVERSION) "$(TMP)" build \
	--prefix=$(PREFIX) --with-gmp=$(PREFIX) LDFLAGS="-Wl,-rpath,$(PREFIX)/lib"


##################################
##################################
mpfr_install :
	@echo "installing mpfr"
	@./build_scripts/install.sh mpfr-$(MPFRVERSION) "$(TMP)" build


##################################
##################################
### XML-LibXSLT
### Term-Gnu-Readline
### FIXME patching Makefile.PL is a rather crude hack to add an rpath to rlver,
###       as I don't know how to add an env variable to the call to Makefile.PL in the following line
### it seems we have to pass ARCHFLAG again in the call to Makefile.PL, global setting ignored
perl :
	@echo "building perl modules"
	@tar xvfz $(TAR_DIR)/XML-LibXSLT-$(LIBXSLTVERSION).tar.gz -C $(TMP)
	@cd $(TMP)/XML-LibXSLT-$(LIBXSLTVERSION); ARCHFLAGS='-arch x86_64' $(PERL) Makefile.PL PREFIX=$(PREFIX)
	@make -C $(TMP)/XML-LibXSLT-$(LIBXSLTVERSION)
	@make -C $(TMP)/XML-LibXSLT-$(LIBXSLTVERSION) install
	@tar xvfz $(TAR_DIR)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION).tar.gz -C $(TMP)
	@${SED} -i '' -e "s|Config{cc}|Config{cc} -Wl,-rpath,\$(PREFIX)/lib|g" $(TMP)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION)/Makefile.PL
	@cd $(TMP)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION);  ARCHFLAGS='-arch x86_64' $(PERL) Makefile.PL PREFIX=$(PREFIX) --includedir=$(PREFIX)/include --libdir=$(PREFIX)/lib
	@make -C $(TMP)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION)
	@make -C $(TMP)/Term-ReadLine-Gnu-$(TERMRLGNUVERSION) install


##################################
##################################
### flint
flint :
	@echo "building flint"
	@cd $(TMP); mkdir -p flint
	@cd $(TMP)/flint; if [ ! -d .git ]; then git clone https://github.com/wbhart/flint2.git .; fi
	@cd $(TMP)/flint; git archive trunk | bzip2 > ../../$(TAR_DIR)/flint-github-$(DATE).tar.bz2
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


##################################
##################################
### glpk
glpk:
	@tar xvfz $(TAR_DIR)/glpk-$(GLPKVERSION).tar.gz -C $(TMP)
	@cd $(TMP)/glpk-$(GLPKVERSION); ./configure --prefix=$(PREFIX) && make && make install


##################################
##################################
### 4ti2
ftit :
	@echo "building 4ti2"
	@tar xvfz $(TAR_DIR)/4ti2-$(4TI2VERSION).tar.gz -C $(TMP)
	@cd $(TMP)/4ti2-$(4TI2VERSION); ./configure --prefix=$(PREFIX) --with-glpk=$(PREFIX) --with-gmp=$(PREFIX)
	@make -C $(TMP)/4ti2-$(4TI2VERSION)
	@make -C $(TMP)/4ti2-$(4TI2VERSION) install


### gnu auto tools
##################################
##################################
autoconf :
	@echo "building autoconf"
	@mkdir -p $(TMP)/local
	@tar xvfz $(TAR_DIR)/autoconf-$(AUTOCONFVERSION).tar.gz -C $(TMP)
	@cd $(TMP)/autoconf-$(AUTOCONFVERSION) && \
		./configure --prefix=$(TMP)/local && \
		make && make install


##################################
##################################
automake :
	@echo "building automake"
	@tar xvfz $(TAR_DIR)/automake-$(AUTOMAKEVERSION).tar.gz -C $(TMP)
	@cd $(TMP)/automake-$(AUTOMAKEVERSION) && \
		PATH=$(TMP)/local/bin:${PATH} ./configure --prefix=$(TMP)/local && \
		make && make install


##################################
##################################
libtool :
	@echo "building libtool"
	@tar xvfz $(TAR_DIR)/libtool-$(LIBTOOLVERSION).tar.gz -C $(TMP)
	@cd $(TMP)/libtool-$(LIBTOOLVERSION) && \
		PATH=$(TMP)/local/bin:${PATH} ./configure --prefix=$(TMP)/local && \
		make && make install


##################################
##################################
### ppl build
ppl_build :
	@echo "building ppl"
	@cd $(TMP); mkdir -p ppl
	@cd $(TMP)/ppl; if [ ! -d .git ]; then git clone git://git.cs.unipr.it/ppl/ppl.git .; else git pull; fi
	@cd $(TMP)/ppl; git archive trunk | bzip2 > $(TAR_DIR)/ppl-git-$(DATE).tar.bz2
	@cd $(TMP)/ppl; PATH=$(TMP)/local/bin:${PATH} libtoolize --force && \
		PATH=$(TMP)/local/bin:${PATH} autoreconf -fi && \
		./configure --prefix=$(PREFIX) --with-gmp=$(PREFIX) --with-mpfr=$(PREFIX) LDFLAGS="-Wl,-rpath,$(PREFIX)/lib" && make


##################################
##################################
### fun thing: ppl puts its path into the header, so we need to fix this
ppl_install :
	@echo "installing ppl"
	@./build_scripts/install.sh ppl "$(TMP)" build
	@cd $(PREFIX)/include; \
	chmod u+w ppl.hh; \
	$(SED) 's/\# .*//g' ppl.hh | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/\./g' > ppl.hh.tmp; mv ppl.hh.tmp ppl.hh


##################################
##################################
### ntl
### Caveat: The configure is not a configure but a shell script, we need to source it
###         as such it also does not care about extra CXXFLAGS, so we need to modify the makefile
### we remove unwanted static lib in the end
ntl :
	@echo "building ntl"
	@tar xvfz $(TAR_DIR)/ntl-$(NTLVERSION).tar.gz -C $(TMP)
	@cd $(TMP)/ntl-$(NTLVERSION)/src && \
		PATH=$(TMP)/local/bin:${PATH} . ./configure PREFIX=$(PREFIX) SHARED=on NTL_GMP_LIP=on GMP_PREFIX=$(PREFIX) && \
		${SED} -i '' -e "s|CXXFLAGS=-g -O2|CXXFLAGS=-g -O2 -I\$(PREFIX)/include -Wl,-rpath,\$(PREFIX)/lib|g" $(TMP)/ntl-$(NTLVERSION)/src/makefile && \
		make && make install
	@rm $(PREFIX)/lib/libntl.a


##################################
##################################
### singular
singular_configure :
	@echo "building singular 4"
	@cd $(TMP); mkdir -p singular
	@cd $(TMP)/singular; if [ ! -d .git ]; then git clone https://github.com/Singular/Sources .; else git pull; fi
		cd $(TMP)/singular && \
		git archive spielwiese | bzip2 > $(TAR_DIR)/singular-github-version-$(DATE).tar.bz2 && \
		PATH=$(TMP)/local/bin:$(PREFIX)/bin:${PATH} \
		./autogen.sh && \
		   PATH=$(TMP)/local/bin:$(PREFIX)/bin:${PATH} \
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
					--with-flint=$(PREFIX) \
					--with-gmp=$(PREFIX) && \
					--with-mpfr=$(PREFIX) &&
		  PATH=$(TMP)/local/bin:$(PREFIX)/bin:${PATH}


##################################
##################################
singular_compile :
	@make -j2 -C $(TMP)/singular/Sources	&& PATH=$(TMP)/local/bin:${PATH}


##################################
##################################
singular_install :
	@make -C $(TMP)/singular/Sources	&& PATH=$(TMP)/local/bin:${PATH} install


##################################
##################################
### polymake
polymake-prepare :
	@echo "preparing polymake build"
	@cd $(TMP); mkdir -p polymake;
	@cd $(TMP)/polymake;  if [ ! -d .git ]; then git clone -b Releases https://github.com/polymake/polymake.git .; \
												else git pull; \
												fi
	@cd $(TMP)/polymake; git archive Releases | bzip2 > $(TAR_DIR)/polymake-releases-$(DATE).tar.bz2
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
				   	 		 --with-ant=$(PREFIX)/apache-ant-$(ANTVERSION)/bin/ant  \
				   	 		 --with-java=/usr/bin/java \
				   	 		LDFLAGS="-L$(PREFIX)/lib/ -stdlib=libc++"  \
				   			CXXFLAGS="$(CXXFLAGS) -I$(PREFIX)/include -Wl,-rpath,$(PREFIX)/lib -stdlib=libc++" \
				   			CFLAGS="$(CFLAGS)" \
				   			CC=$(CC) CXX=$(CXX) \
				   			PERL=$(PERL)


##################################
##################################
polymake-compile :
	@echo "building polymake"
	@make -j2 -C $(TMP)/polymake

##################################
##################################
polymake-docs :
	@echo "creating polymake docs"
	@make -j2 -C $(TMP)/polymake docs


##################################
##################################
polymake-install :
	@echo "installing polymake"
	@make -C $(TMP)/polymake install


##################################
##################################
### adjust the polymake script to the new paths
polymake_run_script :
	@cd $(PREFIX)/polymake/bin; chmod u+w polymake; $(SED) 's/.*InstallTop=.*/   $$InstallTop=\"$$ENV\{POLYMAKE_BASE_PATH\}\/share\/polymake\";/' polymake | $(SED) 's/.*InstallArch=.*/   $$InstallArch=\"$$ENV\{POLYMAKE_BASE_PATH\}\/lib\/polymake\";/' | $(SED) '/.*addlibs=.*/d' > polymake.tmp; mv polymake.tmp polymake
	@cd $(PREFIX)/polymake/bin; chmod u+w polymake-config; $(SED) 's/.*InstallArch=.*/   $$InstallArch=\"$$ENV\{POLYMAKE_BASE_PATH\}\/lib\/polymake\";/' polymake-config > polymake-config.tmp; mv polymake-config.tmp polymake-config


##################################
##################################
### adjust conf.make for polymake and all bundled extensions
### FIXME using \S etc. in a regexp apparently does not work for Mac's sed,
###       so we assume that the path to the current directory is not too strange
polymake_env_var :
	@echo "fixing variables in polymake"
	@cd $(PREFIX)/polymake/lib/polymake; \
	chmod u+w conf.make; \
	$(SED) 's/\# .*//g' conf.make | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
	$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
	$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
	> conf.make.tmp; mv conf.make.tmp conf.make
	for ext in $(shell ls polymake.app/Contents/Resources/polymake/lib/polymake/bundled/ | sed 's|/||'); do \
				cd $(PREFIX)/polymake/lib/polymake/bundled/$$ext; \
				chmod u+w conf.make; \
				$(SED) 's/\# .*//g' conf.make | \
				$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources\/polymake/$$\{POLYMAKE_BASE_PATH\}/g'  | \
				$(SED) -E 's/\/[A-Z,a-z,\/]*\/polymake.app\/Contents\/Resources/$$\{POLYMAKE_BASE_PATH\}\/..\//g' | \
				$(SED) 's/I.*boost/I$\{POLYMAKE_BASE_PATH\}\/..\/include\/boost/' \
				> conf.make.tmp; mv conf.make.tmp conf.make; \
	done


##################################
##################################
### make polymake script executable
### shouldn't this already be the case?
polymake-executable :
	@echo "making polymake executable"
	@chmod u+x $(PREFIX)/polymake/bin/polymake


fix_names :
	@./build_scripts/fix_load_dylib.sh $(PREFIX)/lib $(PREFIX)/lib dylib
	@./build_scripts/fix_load_dylib.sh $(PREFIX)/bin $(PREFIX)/lib ""
	@./build_scripts/fix_load_dylib.sh $(PREFIX)/polymake/lib $(PREFIX)/lib dylib
	@./build_scripts/fix_load_dylib.sh $(PREFIX)/polymake/lib/polymake/lib $(PREFIX)/lib bundle
	@./build_scripts/fix_load_dylib.sh $(PREFIX)/lib/perl5/site_perl/$(PERLVERSION)/darwin-thread-multi-2level/auto/Term/ReadLine/Gnu/ $(PREFIX)/lib bundle
	for ext in $(shell ls polymake.app/Contents/Resources/polymake/lib/polymake/bundled/ | sed 's|/||'); do \
			./build_scripts/fix_load_dylib.sh $(PREFIX)/polymake/lib/polymake/bundled/$$ext/lib $(PREFIX)/lib bundle ; \
	done
	@./build_scripts/fix_rpath.sh $(PREFIX)/lib $(PREFIX)/lib dylib
	@./build_scripts/fix_rpath.sh $(PREFIX)/bin $(PREFIX)/lib ""
	@./build_scripts/fix_rpath.sh $(PREFIX)/polymake/lib $(PREFIX)/lib dylib
	@./build_scripts/fix_rpath.sh $(PREFIX)/polymake/lib/polymake/lib $(PREFIX)/lib bundle
	@./build_scripts/fix_rpath.sh $(PREFIX)/polymake/lib/polymake/perlx/$(PERLVERSION)/darwin-thread-multi-2level/auto/Polymake/Ext $(PREFIX)/lib bundle
	for ext in $(shell polymake.app/Contents/Resources/polymake/lib/polymake/bundled/ | sed 's|/||'); do \
			./build_scripts/fix_rpath.sh $(PREFIX)/polymake/lib/polymake/bundled/$$ext/lib $(PREFIX)/lib bundle ; \
	done
	@./build_scripts/fix_libname.sh "$(PREFIX)/lib" dylib ""
	@./build_scripts/fix_libname.sh "$(PREFIX)/polymake/lib" dylib "../polymake/lib"


##################################
##################################
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



##################################
##################################
dmg :
	@echo "creating a disk image needs administrator rights. You will be asked for your password..."
	@./build_scripts/diskimage "$(TAR_DIR)"


##################################
##################################
clean :
	@rm -rf polymake.app
	@rm -rf tmp
	@rm -f polybundle.dmg
	@rm -f tmp.dmg
	@rm -f build_scripts/README.pdf


##################################
##################################
doc :
	@echo "create readme"
	@cd build_scripts; \
		if [[ README.tex -nt ../README.pdf ]]; then \
			pdflatex README &&  pdflatex README &&  mv README.pdf ../ && rm -f README.aux README.log README.out; \
		fi;
