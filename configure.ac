AC_INIT([clustduct], [0.0.1], [cgoll@suse.com], [clustduct], [http://github.com/mslacken/clustduct])
AC_PROG_CC
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile])

#AC_CONFIG_SRCDIR([src/clustduct.lua src/bfcommons.lua])
AX_PROG_LUA([5.1], [5.4])
AC_CHECK_FILE("/usr/lib64/lua/$LUA_VERSION/genders.so",,AC_MSG_WARN(Can not find genders lua bindings))

AC_OUTPUT
