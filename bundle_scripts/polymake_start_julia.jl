configfile=homedir()*"/.polymake-macbundle/bundle.config"

polymake_base = ""
open(configfile) do f
    for i in eachline(f)
        global polymake_base
       if occursin(r"^\s*POLYMAKE_BASE_DIR",i)
           polymake_base = match(r"^\s*POLYMAKE_BASE_DIR=(.*)/MacOS",i)[1]
       end
    end
end
polymake_base

if ( polymake_base == "" )
    println("polymake bundle not found. You need to start the bundle at least once before using it in Julia!")
else
    println("Initializing polymake ...")
    polymake_base *= "/Resources"
    polymake_bundle_configure_dyld_library_path=""
    polymake_bundle_configure_path=""
    polymake_bundle_configure_perl5lib=""
    if haskey(ENV, "PATH")
        polymake_bundle_configure_path=":"*ENV["PATH"]
    end
    if haskey(ENV, "DYLD_LIBRARY_PATH")
        polymake_bundle_configure_dyld_library_path=":"*ENV["DYLD_LIBRARY_PATH"]
    end
    if haskey(ENV, "PERL5LIB")
        polymake_bundle_configure_perl5lib=":"*ENV["PERL5LIB"]
    end
    ENV["PATH"]=polymake_base*"/polymake/bin:"*polymake_base*"/bin"*polymake_bundle_configure_path
    ENV["POLYMAKE_CONFIG_PATH"]=polymake_base*"/config;user"
    ENV["POLYMAKE_USER_DIR"]=homedir()*"/.polymake-macbundle"
    ENV["POLYMAKE_BASE_PATH"]=polymake_base*"/polymake"
    ENV["DYLD_LIBRARY_PATH"]=polymake_base*"/lib:"*polymake_base*"/include/boost_1_66_0/:/Applications/Julia-1.1.app/Contents/Resources/julia/lib/julia"*polymake_bundle_configure_dyld_library_path
    ENV["LC_RPATH"]=ENV["DYLD_LIBRARY_PATH"]
    ENV["CPLUS_INCLUDE_PATH"]=polymake_base*"/include/"
    ENV["CFLAGS"]="-I"*polymake_base*"/include/"
    ENV["CPPFLAGS"]="-I"*polymake_base*"/include/"
    ENV["PERL5LIB"]=polymake_base*"/perl5/lib/perl5:"*polymake_base*"/perl5/"*polymake_bundle_configure_perl5lib

    using Pkg
    if !haskey(Pkg.installed(), "Polymake")
        Pkg.add("Polymake")
    end
end