using BinDeps

@BinDeps.setup

libpq = library_dependency("libpq", aliases=["libpq5"])

major, minor = (9,4)
branch = "REL$(major)_$(minor)_STABLE"

postgresql_srcurl = "http://git.postgresql.org/gitweb/?p=postgresql.git;a=snapshot;h=refs/heads/$branch;sf=tgz"
postgresql_giturl = "https://github.com/postgres/postgres"  # GitHub mirror

postgresql_srcdir = joinpath(BinDeps.srcdir(libpq), "postgresql")
postgresql_usrdir = BinDeps.usrdir(libpq)

provides(AptGet, "libpq5", libpq)
provides(Yum, "libpq5", libpq)
provides(Yum, "postgresql-libs", libpq)
provides(Pacman, "postgresql-libs", libpq)

@static if is_apple()
    using Homebrew
    provides(Homebrew.HB, "postgresql", libpq, os=:Darwin)
end

provides(SimpleBuild, (@build_steps begin
    BinDeps.DirectoryRule(postgresql_srcdir,  # this isn't exported for some reason
        `git clone $postgresql_giturl $postgresql_srcdir --depth 1 --branch $branch`
    )
    FileRule(joinpath(postgresql_srcdir, "GNUMakefile"), @build_steps begin
        ChangeDirectory(postgresql_srcdir)
        `./configure --prefix=$postgresql_usrdir`
    end)
    @build_steps begin
        ChangeDirectory(joinpath(postgresql_srcdir, "src", "interfaces", "libpq"))
        MakeTargets()
        MakeTargets("install")
    end
end), libpq)

@BinDeps.install Dict(:libpq => :libpq)
