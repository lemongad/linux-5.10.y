# SPDX-License-Identifier: GPL-2.0
VERSION = 5
PATCHLEVEL = 10
SUBLEVEL = 135
EXTRAVERSION =
NAME = Dare mighty things

# *DOCUMENTATION*
# To see a list of typical targets execute "make help"
# More info can be located in ./README
# Comments in this file are targeted only to the developer, do not
# expect to learn how to build the kernel reading this file.

$(if $(filter __%, $(MAKECMDGOALS)), \
	$(error targets prefixed with '__' are only for internal use))

# That's our default target when none is given on the command line
PHONY := __all
__all:

# We are using a recursive build, so we need to do a little thinking
# to get the ordering right.
#
# Most importantly: sub-Makefiles should only ever modify files in
# their own directory. If in some directory we have a dependency on
# a file in another dir (which doesn't happen often, but it's often
# unavoidable when linking the built-in.a targets which finally
# turn into vmlinux), we will call a sub make in that other dir, and
# after that we are sure that everything which is in that other dir
# is now up to date.
#
# The only cases where we need to modify files which have global
# effects are thus separated out and done before the recursive
# descending is started. They are now explicitly listed as the
# prepare rule.

ifneq ($(sub_make_done),1)

# Do not use make's built-in rules and variables
# (this increases performance and avoids hard-to-debug behaviour)
MAKEFLAGS += -rR

# Avoid funny character set dependencies
unexport LC_ALL
LC_COLLATE=C
LC_NUMERIC=C
export LC_COLLATE LC_NUMERIC

# Avoid interference with shell env settings
unexport GREP_OPTIONS

# Beautify output
# ---------------------------------------------------------------------------
#
# Normally, we echo the whole command before executing it. By making
# that echo $($(quiet)$(cmd)), we now have the possibility to set
# $(quiet) to choose other forms of output instead, e.g.
#
#         quiet_cmd_cc_o_c = Compiling $(RELDIR)/$@
#         cmd_cc_o_c       = $(CC) $(c_flags) -c -o $@ $<
#
# If $(quiet) is empty, the whole command will be printed.
# If it is set to "quiet_", only the short version will be printed.
# If it is set to "silent_", nothing will be printed at all, since
# the variable $(silent_cmd_cc_o_c) doesn't exist.
#
# A simple variant is to prefix commands with $(Q) - that's useful
# for commands that shall be hidden in non-verbose mode.
#
#	$(Q)ln $@ :<
#
# If KBUILD_VERBOSE equals 0 then the above command will be hidden.
# If KBUILD_VERBOSE equals 1 then the above command is displayed.
# If KBUILD_VERBOSE equals 2 then give the reason why each target is rebuilt.
#
# To put more focus on warnings, be less verbose as default
# Use 'make V=1' to see the full commands

ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif

# If the user is running make -s (silent mode), suppress echoing of
# commands

ifneq ($(findstring s,$(filter-out --%,$(MAKEFLAGS))),)
  quiet=silent_
endif

export quiet Q KBUILD_VERBOSE

# Kbuild will save output files in the current working directory.
# This does not need to match to the root of the kernel source tree.
#
# For example, you can do this:
#
#  cd /dir/to/store/output/files; make -f /dir/to/kernel/source/Makefile
#
# If you want to save output files in a different location, there are
# two syntaxes to specify it.
#
# 1) O=
# Use "make O=dir/to/store/output/files/"
#
# 2) Set KBUILD_OUTPUT
# Set the environment variable KBUILD_OUTPUT to point to the output directory.
# export KBUILD_OUTPUT=dir/to/store/output/files/; make
#
# The O= assignment takes precedence over the KBUILD_OUTPUT environment
# variable.

# Do we want to change the working directory?
ifeq ("$(origin O)", "command line")
  KBUILD_OUTPUT := $(O)
endif

ifneq ($(KBUILD_OUTPUT),)
# Make's built-in functions such as $(abspath ...), $(realpath ...) cannot
# expand a shell special character '~'. We use a somewhat tedious way here.
abs_objtree := $(shell mkdir -p $(KBUILD_OUTPUT) && cd $(KBUILD_OUTPUT) && pwd)
$(if $(abs_objtree),, \
     $(error failed to create output directory "$(KBUILD_OUTPUT)"))

# $(realpath ...) resolves symlinks
abs_objtree := $(realpath $(abs_objtree))
else
abs_objtree := $(CURDIR)
endif # ifneq ($(KBUILD_OUTPUT),)

ifeq ($(abs_objtree),$(CURDIR))
# Suppress "Entering directory ..." unless we are changing the work directory.
MAKEFLAGS += --no-print-directory
else
need-sub-make := 1
endif

abs_srctree := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

ifneq ($(words $(subst :, ,$(abs_srctree))), 1)
$(error source directory cannot contain spaces or colons)
endif

ifneq ($(abs_srctree),$(abs_objtree))
# Look for make include files relative to root of kernel src
#
# This does not become effective immediately because MAKEFLAGS is re-parsed
# once after the Makefile is read. We need to invoke sub-make.
MAKEFLAGS += --include-dir=$(abs_srctree)
need-sub-make := 1
endif

this-makefile := $(lastword $(MAKEFILE_LIST))

ifneq ($(filter 3.%,$(MAKE_VERSION)),)
# 'MAKEFLAGS += -rR' does not immediately become effective for GNU Make 3.x
# We need to invoke sub-make to avoid implicit rules in the top Makefile.
need-sub-make := 1
# Cancel implicit rules for this Makefile.
$(this-makefile): ;
endif

export abs_srctree abs_objtree
export sub_make_done := 1

ifeq ($(need-sub-make),1)

PHONY += $(MAKECMDGOALS) __sub-make

$(filter-out $(this-makefile), $(MAKECMDGOALS)) __all: __sub-make
	@:

# Invoke a second make in the output directory, passing relevant variables
__sub-make:
	$(Q)$(MAKE) -C $(abs_objtree) -f $(abs_srctree)/Makefile $(MAKECMDGOALS)

endif # need-sub-make
endif # sub_make_done

# We process the rest of the Makefile if this is the final invocation of make
ifeq ($(need-sub-make),)

# Do not print "Entering directory ...",
# but we want to display it when entering to the output directory
# so that IDEs/editors are able to understand relative filenames.
MAKEFLAGS += --no-print-directory

# Call a source code checker (by default, "sparse") as part of the
# C compilation.
#
# Use 'make C=1' to enable checking of only re-compiled files.
# Use 'make C=2' to enable checking of *all* source files, regardless
# of whether they are re-compiled or not.
#
# See the file "Documentation/dev-tools/sparse.rst" for more details,
# including where to get the "sparse" utility.

ifeq ("$(origin C)", "command line")
  KBUILD_CHECKSRC = $(C)
endif
ifndef KBUILD_CHECKSRC
  KBUILD_CHECKSRC = 0
endif

# Use make M=dir or set the environment variable KBUILD_EXTMOD to specify the
# directory of external module to build. Setting M= takes precedence.
ifeq ("$(origin M)", "command line")
  KBUILD_EXTMOD := $(M)
endif

$(if $(word 2, $(KBUILD_EXTMOD)), \
	$(error building multiple external modules is not supported))

export KBUILD_CHECKSRC KBUILD_EXTMOD

extmod-prefix = $(if $(KBUILD_EXTMOD),$(KBUILD_EXTMOD)/)

ifeq ($(abs_srctree),$(abs_objtree))
        # building in the source tree
        srctree := .
	building_out_of_srctree :=
else
        ifeq ($(abs_srctree)/,$(dir $(abs_objtree)))
                # building in a subdirectory of the source tree
                srctree := ..
        else
                srctree := $(abs_srctree)
        endif
	building_out_of_srctree := 1
endif

ifneq ($(KBUILD_ABS_SRCTREE),)
srctree := $(abs_srctree)
endif

objtree		:= .
VPATH		:= $(srctree)

export building_out_of_srctree srctree objtree VPATH

# To make sure we do not include .config for any of the *config targets
# catch them early, and hand them over to scripts/kconfig/Makefile
# It is allowed to specify more targets when calling make, including
# mixing *config targets and build targets.
# For example 'make oldconfig all'.
# Detect when mixed targets is specified, and make a second invocation
# of make so .config is not included in this case either (for *config).

version_h := include/generated/uapi/linux/version.h
old_version_h := include/linux/version.h

clean-targets := %clean mrproper cleandocs
no-dot-config-targets := $(clean-targets) \
			 cscope gtags TAGS tags help% %docs check% coccicheck \
			 $(version_h) headers headers_% archheaders archscripts \
			 %asm-generic kernelversion %src-pkg dt_binding_check \
			 outputmakefile
no-sync-config-targets := $(no-dot-config-targets) %install kernelrelease \
			  image_name
single-targets := %.a %.i %.ko %.lds %.ll %.lst %.mod %.o %.s %.symtypes %/

config-build	:=
mixed-build	:=
need-config	:= 1
may-sync-config	:= 1
single-build	:=

ifneq ($(filter $(no-dot-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-dot-config-targets), $(MAKECMDGOALS)),)
		need-config :=
	endif
endif

ifneq ($(filter $(no-sync-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-sync-config-targets), $(MAKECMDGOALS)),)
		may-sync-config :=
	endif
endif

ifneq ($(KBUILD_EXTMOD),)
	may-sync-config :=
endif

ifeq ($(KBUILD_EXTMOD),)
        ifneq ($(filter %config,$(MAKECMDGOALS)),)
		config-build := 1
                ifneq ($(words $(MAKECMDGOALS)),1)
			mixed-build := 1
                endif
        endif
endif

# We cannot build single targets and the others at the same time
ifneq ($(filter $(single-targets), $(MAKECMDGOALS)),)
	single-build := 1
	ifneq ($(filter-out $(single-targets), $(MAKECMDGOALS)),)
		mixed-build := 1
	endif
endif

# For "make -j clean all", "make -j mrproper defconfig all", etc.
ifneq ($(filter $(clean-targets),$(MAKECMDGOALS)),)
        ifneq ($(filter-out $(clean-targets),$(MAKECMDGOALS)),)
		mixed-build := 1
        endif
endif

# install and modules_install need also be processed one by one
ifneq ($(filter install,$(MAKECMDGOALS)),)
        ifneq ($(filter modules_install,$(MAKECMDGOALS)),)
		mixed-build := 1
        endif
endif

ifdef mixed-build
# ===========================================================================
# We're called with mixed targets (*config and build targets).
# Handle them one by one.

PHONY += $(MAKECMDGOALS) __build_one_by_one

$(MAKECMDGOALS): __build_one_by_one
	@:

__build_one_by_one:
	$(Q)set -e; \
	for i in $(MAKECMDGOALS); do \
		$(MAKE) -f $(srctree)/Makefile $$i; \
	done

else # !mixed-build

include scripts/Kbuild.include

# Read KERNELRELEASE from include/config/kernel.release (if it exists)
KERNELRELEASE = $(shell cat include/config/kernel.release 2> /dev/null)
KERNELVERSION = $(VERSION)$(if $(PATCHLEVEL),.$(PATCHLEVEL)$(if $(SUBLEVEL),.$(SUBLEVEL)))$(EXTRAVERSION)
export VERSION PATCHLEVEL SUBLEVEL KERNELRELEASE KERNELVERSION

include scripts/subarch.include

# Cross compiling and selecting different set of gcc/bin-utils
# ---------------------------------------------------------------------------
#
# When performing cross compilation for other architectures ARCH shall be set
# to the target architecture. (See arch/* for the possibilities).
# ARCH can be set during invocation of make:
# make ARCH=ia64
# Another way is to have ARCH set in the environment.
# The default ARCH is the host where make is executed.

# CROSS_COMPILE specify the prefix used for all executables used
# during compilation. Only gcc and related bin-utils executables
# are prefixed with $(CROSS_COMPILE).
# CROSS_COMPILE can be set on the command line
# make CROSS_COMPILE=ia64-linux-
# Alternatively CROSS_COMPILE can be set in the environment.
# Default value for CROSS_COMPILE is not to prefix executables
# Note: Some architectures assign CROSS_COMPILE in their arch/*/Makefile
ARCH		?= $(SUBARCH)

# Architecture as present in compile.h
UTS_MACHINE 	:= $(ARCH)
SRCARCH 	:= $(ARCH)

# Additional ARCH settings for x86
ifeq ($(ARCH),i386)
        SRCARCH := x86
endif
ifeq ($(ARCH),x86_64)
        SRCARCH := x86
endif

# Additional ARCH settings for sparc
ifeq ($(ARCH),sparc32)
       SRCARCH := sparc
endif
ifeq ($(ARCH),sparc64)
       SRCARCH := sparc
endif

# Additional ARCH settings for sh
ifeq ($(ARCH),sh64)
       SRCARCH := sh
endif

KCONFIG_CONFIG	?= .config
export KCONFIG_CONFIG

# Default file for 'make defconfig'. This may be overridden by arch-Makefile.
export KBUILD_DEFCONFIG := defconfig

# SHELL used by kbuild
CONFIG_SHELL := sh

HOST_LFS_CFLAGS := $(shell getconf LFS_CFLAGS 2>/dev/null)
HOST_LFS_LDFLAGS := $(shell getconf LFS_LDFLAGS 2>/dev/null)
HOST_LFS_LIBS := $(shell getconf LFS_LIBS 2>/dev/null)

ifneq ($(LLVM),)
HOSTCC	= clang
HOSTCXX	= clang++
else
HOSTCC	= gcc
HOSTCXX	= g++
endif

export KBUILD_USERCFLAGS := -Wall -Wmissing-prototypes -Wstrict-prototypes \
			      -O2 -fomit-frame-pointer -std=gnu89
export KBUILD_USERLDFLAGS :=

KBUILD_HOSTCFLAGS   := $(KBUILD_USERCFLAGS) $(HOST_LFS_CFLAGS) $(HOSTCFLAGS)
KBUILD_HOSTCXXFLAGS := -Wall -O2 $(HOST_LFS_CFLAGS) $(HOSTCXXFLAGS)
KBUILD_HOSTLDFLAGS  := $(HOST_LFS_LDFLAGS) $(HOSTLDFLAGS)
KBUILD_HOSTLDLIBS   := $(HOST_LFS_LIBS) $(HOSTLDLIBS)

# Make variables (CC, etc...)
CPP		= $(CC) -E
ifneq ($(LLVM),)
CC		= clang
LD		= ld.lld
AR		= llvm-ar
NM		= llvm-nm
OBJCOPY		= llvm-objcopy
OBJDUMP		= llvm-objdump
READELF		= llvm-readelf
STRIP		= llvm-strip
else
CC		= $(CROSS_COMPILE)gcc
LD		= $(CROSS_COMPILE)ld
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
OBJCOPY		= $(CROSS_COMPILE)objcopy
OBJDUMP		= $(CROSS_COMPILE)objdump
READELF		= $(CROSS_COMPILE)readelf
STRIP		= $(CROSS_COMPILE)strip
endif
PAHOLE		= pahole
RESOLVE_BTFIDS	= $(objtree)/tools/bpf/resolve_btfids/resolve_btfids
LEX		= flex
YACC		= bison
AWK		= awk
INSTALLKERNEL  := installkernel
DEPMOD		= depmod
PERL		= perl
PYTHON		= python
PYTHON3		= python3
CHECK		= sparse
BASH		= bash
KGZIP		= gzip
KBZIP2		= bzip2
KLZOP		= lzop
LZMA		= lzma
LZ4		= lz4c
XZ		= xz
ZSTD		= zstd

CHECKFLAGS     := -D__linux__ -Dlinux -D__STDC__ -Dunix -D__unix__ \
		  -Wbitwise -Wno-return-void -Wno-unknown-attribute $(CF)
NOSTDINC_FLAGS :=
CFLAGS_MODULE   =
AFLAGS_MODULE   =
LDFLAGS_MODULE  =
CFLAGS_KERNEL	=
AFLAGS_KERNEL	=
LDFLAGS_vmlinux =

# Use USERINCLUDE when you must reference the UAPI directories only.
USERINCLUDE    := \
		-I$(srctree)/arch/$(SRCARCH)/include/uapi \
		-I$(objtree)/arch/$(SRCARCH)/include/generated/uapi \
		-I$(srctree)/include/uapi \
		-I$(objtree)/include/generated/uapi \
                -include $(srctree)/include/linux/kconfig.h

# Use LINUXINCLUDE when you must reference the include/ directory.
# Needed to be compatible with the O= option
LINUXINCLUDE    := \
		-I$(srctree)/arch/$(SRCARCH)/include \
		-I$(objtree)/arch/$(SRCARCH)/include/generated \
		$(if $(building_out_of_srctree),-I$(srctree)/include) \
		-I$(objtree)/include \
		$(USERINCLUDE)

KBUILD_AFLAGS   := -D__ASSEMBLY__ -fno-PIE
KBUILD_CFLAGS   := -Wall -Wundef -Werror=strict-prototypes -Wno-trigraphs \
		   -fno-strict-aliasing -fno-common -fshort-wchar -fno-PIE \
		   -Werror=implicit-function-declaration -Werror=implicit-int \
		   -Werror=return-type -Wno-format-security \
		   -std=gnu89
KBUILD_CPPFLAGS := -D__KERNEL__
KBUILD_AFLAGS_KERNEL :=
KBUILD_CFLAGS_KERNEL :=
KBUILD_AFLAGS_MODULE  := -DMODULE
KBUILD_CFLAGS_MODULE  := -DMODULE
KBUILD_LDFLAGS_MODULE :=
KBUILD_LDFLAGS :=
CLANG_FLAGS :=

export ARCH SRCARCH CONFIG_SHELL BASH HOSTCC KBUILD_HOSTCFLAGS CROSS_COMPILE LD CC
export CPP AR NM STRIP OBJCOPY OBJDUMP READELF PAHOLE RESOLVE_BTFIDS LEX YACC AWK INSTALLKERNEL
export PERL PYTHON PYTHON3 CHECK CHECKFLAGS MAKE UTS_MACHINE HOSTCXX
export KGZIP KBZIP2 KLZOP LZMA LZ4 XZ ZSTD
export KBUILD_HOSTCXXFLAGS KBUILD_HOSTLDFLAGS KBUILD_HOSTLDLIBS LDFLAGS_MODULE

export KBUILD_CPPFLAGS NOSTDINC_FLAGS LINUXINCLUDE OBJCOPYFLAGS KBUILD_LDFLAGS
export KBUILD_CFLAGS CFLAGS_KERNEL CFLAGS_MODULE
export KBUILD_AFLAGS AFLAGS_KERNEL AFLAGS_MODULE
export KBUILD_AFLAGS_MODULE KBUILD_CFLAGS_MODULE KBUILD_LDFLAGS_MODULE
export KBUILD_AFLAGS_KERNEL KBUILD_CFLAGS_KERNEL

# Files to ignore in find ... statements

export RCS_FIND_IGNORE := \( -name SCCS -o -name BitKeeper -o -name .svn -o    \
			  -name CVS -o -name .pc -o -name .hg -o -name .git \) \
			  -prune -o
export RCS_TAR_IGNORE := --exclude SCCS --exclude BitKeeper --exclude .svn \
			 --exclude CVS --exclude .pc --exclude .hg --exclude .git

# ===========================================================================
# Rules shared between *config targets and build targets

# Basic helpers built in scripts/basic/
PHONY += scripts_basic
scripts_basic:
	$(Q)$(MAKE) $(build)=scripts/basic
	$(Q)rm -f .tmp_quiet_recordmcount

PHONY += outputmakefile
# Before starting out-of-tree build, make sure the source tree is clean.
# outputmakefile generates a Makefile in the output directory, if using a
# separate output directory. This allows convenient use of make in the
# output directory.
# At the same time when output Makefile generated, generate .gitignore to
# ignore whole output directory
outputmakefile:
ifdef building_out_of_srctree
	$(Q)if [ -f $(srctree)/.config -o \
		 -d $(srctree)/include/config -o \
		 -d $(srctree)/arch/$(SRCARCH)/include/generated ]; then \
		echo >&2 "***"; \
		echo >&2 "*** The source tree is not clean, please run 'make$(if $(findstring command line, $(origin ARCH)), ARCH=$(ARCH)) mrproper'"; \
		echo >&2 "*** in $(abs_srctree)";\
		echo >&2 "***"; \
		false; \
	fi
	$(Q)ln -fsn $(srctree) source
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/mkmakefile $(srctree)
	$(Q)test -e .gitignore || \
	{ echo "# this is build directory, ignore it"; echo "*"; } > .gitignore
endif

ifneq ($(shell $(CC) --version 2>&1 | head -n 1 | grep clang),)
ifneq ($(CROSS_COMPILE),)
CLANG_FLAGS	+= --target=$(notdir $(CROSS_COMPILE:%-=%))
GCC_TOOLCHAIN_DIR := $(dir $(shell which $(CROSS_COMPILE)elfedit))
CLANG_FLAGS	+= --prefix=$(GCC_TOOLCHAIN_DIR)$(notdir $(CROSS_COMPILE))
GCC_TOOLCHAIN	:= $(realpath $(GCC_TOOLCHAIN_DIR)/..)
endif
ifneq ($(GCC_TOOLCHAIN),)
CLANG_FLAGS	+= --gcc-toolchain=$(GCC_TOOLCHAIN)
endif
ifneq ($(LLVM_IAS),1)
CLANG_FLAGS	+= -no-integrated-as
endif
CLANG_FLAGS	+= -Werror=unknown-warning-option
KBUILD_CFLAGS	+= $(CLANG_FLAGS)
KBUILD_AFLAGS	+= $(CLANG_FLAGS)
export CLANG_FLAGS
endif

# The expansion should be delayed until arch/$(SRCARCH)/Makefile is included.
# Some architectures define CROSS_COMPILE in arch/$(SRCARCH)/Makefile.
# CC_VERSION_TEXT is referenced from Kconfig (so it needs export),
# and from include/config/auto.conf.cmd to detect the compiler upgrade.
CC_VERSION_TEXT = $(shell $(CC) --version 2>/dev/null | head -n 1)

ifdef config-build
# ===========================================================================
# *config targets only - make sure prerequisites are updated, and descend
# in scripts/kconfig to make the *config target

# Read arch specific Makefile to set KBUILD_DEFCONFIG as needed.
# KBUILD_DEFCONFIG may point out an alternative default configuration
# used for 'make defconfig'
include arch/$(SRCARCH)/Makefile
export KBUILD_DEFCONFIG KBUILD_KCONFIG CC_VERSION_TEXT

config: outputmakefile scripts_basic FORCE
	$(Q)$(MAKE) $(build)=scripts/kconfig $@

%config: outputmakefile scripts_basic FORCE
	$(Q)$(MAKE) $(build)=scripts/kconfig $@

else #!config-build
# ===========================================================================
# Build targets only - this includes vmlinux, arch specific targets, clean
# targets and others. In general all targets except *config targets.

# If building an external module we do not care about the all: rule
# but instead __all depend on modules
PHONY += all
ifeq ($(KBUILD_EXTMOD),)
__all: all
else
__all: modules
endif

# Decide whether to build built-in, modular, or both.
# Normally, just do built-in.

KBUILD_MODULES :=
KBUILD_BUILTIN := 1

# If we have only "make modules", don't compile built-in objects.
ifeq ($(MAKECMDGOALS),modules)
  KBUILD_BUILTIN :=
endif

# If we have "make <whatever> modules", compile modules
# in addition to whatever we do anyway.
# Just "make" or "make all" shall build modules as well

ifneq ($(filter all modules nsdeps %compile_commands.json clang-%,$(MAKECMDGOALS)),)
  KBUILD_MODULES := 1
endif

ifeq ($(MAKECMDGOALS),)
  KBUILD_MODULES := 1
endif

export KBUILD_MODULES KBUILD_BUILTIN

ifdef need-config
include include/config/auto.conf
endif

ifeq ($(KBUILD_EXTMOD),)
# Objects we will link into vmlinux / subdirs we need to visit
core-y		:= init/ usr/
drivers-y	:= drivers/ sound/
drivers-$(CONFIG_SAMPLES) += samples/
drivers-y	+= net/ virt/
libs-y		:= lib/
endif # KBUILD_EXTMOD

# The all: target is the default when no target is given on the
# command line.
# This allow a user to issue only 'make' to build a kernel including modules
# Defaults to vmlinux, but the arch makefile usually adds further targets
all: vmlinux

CFLAGS_GCOV	:= -fprofile-arcs -ftest-coverage \
	$(call cc-option,-fno-tree-loop-im) \
	$(call cc-disable-warning,maybe-uninitialized,)
export CFLAGS_GCOV

# The arch Makefiles can override CC_FLAGS_FTRACE. We may also append it later.
ifdef CONFIG_FUNCTION_TRACER
  CC_FLAGS_FTRACE := -pg
endif

ifdef CONFIG_CC_IS_GCC
RETPOLINE_CFLAGS	:= $(call cc-option,-mindirect-branch=thunk-extern -mindirect-branch-register)
RETPOLINE_CFLAGS	+= $(call cc-option,-mindirect-branch-cs-prefix)
RETPOLINE_VDSO_CFLAGS	:= $(call cc-option,-mindirect-branch=thunk-inline -mindirect-branch-register)
endif
ifdef CONFIG_CC_IS_CLANG
RETPOLINE_CFLAGS	:= -mretpoline-external-thunk
RETPOLINE_VDSO_CFLAGS	:= -mretpoline
endif

ifdef CONFIG_RETHUNK
RETHUNK_CFLAGS         := -mfunction-return=thunk-extern
RETPOLINE_CFLAGS       += $(RETHUNK_CFLAGS)
endif

export RETPOLINE_CFLAGS
export RETPOLINE_VDSO_CFLAGS

include arch/$(SRCARCH)/Makefile

ifdef need-config
ifdef may-sync-config
# Read in dependencies to all Kconfig* files, make sure to run syncconfig if
# changes are detected. This should be included after arch/$(SRCARCH)/Makefile
# because some architectures define CROSS_COMPILE there.
include include/config/auto.conf.cmd

$(KCONFIG_CONFIG):
	@echo >&2 '***'
	@echo >&2 '*** Configuration file "$@" not found!'
	@echo >&2 '***'
	@echo >&2 '*** Please run some configurator (e.g. "make oldconfig" or'
	@echo >&2 '*** "make menuconfig" or "make xconfig").'
	@echo >&2 '***'
	@/bin/false

# The actual configuration files used during the build are stored in
# include/generated/ and include/config/. Update them if .config is newer than
# include/config/auto.conf (which mirrors .config).
#
# This exploits the 'multi-target pattern rule' trick.
# The syncconfig should be executed only once to make all the targets.
# (Note: use the grouped target '&:' when we bump to GNU Make 4.3)
#
# Do not use $(call cmd,...) here. That would suppress prompts from syncconfig,
# so you cannot notice that Kconfig is waiting for the user input.
%/config/auto.conf %/config/auto.conf.cmd %/generated/autoconf.h: $(KCONFIG_CONFIG)
	$(Q)$(kecho) "  SYNC    $@"
	$(Q)$(MAKE) -f $(srctree)/Makefile syncconfig
else # !may-sync-config
# External modules and some install targets need include/generated/autoconf.h
# and include/config/auto.conf but do not care if they are up-to-date.
# Use auto.conf to trigger the test
PHONY += include/config/auto.conf

include/config/auto.conf:
	$(Q)test -e include/generated/autoconf.h -a -e $@ || (		\
	echo >&2;							\
	echo >&2 "  ERROR: Kernel configuration is invalid.";		\
	echo >&2 "         include/generated/autoconf.h or $@ are missing.";\
	echo >&2 "         Run 'make oldconfig && make prepare' on kernel src to fix it.";	\
	echo >&2 ;							\
	/bin/false)

endif # may-sync-config
endif # need-config

KBUILD_CFLAGS	+= $(call cc-option,-fno-delete-null-pointer-checks,)
KBUILD_CFLAGS	+= $(call cc-disable-warning,frame-address,)
KBUILD_CFLAGS	+= $(call cc-disable-warning, format-truncation)
KBUILD_CFLAGS	+= $(call cc-disable-warning, format-overflow)
KBUILD_CFLAGS	+= $(call cc-disable-warning, address-of-packed-member)

ifdef CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE
KBUILD_CFLAGS += -O2
else ifdef CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3
KBUILD_CFLAGS += -O3
else ifdef CONFIG_CC_OPTIMIZE_FOR_SIZE
KBUILD_CFLAGS += -Os
endif

# Tell gcc to never replace conditional load with a non-conditional one
KBUILD_CFLAGS	+= $(call cc-option,--param=allow-store-data-races=0)
KBUILD_CFLAGS	+= $(call cc-option,-fno-allow-store-data-races)

ifdef CONFIG_READABLE_ASM
# Disable optimizations that make assembler listings hard to read.
# reorder blocks reorders the control in the function
# ipa clone creates specialized cloned functions
# partial inlining inlines only parts of functions
KBUILD_CFLAGS += $(call cc-option,-fno-reorder-blocks,) \
                 $(call cc-option,-fno-ipa-cp-clone,) \
                 $(call cc-option,-fno-partial-inlining)
endif

ifneq ($(CONFIG_FRAME_WARN),0)
KBUILD_CFLAGS += -Wframe-larger-than=$(CONFIG_FRAME_WARN)
endif

stackp-flags-y                                    := -fno-stack-protector
stackp-flags-$(CONFIG_STACKPROTECTOR)             := -fstack-protector
stackp-flags-$(CONFIG_STACKPROTECTOR_STRONG)      := -fstack-protector-strong

KBUILD_CFLAGS += $(stackp-flags-y)

ifdef CONFIG_CC_IS_CLANG
KBUILD_CPPFLAGS += -Qunused-arguments
KBUILD_CFLAGS += -Wno-format-invalid-specifier
KBUILD_CFLAGS += -Wno-gnu
# CLANG uses a _MergedGlobals as optimization, but this breaks modpost, as the
# source of a reference will be _MergedGlobals and not on of the whitelisted names.
# See modpost pattern 2
KBUILD_CFLAGS += -mno-global-merge
else

# Warn about unmarked fall-throughs in switch statement.
# Disabled for clang while comment to attribute conversion happens and
# https://github.com/ClangBuiltLinux/linux/issues/636 is discussed.
KBUILD_CFLAGS += $(call cc-option,-Wimplicit-fallthrough,)
endif

# These warnings generated too much noise in a regular build.
# Use make W=1 to enable them (see scripts/Makefile.extrawarn)
KBUILD_CFLAGS += $(call cc-disable-warning, unused-but-set-variable)

KBUILD_CFLAGS += $(call cc-disable-warning, unused-const-variable)
ifdef CONFIG_FRAME_POINTER
KBUILD_CFLAGS	+= -fno-omit-frame-pointer -fno-optimize-sibling-calls
else
# Some targets (ARM with Thumb2, for example), can't be built with frame
# pointers.  For those, we don't have FUNCTION_TRACER automatically
# select FRAME_POINTER.  However, FUNCTION_TRACER adds -pg, and this is
# incompatible with -fomit-frame-pointer with current GCC, so we don't use
# -fomit-frame-pointer with FUNCTION_TRACER.
ifndef CONFIG_FUNCTION_TRACER
KBUILD_CFLAGS	+= -fomit-frame-pointer
endif
endif

# Initialize all stack variables with a 0xAA pattern.
ifdef CONFIG_INIT_STACK_ALL_PATTERN
KBUILD_CFLAGS	+= -ftrivial-auto-var-init=pattern
endif

# Initialize all stack variables with a zero value.
ifdef CONFIG_INIT_STACK_ALL_ZERO
# Future support for zero initialization is still being debated, see
# https://bugs.llvm.org/show_bug.cgi?id=45497. These flags are subject to being
# renamed or dropped.
KBUILD_CFLAGS	+= -ftrivial-auto-var-init=zero
KBUILD_CFLAGS	+= -enable-trivial-auto-var-init-zero-knowing-it-will-be-removed-from-clang
endif

DEBUG_CFLAGS	:=

# Workaround for GCC versions < 5.0
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=61801
ifdef CONFIG_CC_IS_GCC
DEBUG_CFLAGS	+= $(call cc-ifversion, -lt, 0500, $(call cc-option, -fno-var-tracking-assignments))
endif

ifdef CONFIG_DEBUG_INFO

ifdef CONFIG_DEBUG_INFO_SPLIT
DEBUG_CFLAGS	+= -gsplit-dwarf
else
DEBUG_CFLAGS	+= -g
endif

ifneq ($(LLVM_IAS),1)
KBUILD_AFLAGS	+= -Wa,-gdwarf-2
endif

ifdef CONFIG_DEBUG_INFO_DWARF4
DEBUG_CFLAGS	+= -gdwarf-4
endif

ifdef CONFIG_DEBUG_INFO_REDUCED
DEBUG_CFLAGS	+= $(call cc-option, -femit-struct-debug-baseonly) \
		   $(call cc-option,-fno-var-tracking)
endif

ifdef CONFIG_DEBUG_INFO_COMPRESSED
DEBUG_CFLAGS	+= -gz=zlib
KBUILD_AFLAGS	+= -gz=zlib
KBUILD_LDFLAGS	+= --compress-debug-sections=zlib
endif

endif # CONFIG_DEBUG_INFO

KBUILD_CFLAGS += $(DEBUG_CFLAGS)
export DEBUG_CFLAGS

ifdef CONFIG_FUNCTION_TRACER
ifdef CONFIG_FTRACE_MCOUNT_RECORD
  # gcc 5 supports generating the mcount tables directly
  ifeq ($(call cc-option-yn,-mrecord-mcount),y)
    CC_FLAGS_FTRACE	+= -mrecord-mcount
    export CC_USING_RECORD_MCOUNT := 1
  endif
  ifdef CONFIG_HAVE_NOP_MCOUNT
    ifeq ($(call cc-option-yn, -mnop-mcount),y)
      CC_FLAGS_FTRACE	+= -mnop-mcount
      CC_FLAGS_USING	+= -DCC_USING_NOP_MCOUNT
    endif
  endif
endif
ifdef CONFIG_HAVE_FENTRY
  ifeq ($(call cc-option-yn, -mfentry),y)
    CC_FLAGS_FTRACE	+= -mfentry
    CC_FLAGS_USING	+= -DCC_USING_FENTRY
  endif
endif
export CC_FLAGS_FTRACE
KBUILD_CFLAGS	+= $(CC_FLAGS_FTRACE) $(CC_FLAGS_USING)
KBUILD_AFLAGS	+= $(CC_FLAGS_USING)
ifdef CONFIG_DYNAMIC_FTRACE
	ifdef CONFIG_HAVE_C_RECORDMCOUNT
		BUILD_C_RECORDMCOUNT := y
		export BUILD_C_RECORDMCOUNT
	endif
endif
endif

# We trigger additional mismatches with less inlining
ifdef CONFIG_DEBUG_SECTION_MISMATCH
KBUILD_CFLAGS += $(call cc-option, -fno-inline-functions-called-once)
endif

ifdef CONFIG_LD_DEAD_CODE_DATA_ELIMINATION
KBUILD_CFLAGS_KERNEL += -ffunction-sections -fdata-sections
LDFLAGS_vmlinux += --gc-sections
endif

ifdef CONFIG_SHADOW_CALL_STACK
CC_FLAGS_SCS	:= -fsanitize=shadow-call-stack
KBUILD_CFLAGS	+= $(CC_FLAGS_SCS)
export CC_FLAGS_SCS
endif

ifdef CONFIG_DEBUG_FORCE_FUNCTION_ALIGN_32B
KBUILD_CFLAGS += -falign-functions=32
endif

# arch Makefile may override CC so keep this after arch Makefile is included
NOSTDINC_FLAGS += -nostdinc -isystem $(shell $(CC) -print-file-name=include)

# warn about C99 declaration after statement
KBUILD_CFLAGS += -Wdeclaration-after-statement

# Variable Length Arrays (VLAs) should not be used anywhere in the kernel
KBUILD_CFLAGS += -Wvla

# disable pointer signed / unsigned warnings in gcc 4.0
KBUILD_CFLAGS += -Wno-pointer-sign

# disable stringop warnings in gcc 8+
KBUILD_CFLAGS += $(call cc-disable-warning, stringop-truncation)

# We'll want to enable this eventually, but it's not going away for 5.7 at least
KBUILD_CFLAGS += $(call cc-disable-warning, zero-length-bounds)
KBUILD_CFLAGS += $(call cc-disable-warning, array-bounds)
KBUILD_CFLAGS += $(call cc-disable-warning, stringop-overflow)

# Another good warning that we'll want to enable eventually
KBUILD_CFLAGS += $(call cc-disable-warning, restrict)

# Enabled with W=2, disabled by default as noisy
KBUILD_CFLAGS += $(call cc-disable-warning, maybe-uninitialized)

# disable invalid "can't wrap" optimizations for signed / pointers
KBUILD_CFLAGS	+= -fno-strict-overflow

# Make sure -fstack-check isn't enabled (like gentoo apparently did)
KBUILD_CFLAGS  += -fno-stack-check

# conserve stack if available
KBUILD_CFLAGS   += $(call cc-option,-fconserve-stack)

# Prohibit date/time macros, which would make the build non-deterministic
KBUILD_CFLAGS   += -Werror=date-time

# enforce correct pointer usage
KBUILD_CFLAGS   += $(call cc-option,-Werror=incompatible-pointer-types)

# Require designated initializers for all marked structures
KBUILD_CFLAGS   += $(call cc-option,-Werror=designated-init)

# change __FILE__ to the relative path from the srctree
KBUILD_CPPFLAGS += $(call cc-option,-fmacro-prefix-map=$(srctree)/=)

# include additional Makefiles when needed
include-y			:= scripts/Makefile.extrawarn
include-$(CONFIG_KASAN)		+= scripts/Makefile.kasan
include-$(CONFIG_KCSAN)		+= scripts/Makefile.kcsan
include-$(CONFIG_UBSAN)		+= scripts/Makefile.ubsan
include-$(CONFIG_KCOV)		+= scripts/Makefile.kcov
include-$(CONFIG_GCC_PLUGINS)	+= scripts/Makefile.gcc-plugins

include $(addprefix $(srctree)/, $(include-y))

# scripts/Makefile.gcc-plugins is intentionally included last.
# Do not add $(call cc-option,...) below this line. When you build the kernel
# from the clean source tree, the GCC plugins do not exist at this point.

# Add user supplied CPPFLAGS, AFLAGS and CFLAGS as the last assignments
KBUILD_CPPFLAGS += $(KCPPFLAGS)
KBUILD_AFLAGS   += $(KAFLAGS)
KBUILD_CFLAGS   += $(KCFLAGS)

KBUILD_LDFLAGS_MODULE += --build-id=sha1
LDFLAGS_vmlinux += --build-id=sha1

ifeq ($(CONFIG_STRIP_ASM_SYMS),y)
LDFLAGS_vmlinux	+= $(call ld-option, -X,)
endif

ifeq ($(CONFIG_RELR),y)
LDFLAGS_vmlinux	+= --pack-dyn-relocs=relr --use-android-relr-tags
endif

# We never want expected sections to be placed heuristically by the
# linker. All sections should be explicitly named in the linker script.
ifdef CONFIG_LD_ORPHAN_WARN
LDFLAGS_vmlinux += --orphan-handling=warn
endif

# Align the bit size of userspace programs with the kernel
KBUILD_USERCFLAGS  += $(filter -m32 -m64 --target=%, $(KBUILD_CFLAGS))
KBUILD_USERLDFLAGS += $(filter -m32 -m64 --target=%, $(KBUILD_CFLAGS))

# make the checker run with the right architecture
CHECKFLAGS += --arch=$(ARCH)

# insure the checker run with the right endianness
CHECKFLAGS += $(if $(CONFIG_CPU_BIG_ENDIAN),-mbig-endian,-mlittle-endian)

# the checker needs the correct machine size
CHECKFLAGS += $(if $(CONFIG_64BIT),-m64,-m32)

# Default kernel image to build when no specific target is given.
# KBUILD_IMAGE may be overruled on the command line or
# set in the environment
# Also any assignments in arch/$(ARCH)/Makefile take precedence over
# this default value
export KBUILD_IMAGE ?= vmlinux

#
# INSTALL_PATH specifies where to place the updated kernel and system map
# images. Default is /boot, but you can set it to other values
export	INSTALL_PATH ?= /boot

#
# INSTALL_DTBS_PATH specifies a prefix for relocations required by build roots.
# Like INSTALL_MOD_PATH, it isn't defined in the Makefile, but can be passed as
# an argument if needed. Otherwise it defaults to the kernel install path
#
export INSTALL_DTBS_PATH ?= $(INSTALL_PATH)/dtbs/$(KERNELRELEASE)

#
# INSTALL_MOD_PATH specifies a prefix to MODLIB for module directory
# relocations required by build roots.  This is not defined in the
# makefile but the argument can be passed to make if needed.
#

MODLIB	= $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)
export MODLIB

#
# INSTALL_MOD_STRIP, if defined, will cause modules to be
# stripped after they are installed.  If INSTALL_MOD_STRIP is '1', then
# the default option --strip-debug will be used.  Otherwise,
# INSTALL_MOD_STRIP value will be used as the options to the strip command.

ifdef INSTALL_MOD_STRIP
ifeq ($(INSTALL_MOD_STRIP),1)
mod_strip_cmd = $(STRIP) --strip-debug
else
mod_strip_cmd = $(STRIP) $(INSTALL_MOD_STRIP)
endif # INSTALL_MOD_STRIP=1
else
mod_strip_cmd = true
endif # INSTALL_MOD_STRIP
export mod_strip_cmd

# CONFIG_MODULE_COMPRESS, if defined, will cause module to be compressed
# after they are installed in agreement with CONFIG_MODULE_COMPRESS_GZIP
# or CONFIG_MODULE_COMPRESS_XZ.

mod_compress_cmd = true
ifdef CONFIG_MODULE_COMPRESS
  ifdef CONFIG_MODULE_COMPRESS_GZIP
    mod_compress_cmd = $(KGZIP) -n -f
  endif # CONFIG_MODULE_COMPRESS_GZIP
  ifdef CONFIG_MODULE_COMPRESS_XZ
    mod_compress_cmd = $(XZ) -f
  endif # CONFIG_MODULE_COMPRESS_XZ
endif # CONFIG_MODULE_COMPRESS
export mod_compress_cmd

ifdef CONFIG_MODULE_SIG_ALL
$(eval $(call config_filename,MODULE_SIG_KEY))

mod_sign_cmd = scripts/sign-file $(CONFIG_MODULE_SIG_HASH) $(MODULE_SIG_KEY_SRCPREFIX)$(CONFIG_MODULE_SIG_KEY) certs/signing_key.x509
else
mod_sign_cmd = true
endif
export mod_sign_cmd

HOST_LIBELF_LIBS = $(shell pkg-config libelf --libs 2>/dev/null || echo -lelf)

has_libelf = $(call try-run,\
               echo "int main() {}" | $(HOSTCC) $(KBUILD_HOSTLDFLAGS) -xc -o /dev/null $(HOST_LIBELF_LIBS) -,1,0)

ifdef CONFIG_STACK_VALIDATION
  ifeq ($(has_libelf),1)
    objtool_target := tools/objtool FORCE
  else
    SKIP_STACK_VALIDATION := 1
    export SKIP_STACK_VALIDATION
  endif
endif

PHONY += resolve_btfids_clean

resolve_btfids_O = $(abspath $(objtree))/tools/bpf/resolve_btfids

# tools/bpf/resolve_btfids directory might not exist
# in output directory, skip its clean in that case
resolve_btfids_clean:
ifneq ($(wildcard $(resolve_btfids_O)),)
	$(Q)$(MAKE) -sC $(srctree)/tools/bpf/resolve_btfids O=$(resolve_btfids_O) clean
endif

ifdef CONFIG_BPF
ifdef CONFIG_DEBUG_INFO_BTF
  ifeq ($(has_libelf),1)
    resolve_btfids_target := tools/bpf/resolve_btfids FORCE
  else
    ERROR_RESOLVE_BTFIDS := 1
  endif
endif # CONFIG_DEBUG_INFO_BTF
endif # CONFIG_BPF

PHONY += prepare0

export MODORDER := $(extmod-prefix)modules.order
export MODULES_NSDEPS := $(extmod-prefix)modules.nsdeps

ifeq ($(KBUILD_EXTMOD),)
core-y		+= kernel/ certs/ mm/ fs/ ipc/ security/ crypto/ block/

vmlinux-dirs	:= $(patsubst %/,%,$(filter %/, \
		     $(core-y) $(core-m) $(drivers-y) $(drivers-m) \
		     $(libs-y) $(libs-m)))

vmlinux-alldirs	:= $(sort $(vmlinux-dirs) Documentation \
		     $(patsubst %/,%,$(filter %/, $(core-) \
			$(drivers-) $(libs-))))

subdir-modorder := $(addsuffix modules.order,$(filter %/, \
			$(core-y) $(core-m) $(libs-y) $(libs-m) \
			$(drivers-y) $(drivers-m)))

build-dirs	:= $(vmlinux-dirs)
clean-dirs	:= $(vmlinux-alldirs)

# Externally visible symbols (used by link-vmlinux.sh)
KBUILD_VMLINUX_OBJS := $(head-y) $(patsubst %/,%/built-in.a, $(core-y))
KBUILD_VMLINUX_OBJS += $(addsuffix built-in.a, $(filter %/, $(libs-y)))
ifdef CONFIG_MODULES
KBUILD_VMLINUX_OBJS += $(patsubst %/, %/lib.a, $(filter %/, $(libs-y)))
KBUILD_VMLINUX_LIBS := $(filter-out %/, $(libs-y))
else
KBUILD_VMLINUX_LIBS := $(patsubst %/,%/lib.a, $(libs-y))
endif
KBUILD_VMLINUX_OBJS += $(patsubst %/,%/built-in.a, $(drivers-y))

export KBUILD_VMLINUX_OBJS KBUILD_VMLINUX_LIBS
export KBUILD_LDS          := arch/$(SRCARCH)/kernel/vmlinux.lds
# used by scripts/Makefile.package
export KBUILD_ALLDIRS := $(sort $(filter-out arch/%,$(vmlinux-alldirs)) LICENSES arch include scripts tools)

vmlinux-deps := $(KBUILD_LDS) $(KBUILD_VMLINUX_OBJS) $(KBUILD_VMLINUX_LIBS)

# Recurse until adjust_autoksyms.sh is satisfied
PHONY += autoksyms_recursive
ifdef CONFIG_TRIM_UNUSED_KSYMS
# For the kernel to actually contain only the needed exported symbols,
# we have to build modules as well to determine what those symbols are.
# (this can be evaluated only once include/config/auto.conf has been included)
KBUILD_MODULES := 1

autoksyms_recursive: descend modules.order
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/adjust_autoksyms.sh \
	  "$(MAKE) -f $(srctree)/Makefile autoksyms_recursive"
endif

autoksyms_h := $(if $(CONFIG_TRIM_UNUSED_KSYMS), include/generated/autoksyms.h)

quiet_cmd_autoksyms_h = GEN     $@
      cmd_autoksyms_h = mkdir -p $(dir $@); \
			$(CONFIG_SHELL) $(srctree)/scripts/gen_autoksyms.sh $@

$(autoksyms_h):
	$(call cmd,autoksyms_h)

ARCH_POSTLINK := $(wildcard $(srctree)/arch/$(SRCARCH)/Makefile.postlink)

# Final link of vmlinux with optional arch pass after final link
cmd_link-vmlinux =                                                 \
	$(CONFIG_SHELL) $< "$(LD)" "$(KBUILD_LDFLAGS)" "$(LDFLAGS_vmlinux)";    \
	$(if $(ARCH_POSTLINK), $(MAKE) -f $(ARCH_POSTLINK) $@, true)

vmlinux: scripts/link-vmlinux.sh autoksyms_recursive $(vmlinux-deps) FORCE
	+$(call if_changed,link-vmlinux)

targets := vmlinux

# The actual objects are generated when descending,
# make sure no implicit rule kicks in
$(sort $(vmlinux-deps) $(subdir-modorder)): descend ;

filechk_kernel.release = \
	echo "$(KERNELVERSION)$$($(CONFIG_SHELL) $(srctree)/scripts/setlocalversion $(srctree))"

# Store (new) KERNELRELEASE string in include/config/kernel.release
include/config/kernel.release: FORCE
	$(call filechk,kernel.release)

# Additional helpers built in scripts/
# Carefully list dependencies so we do not try to build scripts twice
# in parallel
PHONY += scripts
scripts: scripts_basic scripts_dtc
	$(Q)$(MAKE) $(build)=$(@)

# Things we need to do before we recursively start building the kernel
# or the modules are listed in "prepare".
# A multi level approach is used. prepareN is processed before prepareN-1.
# archprepare is used in arch Makefiles and when processed asm symlink,
# version.h and scripts_basic is processed / created.

PHONY += prepare archprepare

archprepare: outputmakefile archheaders archscripts scripts include/config/kernel.release \
	asm-generic $(version_h) $(autoksyms_h) include/generated/utsrelease.h \
	include/generated/autoconf.h

prepare0: archprepare
	$(Q)$(MAKE) $(build)=scripts/mod
	$(Q)$(MAKE) $(build)=.

# All the preparing..
prepare: prepare0 prepare-objtool prepare-resolve_btfids

# Support for using generic headers in asm-generic
asm-generic := -f $(srctree)/scripts/Makefile.asm-generic obj

PHONY += asm-generic uapi-asm-generic
asm-generic: uapi-asm-generic
	$(Q)$(MAKE) $(asm-generic)=arch/$(SRCARCH)/include/generated/asm \
	generic=include/asm-generic
uapi-asm-generic:
	$(Q)$(MAKE) $(asm-generic)=arch/$(SRCARCH)/include/generated/uapi/asm \
	generic=include/uapi/asm-generic

PHONY += prepare-objtool prepare-resolve_btfids
prepare-objtool: $(objtool_target)
ifeq ($(SKIP_STACK_VALIDATION),1)
ifdef CONFIG_UNWINDER_ORC
	@echo "error: Cannot generate ORC metadata for CONFIG_UNWINDER_ORC=y, please install libelf-dev, libelf-devel or elfutils-libelf-devel" >&2
	@false
else
	@echo "warning: Cannot use CONFIG_STACK_VALIDATION=y, please install libelf-dev, libelf-devel or elfutils-libelf-devel" >&2
endif
endif

prepare-resolve_btfids: $(resolve_btfids_target)
ifeq ($(ERROR_RESOLVE_BTFIDS),1)
	@echo "error: Cannot resolve BTF IDs for CONFIG_DEBUG_INFO_BTF, please install libelf-dev, libelf-devel or elfutils-libelf-devel" >&2
	@false
endif
# Generate some files
# ---------------------------------------------------------------------------

# KERNELRELEASE can change from a few different places, meaning version.h
# needs to be updated, so this check is forced on all builds

uts_len := 64
define filechk_utsrelease.h
	if [ `echo -n "$(KERNELRELEASE)" | wc -c ` -gt $(uts_len) ]; then \
	  echo '"$(KERNELRELEASE)" exceeds $(uts_len) characters' >&2;    \
	  exit 1;                                                         \
	fi;                                                               \
	echo \#define UTS_RELEASE \"$(KERNELRELEASE)\"
endef

define filechk_version.h
	if [ $(SUBLEVEL) -gt 255 ]; then                                 \
		echo \#define LINUX_VERSION_CODE $(shell                 \
		expr $(VERSION) \* 65536 + $(PATCHLEVEL) \* 256 + 255); \
	else                                                             \
		echo \#define LINUX_VERSION_CODE $(shell                 \
		expr $(VERSION) \* 65536 + $(PATCHLEVEL) \* 256 + $(SUBLEVEL)); \
	fi;                                                              \
	echo '#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) +  \
	((c) > 255 ? 255 : (c)))'
endef

$(version_h): PATCHLEVEL := $(if $(PATCHLEVEL), $(PATCHLEVEL), 0)
$(version_h): SUBLEVEL := $(if $(SUBLEVEL), $(SUBLEVEL), 0)
$(version_h): FORCE
	$(call filechk,version.h)
	$(Q)rm -f $(old_version_h)

include/generated/utsrelease.h: include/config/kernel.release FORCE
	$(call filechk,utsrelease.h)

PHONY += headerdep
headerdep:
	$(Q)find $(srctree)/include/ -name '*.h' | xargs --max-args 1 \
	$(srctree)/scripts/headerdep.pl -I$(srctree)/include

# ---------------------------------------------------------------------------
# Kernel headers

#Default location for installed headers
export INSTALL_HDR_PATH = $(objtree)/usr

quiet_cmd_headers_install = INSTALL $(INSTALL_HDR_PATH)/include
      cmd_headers_install = \
	mkdir -p $(INSTALL_HDR_PATH); \
	rsync -mrl --include='*/' --include='*\.h' --exclude='*' \
	usr/include $(INSTALL_HDR_PATH)

PHONY += headers_install
headers_install: headers
	$(call cmd,headers_install)

PHONY += archheaders archscripts

hdr-inst := -f $(srctree)/scripts/Makefile.headersinst obj

PHONY += headers
headers: $(version_h) scripts_unifdef uapi-asm-generic archheaders archscripts
	$(if $(wildcard $(srctree)/arch/$(SRCARCH)/include/uapi/asm/Kbuild),, \
	  $(error Headers not exportable for the $(SRCARCH) architecture))
	$(Q)$(MAKE) $(hdr-inst)=include/uapi
	$(Q)$(MAKE) $(hdr-inst)=arch/$(SRCARCH)/include/uapi

# Deprecated. It is no-op now.
PHONY += headers_check
headers_check:
	@:

ifdef CONFIG_HEADERS_INSTALL
prepare: headers
endif

PHONY += scripts_unifdef
scripts_unifdef: scripts_basic
	$(Q)$(MAKE) $(build)=scripts scripts/unifdef

# ---------------------------------------------------------------------------
# Kernel selftest

PHONY += kselftest
kselftest:
	$(Q)$(MAKE) -C $(srctree)/tools/testing/selftests run_tests

kselftest-%: FORCE
	$(Q)$(MAKE) -C $(srctree)/tools/testing/selftests $*

PHONY += kselftest-merge
kselftest-merge:
	$(if $(wildcard $(objtree)/.config),, $(error No .config exists, config your kernel first!))
	$(Q)find $(srctree)/tools/testing/selftests -name config | \
		xargs $(srctree)/scripts/kconfig/merge_config.sh -m $(objtree)/.config
	$(Q)$(MAKE) -f $(srctree)/Makefile olddefconfig

# ---------------------------------------------------------------------------
# Devicetree files

ifneq ($(wildcard $(srctree)/arch/$(SRCARCH)/boot/dts/),)
dtstree := arch/$(SRCARCH)/boot/dts
endif

ifneq ($(dtstree),)

%.dtb: include/config/kernel.release scripts_dtc
	$(Q)$(MAKE) $(build)=$(dtstree) $(dtstree)/$@

PHONY += dtbs dtbs_install dtbs_check
dtbs: include/config/kernel.release scripts_dtc
	$(Q)$(MAKE) $(build)=$(dtstree)

ifneq ($(filter dtbs_check, $(MAKECMDGOALS)),)
export CHECK_DTBS=y
dtbs: dt_binding_check
endif

dtbs_check: dtbs

dtbs_install:
	$(Q)$(MAKE) $(dtbinst)=$(dtstree) dst=$(INSTALL_DTBS_PATH)

ifdef CONFIG_OF_EARLY_FLATTREE
all: dtbs
endif

endif

PHONY += scripts_dtc
scripts_dtc: scripts_basic
	$(Q)$(MAKE) $(build)=scripts/dtc

ifneq ($(filter dt_binding_check, $(MAKECMDGOALS)),)
export CHECK_DT_BINDING=y
endif

PHONY += dt_binding_check
dt_binding_check: scripts_dtc
	$(Q)$(MAKE) $(build)=Documentation/devicetree/bindings

# ---------------------------------------------------------------------------
# Modules

ifdef CONFIG_MODULES

# By default, build modules as well

all: modules

# When we're building modules with modversions, we need to consider
# the built-in objects during the descend as well, in order to
# make sure the checksums are up to date before we record them.
ifdef CONFIG_MODVERSIONS
  KBUILD_BUILTIN := 1
endif

# Build modules
#
# A module can be listed more than once in obj-m resulting in
# duplicate lines in modules.order files.  Those are removed
# using awk while concatenating to the final file.

PHONY += modules
modules: $(if $(KBUILD_BUILTIN),vmlinux) modules_check modules_prepare
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modpost

PHONY += modules_check
modules_check: modules.order
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/modules-check.sh $<

cmd_modules_order = $(AWK) '!x[$$0]++' $(real-prereqs) > $@

modules.order: $(subdir-modorder) FORCE
	$(call if_changed,modules_order)

targets += modules.order

# Target to prepare building external modules
PHONY += modules_prepare
modules_prepare: prepare
	$(Q)$(MAKE) $(build)=scripts scripts/module.lds

# Target to install modules
PHONY += modules_install
modules_install: _modinst_ _modinst_post

PHONY += _modinst_
_modinst_:
	@rm -rf $(MODLIB)/kernel
	@rm -f $(MODLIB)/source
	@mkdir -p $(MODLIB)/kernel
	@ln -s $(abspath $(srctree)) $(MODLIB)/source
	@if [ ! $(objtree) -ef  $(MODLIB)/build ]; then \
		rm -f $(MODLIB)/build ; \
		ln -s $(CURDIR) $(MODLIB)/build ; \
	fi
	@sed 's:^:kernel/:' modules.order > $(MODLIB)/modules.order
	@cp -f modules.builtin $(MODLIB)/
	@cp -f $(objtree)/modules.builtin.modinfo $(MODLIB)/
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modinst

# This depmod is only for convenience to give the initial
# boot a modules.dep even before / is mounted read-write.  However the
# boot script depmod is the master version.
PHONY += _modinst_post
_modinst_post: _modinst_
	$(call cmd,depmod)

ifeq ($(CONFIG_MODULE_SIG), y)
PHONY += modules_sign
modules_sign:
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modsign
endif

else # CONFIG_MODULES

# Modules not configured
# ---------------------------------------------------------------------------

PHONY += modules modules_install
modules modules_install:
	@echo >&2
	@echo >&2 "The present kernel configuration has modules disabled."
	@echo >&2 "Type 'make config' and enable loadable module support."
	@echo >&2 "Then build a kernel with module support enabled."
	@echo >&2
	@exit 1

endif # CONFIG_MODULES

###
# Cleaning is done on three levels.
# make clean     Delete most generated files
#                Leave enough to build external modules
# make mrproper  Delete the current configuration, and all generated files
# make distclean Remove editor backup files, patch leftover files and the like

# Directories & files removed with 'make clean'
CLEAN_FILES += include/ksym vmlinux.symvers modules-only.symvers \
	       modules.builtin modules.builtin.modinfo modules.nsdeps \
	       compile_commands.json

# Directories & files removed with 'make mrproper'
MRPROPER_FILES += include/config include/generated          \
		  arch/$(SRCARCH)/include/generated .tmp_objdiff \
		  debian snap tar-install \
		  .config .config.old .version \
		  Module.symvers \
		  signing_key.pem signing_key.priv signing_key.x509	\
		  x509.genkey extra_certificates signing_key.x509.keyid	\
		  signing_key.x509.signer vmlinux-gdb.py \
		  *.spec

# Directories & files removed with 'make distclean'
DISTCLEAN_FILES += tags TAGS cscope* GPATH GTAGS GRTAGS GSYMS

# clean - Delete most, but leave enough to build external modules
#
clean: rm-files := $(CLEAN_FILES)

PHONY += archclean vmlinuxclean

vmlinuxclean:
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/link-vmlinux.sh clean
	$(Q)$(if $(ARCH_POSTLINK), $(MAKE) -f $(ARCH_POSTLINK) clean)

clean: archclean vmlinuxclean resolve_btfids_clean

# mrproper - Delete all generated files, including .config
#
mrproper: rm-files := $(wildcard $(MRPROPER_FILES))
mrproper-dirs      := $(addprefix _mrproper_,scripts)

PHONY += $(mrproper-dirs) mrproper
$(mrproper-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _mrproper_%,%,$@)

mrproper: clean $(mrproper-dirs)
	$(call cmd,rmfiles)

# distclean
#
distclean: rm-files := $(wildcard $(DISTCLEAN_FILES))

PHONY += distclean

distclean: mrproper
	$(call cmd,rmfiles)
	@find $(srctree) $(RCS_FIND_IGNORE) \
		\( -name '*.orig' -o -name '*.rej' -o -name '*~' \
		-o -name '*.bak' -o -name '#*#' -o -name '*%' \
		-o -name 'core' \) \
		-type f -print | xargs rm -f


# Packaging of the kernel to various formats
# ---------------------------------------------------------------------------

%src-pkg: FORCE
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.package $@
%pkg: include/config/kernel.release FORCE
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.package $@

# Brief documentation of the typical targets used
# ---------------------------------------------------------------------------

boards := $(wildcard $(srctree)/arch/$(SRCARCH)/configs/*_defconfig)
boards := $(sort $(notdir $(boards)))
board-dirs := $(dir $(wildcard $(srctree)/arch/$(SRCARCH)/configs/*/*_defconfig))
board-dirs := $(sort $(notdir $(board-dirs:/=)))

PHONY += help
help:
	@echo  'Cleaning targets:'
	@echo  '  clean		  - Remove most generated files but keep the config and'
	@echo  '                    enough build support to build external modules'
	@echo  '  mrproper	  - Remove all generated files + config + various backup files'
	@echo  '  distclean	  - mrproper + remove editor backup and patch files'
	@echo  ''
	@echo  'Configuration targets:'
	@$(MAKE) -f $(srctree)/scripts/kconfig/Makefile help
	@echo  ''
	@echo  'Other generic targets:'
	@echo  '  all		  - Build all targets marked with [*]'
	@echo  '* vmlinux	  - Build the bare kernel'
	@echo  '* modules	  - Build all modules'
	@echo  '  modules_install - Install all modules to INSTALL_MOD_PATH (default: /)'
	@echo  '  dir/            - Build all files in dir and below'
	@echo  '  dir/file.[ois]  - Build specified target only'
	@echo  '  dir/file.ll     - Build the LLVM assembly file'
	@echo  '                    (requires compiler support for LLVM assembly generation)'
	@echo  '  dir/file.lst    - Build specified mixed source/assembly target only'
	@echo  '                    (requires a recent binutils and recent build (System.map))'
	@echo  '  dir/file.ko     - Build module including final link'
	@echo  '  modules_prepare - Set up for building external modules'
	@echo  '  tags/TAGS	  - Generate tags file for editors'
	@echo  '  cscope	  - Generate cscope index'
	@echo  '  gtags           - Generate GNU GLOBAL index'
	@echo  '  kernelrelease	  - Output the release version string (use with make -s)'
	@echo  '  kernelversion	  - Output the version stored in Makefile (use with make -s)'
	@echo  '  image_name	  - Output the image name (use with make -s)'
	@echo  '  headers_install - Install sanitised kernel headers to INSTALL_HDR_PATH'; \
	 echo  '                    (default: $(INSTALL_HDR_PATH))'; \
	 echo  ''
	@echo  'Static analysers:'
	@echo  '  checkstack      - Generate a list of stack hogs'
	@echo  '  versioncheck    - Sanity check on version.h usage'
	@echo  '  includecheck    - Check for duplicate included header files'
	@echo  '  export_report   - List the usages of all exported symbols'
	@echo  '  headerdep       - Detect inclusion cycles in headers'
	@echo  '  coccicheck      - Check with Coccinelle'
	@echo  '  clang-analyzer  - Check with clang static analyzer'
	@echo  '  clang-tidy      - Check with clang-tidy'
	@echo  ''
	@echo  'Tools:'
	@echo  '  nsdeps          - Generate missing symbol namespace dependencies'
	@echo  ''
	@echo  'Kernel selftest:'
	@echo  '  kselftest         - Build and run kernel selftest'
	@echo  '                      Build, install, and boot kernel before'
	@echo  '                      running kselftest on it'
	@echo  '                      Run as root for full coverage'
	@echo  '  kselftest-all     - Build kernel selftest'
	@echo  '  kselftest-install - Build and install kernel selftest'
	@echo  '  kselftest-clean   - Remove all generated kselftest files'
	@echo  '  kselftest-merge   - Merge all the config dependencies of'
	@echo  '		      kselftest to existing .config.'
	@echo  ''
	@$(if $(dtstree), \
		echo 'Devicetree:'; \
		echo '* dtbs             - Build device tree blobs for enabled boards'; \
		echo '  dtbs_install     - Install dtbs to $(INSTALL_DTBS_PATH)'; \
		echo '  dt_binding_check - Validate device tree binding documents'; \
		echo '  dtbs_check       - Validate device tree source files';\
		echo '')

	@echo 'Userspace tools targets:'
	@echo '  use "make tools/help"'
	@echo '  or  "cd tools; make help"'
	@echo  ''
	@echo  'Kernel packaging:'
	@$(MAKE) -f $(srctree)/scripts/Makefile.package help
	@echo  ''
	@echo  'Documentation targets:'
	@$(MAKE) -f $(srctree)/Documentation/Makefile dochelp
	@echo  ''
	@echo  'Architecture specific targets ($(SRCARCH)):'
	@$(if $(archhelp),$(archhelp),\
		echo '  No architecture specific help defined for $(SRCARCH)')
	@echo  ''
	@$(if $(boards), \
		$(foreach b, $(boards), \
		printf "  %-27s - Build for %s\\n" $(b) $(subst _defconfig,,$(b));) \
		echo '')
	@$(if $(board-dirs), \
		$(foreach b, $(board-dirs), \
		printf "  %-16s - Show %s-specific targets\\n" help-$(b) $(b);) \
		printf "  %-16s - Show all of the above\\n" help-boards; \
		echo '')

	@echo  '  make V=0|1 [targets] 0 => quiet build (default), 1 => verbose build'
	@echo  '  make V=2   [targets] 2 => give reason for rebuild of target'
	@echo  '  make O=dir [targets] Locate all output files in "dir", including .config'
	@echo  '  make C=1   [targets] Check re-compiled c source with $$CHECK'
	@echo  '                       (sparse by default)'
	@echo  '  make C=2   [targets] Force check of all c source with $$CHECK'
	@echo  '  make RECORDMCOUNT_WARN=1 [targets] Warn about ignored mcount sections'
	@echo  '  make W=n   [targets] Enable extra build checks, n=1,2,3 where'
	@echo  '		1: warnings which may be relevant and do not occur too often'
	@echo  '		2: warnings which occur quite often but may still be relevant'
	@echo  '		3: more obscure warnings, can most likely be ignored'
	@echo  '		Multiple levels can be combined with W=12 or W=123'
	@echo  ''
	@echo  'Execute "make" or "make all" to build all targets marked with [*] '
	@echo  'For further info see the ./README file'


help-board-dirs := $(addprefix help-,$(board-dirs))

help-boards: $(help-board-dirs)

boards-per-dir = $(sort $(notdir $(wildcard $(srctree)/arch/$(SRCARCH)/configs/$*/*_defconfig)))

$(help-board-dirs): help-%:
	@echo  'Architecture specific targets ($(SRCARCH) $*):'
	@$(if $(boards-per-dir), \
		$(foreach b, $(boards-per-dir), \
		printf "  %-24s - Build for %s\\n" $*/$(b) $(subst _defconfig,,$(b));) \
		echo '')


# Documentation targets
# ---------------------------------------------------------------------------
DOC_TARGETS := xmldocs latexdocs pdfdocs htmldocs epubdocs cleandocs \
	       linkcheckdocs dochelp refcheckdocs
PHONY += $(DOC_TARGETS)
$(DOC_TARGETS):
	$(Q)$(MAKE) $(build)=Documentation $@

# Misc
# ---------------------------------------------------------------------------

PHONY += scripts_gdb
scripts_gdb: prepare0
	$(Q)$(MAKE) $(build)=scripts/gdb
	$(Q)ln -fsn $(abspath $(srctree)/scripts/gdb/vmlinux-gdb.py)

ifdef CONFIG_GDB_SCRIPTS
all: scripts_gdb
endif

else # KBUILD_EXTMOD

###
# External module support.
# When building external modules the kernel used as basis is considered
# read-only, and no consistency checks are made and the make
# system is not used on the basis kernel. If updates are required
# in the basis kernel ordinary make commands (without M=...) must
# be used.
#
# The following are the only valid targets when building external
# modules.
# make M=dir clean     Delete all automatically generated files
# make M=dir modules   Make all modules in specified dir
# make M=dir	       Same as 'make M=dir modules'
# make M=dir modules_install
#                      Install the modules built in the module directory
#                      Assumes install directory is already created

# We are always building only modules.
KBUILD_BUILTIN :=
KBUILD_MODULES := 1

build-dirs := $(KBUILD_EXTMOD)
PHONY += modules
modules: $(MODORDER)
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modpost

$(MODORDER): descend
	@:

PHONY += modules_install
modules_install: _emodinst_ _emodinst_post

install-dir := $(if $(INSTALL_MOD_DIR),$(INSTALL_MOD_DIR),extra)
PHONY += _emodinst_
_emodinst_:
	$(Q)mkdir -p $(MODLIB)/$(install-dir)
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modinst

PHONY += _emodinst_post
_emodinst_post: _emodinst_
	$(call cmd,depmod)

compile_commands.json: $(extmod-prefix)compile_commands.json
PHONY += compile_commands.json

clean-dirs := $(KBUILD_EXTMOD)
clean: rm-files := $(KBUILD_EXTMOD)/Module.symvers $(KBUILD_EXTMOD)/modules.nsdeps \
	$(KBUILD_EXTMOD)/compile_commands.json

PHONY += help
help:
	@echo  '  Building external modules.'
	@echo  '  Syntax: make -C path/to/kernel/src M=$$PWD target'
	@echo  ''
	@echo  '  modules         - default target, build the module(s)'
	@echo  '  modules_install - install the module'
	@echo  '  clean           - remove generated files in module directory only'
	@echo  ''

# no-op for external module builds
PHONY += prepare modules_prepare

endif # KBUILD_EXTMOD

# Single targets
# ---------------------------------------------------------------------------
# To build individual files in subdirectories, you can do like this:
#
#   make foo/bar/baz.s
#
# The supported suffixes for single-target are listed in 'single-targets'
#
# To build only under specific subdirectories, you can do like this:
#
#   make foo/bar/baz/

ifdef single-build

# .ko is special because modpost is needed
single-ko := $(sort $(filter %.ko, $(MAKECMDGOALS)))
single-no-ko := $(sort $(patsubst %.ko,%.mod, $(MAKECMDGOALS)))

$(single-ko): single_modpost
	@:
$(single-no-ko): descend
	@:

ifeq ($(KBUILD_EXTMOD),)
# For the single build of in-tree modules, use a temporary file to avoid
# the situation of modules_install installing an invalid modules.order.
MODORDER := .modules.tmp
endif

PHONY += single_modpost
single_modpost: $(single-no-ko) modules_prepare
	$(Q){ $(foreach m, $(single-ko), echo $(extmod-prefix)$m;) } > $(MODORDER)
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modpost

KBUILD_MODULES := 1

export KBUILD_SINGLE_TARGETS := $(addprefix $(extmod-prefix), $(single-no-ko))

# trim unrelated directories
build-dirs := $(foreach d, $(build-dirs), \
			$(if $(filter $(d)/%, $(KBUILD_SINGLE_TARGETS)), $(d)))

endif

ifndef CONFIG_MODULES
KBUILD_MODULES :=
endif

# Handle descending into subdirectories listed in $(build-dirs)
# Preset locale variables to speed up the build process. Limit locale
# tweaks to this spot to avoid wrong language settings when running
# make menuconfig etc.
# Error messages still appears in the original language
PHONY += descend $(build-dirs)
descend: $(build-dirs)
$(build-dirs): prepare
	$(Q)$(MAKE) $(build)=$@ \
	single-build=$(if $(filter-out $@/, $(filter $@/%, $(KBUILD_SINGLE_TARGETS))),1) \
	need-builtin=1 need-modorder=1

clean-dirs := $(addprefix _clean_, $(clean-dirs))
PHONY += $(clean-dirs) clean
$(clean-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

clean: $(clean-dirs)
	$(call cmd,rmfiles)
	@find $(if $(KBUILD_EXTMOD), $(KBUILD_EXTMOD), .) $(RCS_FIND_IGNORE) \
		\( -name '*.[aios]' -o -name '*.ko' -o -name '.*.cmd' \
		-o -name '*.ko.*' \
		-o -name '*.dtb' -o -name '*.dtb.S' -o -name '*.dt.yaml' \
		-o -name '*.dwo' -o -name '*.lst' \
		-o -name '*.su' -o -name '*.mod' \
		-o -name '.*.d' -o -name '.*.tmp' -o -name '*.mod.c' \
		-o -name '*.lex.c' -o -name '*.tab.[ch]' \
		-o -name '*.asn1.[ch]' \
		-o -name '*.symtypes' -o -name 'modules.order' \
		-o -name '.tmp_*.o.*' \
		-o -name '*.c.[012]*.*' \
		-o -name '*.ll' \
		-o -name '*.gcno' \) -type f -print | xargs rm -f

# Generate tags for editors
# ---------------------------------------------------------------------------
quiet_cmd_tags = GEN     $@
      cmd_tags = $(BASH) $(srctree)/scripts/tags.sh $@

tags TAGS cscope gtags: FORCE
	$(call cmd,tags)

# Script to generate missing namespace dependencies
# ---------------------------------------------------------------------------

PHONY += nsdeps
nsdeps: export KBUILD_NSDEPS=1
nsdeps: modules
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/nsdeps

# Clang Tooling
# ---------------------------------------------------------------------------

quiet_cmd_gen_compile_commands = GEN     $@
      cmd_gen_compile_commands = $(PYTHON3) $< -a $(AR) -o $@ $(filter-out $<, $(real-prereqs))

$(extmod-prefix)compile_commands.json: scripts/clang-tools/gen_compile_commands.py \
	$(if $(KBUILD_EXTMOD),,$(KBUILD_VMLINUX_OBJS) $(KBUILD_VMLINUX_LIBS)) \
	$(if $(CONFIG_MODULES), $(MODORDER)) FORCE
	$(call if_changed,gen_compile_commands)

targets += $(extmod-prefix)compile_commands.json

PHONY += clang-tidy clang-analyzer

ifdef CONFIG_CC_IS_CLANG
quiet_cmd_clang_tools = CHECK   $<
      cmd_clang_tools = $(PYTHON3) $(srctree)/scripts/clang-tools/run-clang-tools.py $@ $<

clang-tidy clang-analyzer: $(extmod-prefix)compile_commands.json
	$(call cmd,clang_tools)
else
clang-tidy clang-analyzer:
	@echo "$@ requires CC=clang" >&2
	@false
endif

# Scripts to check various things for consistency
# ---------------------------------------------------------------------------

PHONY += includecheck versioncheck coccicheck export_report

includecheck:
	find $(srctree)/* $(RCS_FIND_IGNORE) \
		-name '*.[hcS]' -type f -print | sort \
		| xargs $(PERL) -w $(srctree)/scripts/checkincludes.pl

versioncheck:
	find $(srctree)/* $(RCS_FIND_IGNORE) \
		-name '*.[hcS]' -type f -print | sort \
		| xargs $(PERL) -w $(srctree)/scripts/checkversion.pl

coccicheck:
	$(Q)$(BASH) $(srctree)/scripts/$@

export_report:
	$(PERL) $(srctree)/scripts/export_report.pl

PHONY += checkstack kernelrelease kernelversion image_name

# UML needs a little special treatment here.  It wants to use the host
# toolchain, so needs $(SUBARCH) passed to checkstack.pl.  Everyone
# else wants $(ARCH), including people doing cross-builds, which means
# that $(SUBARCH) doesn't work here.
ifeq ($(ARCH), um)
CHECKSTACK_ARCH := $(SUBARCH)
else
CHECKSTACK_ARCH := $(ARCH)
endif
checkstack:
	$(OBJDUMP) -d vmlinux $$(find . -name '*.ko') | \
	$(PERL) $(srctree)/scripts/checkstack.pl $(CHECKSTACK_ARCH)

kernelrelease:
	@echo "$(KERNELVERSION)$$($(CONFIG_SHELL) $(srctree)/scripts/setlocalversion $(srctree))"

kernelversion:
	@echo $(KERNELVERSION)

image_name:
	@echo $(KBUILD_IMAGE)

# Clear a bunch of variables before executing the submake

ifeq ($(quiet),silent_)
tools_silent=s
endif

tools/: FORCE
	$(Q)mkdir -p $(objtree)/tools
	$(Q)$(MAKE) LDFLAGS= MAKEFLAGS="$(tools_silent) $(filter --j% -j,$(MAKEFLAGS))" O=$(abspath $(objtree)) subdir=tools -C $(srctree)/tools/

tools/%: FORCE
	$(Q)mkdir -p $(objtree)/tools
	$(Q)$(MAKE) LDFLAGS= MAKEFLAGS="$(tools_silent) $(filter --j% -j,$(MAKEFLAGS))" O=$(abspath $(objtree)) subdir=tools -C $(srctree)/tools/ $*

quiet_cmd_rmfiles = $(if $(wildcard $(rm-files)),CLEAN   $(wildcard $(rm-files)))
      cmd_rmfiles = rm -rf $(rm-files)

# Run depmod only if we have System.map and depmod is executable
quiet_cmd_depmod = DEPMOD  $(KERNELRELEASE)
      cmd_depmod = $(CONFIG_SHELL) $(srctree)/scripts/depmod.sh $(DEPMOD) \
                   $(KERNELRELEASE)

# read saved command lines for existing targets
existing-targets := $(wildcard $(sort $(targets)))

-include $(foreach f,$(existing-targets),$(dir $(f)).$(notdir $(f)).cmd)

endif # config-build
endif # mixed-build
endif # need-sub-make

PHONY += FORCE
FORCE:

# Declare the contents of the PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)
EXTRA_CFLAGS += $(USER_EXTRA_CFLAGS)
EXTRA_CFLAGS += -Os
#EXTRA_CFLAGS += -O3
#EXTRA_CFLAGS += -Wall
#EXTRA_CFLAGS += -Wextra
#EXTRA_CFLAGS += -Werror
#EXTRA_CFLAGS += -pedantic
#EXTRA_CFLAGS += -Wshadow -Wpointer-arith -Wcast-qual -Wstrict-prototypes -Wmissing-prototypes

EXTRA_CFLAGS += -Wno-unused-variable
EXTRA_CFLAGS += -Wno-unused-value
EXTRA_CFLAGS += -Wno-unused-label
EXTRA_CFLAGS += -Wno-unused-parameter
EXTRA_CFLAGS += -Wno-unused-function
EXTRA_CFLAGS += -Wno-unused
EXTRA_CFLAGS += -Wno-cast-function-type
#EXTRA_CFLAGS += -Wno-uninitialized
EXTRA_CFLAGS += -Wno-implicit-fallthrough

GCC_VER_49 := $(shell echo `$(CC) -dumpversion | cut -f1-2 -d.` \>= 4.9 | bc )
ifeq ($(GCC_VER_49),1)
EXTRA_CFLAGS += -Wno-date-time	# Fix compile error && warning on gcc 4.9 and later
endif

EXTRA_CFLAGS += -Wno-vla

EXTRA_CFLAGS += -I$(src)/include

EXTRA_LDFLAGS += --strip-debug

CONFIG_AUTOCFG_CP = n

CONFIG_RTL8710B = y

########################## WIFI IC ############################
CONFIG_MULTIDRV = n
CONFIG_RTL8188E = n
CONFIG_RTL8812A = n
CONFIG_RTL8821A = n
CONFIG_RTL8192E = n
CONFIG_RTL8723B = n
CONFIG_RTL8814A = n
CONFIG_RTL8723C = n
CONFIG_RTL8188F = n
CONFIG_RTL8822B = n
CONFIG_RTL8723D = n
CONFIG_RTL8821C = n
######################### Interface ###########################
CONFIG_USB_HCI = y
CONFIG_PCI_HCI = n
CONFIG_SDIO_HCI = n
CONFIG_GSPI_HCI = n
########################## Features ###########################
CONFIG_MP_INCLUDED = n
CONFIG_POWER_SAVING = n
CONFIG_USB_AUTOSUSPEND = n
CONFIG_HW_PWRP_DETECTION = n
CONFIG_WIFI_TEST = n
CONFIG_BT_COEXIST = n
CONFIG_INTEL_WIDI = n
CONFIG_WAPI_SUPPORT = n
CONFIG_EFUSE_CONFIG_FILE = y
CONFIG_EXT_CLK = n
CONFIG_TRAFFIC_PROTECT = n
CONFIG_LOAD_PHY_PARA_FROM_FILE = y
CONFIG_TXPWR_BY_RATE_EN = auto
CONFIG_TXPWR_LIMIT_EN = auto
CONFIG_CALIBRATE_TX_POWER_TO_MAX = y
CONFIG_RTW_CHPLAN = 0xFF
CONFIG_RTW_ADAPTIVITY_EN = disable
CONFIG_RTW_ADAPTIVITY_MODE = normal
CONFIG_SIGNAL_SCALE_MAPPING = n
CONFIG_80211W = n
CONFIG_REDUCE_TX_CPU_LOADING = y
CONFIG_BR_EXT = n
CONFIG_TDLS = n
CONFIG_WIFI_MONITOR = n
CONFIG_MCC_MODE = n
CONFIG_APPEND_VENDOR_IE_ENABLE = n
CONFIG_RTW_NAPI = y
CONFIG_RTW_GRO = y
CONFIG_RTW_IPCAM_APPLICATION = n
CONFIG_RTW_REPEATER_SON = n
CONFIG_RTW_WIFI_HAL = y
CONFIG_VHT_EXTRAS = y
CONFIG_LED_CONTROL = y
CONFIG_LED_ENABLE = y
########################## Debug ###########################
CONFIG_RTW_DEBUG = n
# default log level is _DRV_INFO_ = 4,
# please refer to "How_to_set_driver_debug_log_level.doc" to set the available level.
CONFIG_RTW_LOG_LEVEL = 4
######################## Wake On Lan ##########################
CONFIG_WOWLAN = n
CONFIG_WAKEUP_TYPE = 0x7 #bit2: deauth, bit1: unicast, bit0: magic pkt.
CONFIG_GPIO_WAKEUP = n
CONFIG_WAKEUP_GPIO_IDX = default
CONFIG_HIGH_ACTIVE = n
CONFIG_PNO_SUPPORT = n
CONFIG_PNO_SET_DEBUG = n
CONFIG_AP_WOWLAN = n
######### Notify SDIO Host Keep Power During Syspend ##########
CONFIG_RTW_SDIO_PM_KEEP_POWER = y
###################### MP HW TX MODE FOR VHT #######################
CONFIG_MP_VHT_HW_TX_MODE = n
###################### Platform Related #######################
CONFIG_PLATFORM_I386_PC = y
CONFIG_PLATFORM_ARM_RPI = n
CONFIG_PLATFORM_ANDROID_X86 = n
CONFIG_PLATFORM_ANDROID_INTEL_X86 = n
CONFIG_PLATFORM_JB_X86 = n
CONFIG_PLATFORM_ARM_S3C2K4 = n
CONFIG_PLATFORM_ARM_PXA2XX = n
CONFIG_PLATFORM_ARM_S3C6K4 = n
CONFIG_PLATFORM_MIPS_RMI = n
CONFIG_PLATFORM_RTD2880B = n
CONFIG_PLATFORM_MIPS_AR9132 = n
CONFIG_PLATFORM_RTK_DMP = n
CONFIG_PLATFORM_MIPS_PLM = n
CONFIG_PLATFORM_MSTAR389 = n
CONFIG_PLATFORM_MT53XX = n
CONFIG_PLATFORM_ARM_MX51_241H = n
CONFIG_PLATFORM_FS_MX61 = n
CONFIG_PLATFORM_ACTIONS_ATJ227X = n
CONFIG_PLATFORM_TEGRA3_CARDHU = n
CONFIG_PLATFORM_TEGRA4_DALMORE = n
CONFIG_PLATFORM_ARM_TCC8900 = n
CONFIG_PLATFORM_ARM_TCC8920 = n
CONFIG_PLATFORM_ARM_TCC8920_JB42 = n
CONFIG_PLATFORM_ARM_TCC8930_JB42 = n
CONFIG_PLATFORM_ARM_RK2818 = n
CONFIG_PLATFORM_ARM_RK3066 = n
CONFIG_PLATFORM_ARM_RK3188 = n
CONFIG_PLATFORM_ARM_URBETTER = n
CONFIG_PLATFORM_ARM_TI_PANDA = n
CONFIG_PLATFORM_MIPS_JZ4760 = n
CONFIG_PLATFORM_DMP_PHILIPS = n
CONFIG_PLATFORM_MSTAR_TITANIA12 = n
CONFIG_PLATFORM_MSTAR = n
CONFIG_PLATFORM_SZEBOOK = n
CONFIG_PLATFORM_ARM_SUNxI = n
CONFIG_PLATFORM_ARM_SUN6I = n
CONFIG_PLATFORM_ARM_SUN7I = n
CONFIG_PLATFORM_ARM_SUN8I_W3P1 = n
CONFIG_PLATFORM_ARM_SUN8I_W5P1 = n
CONFIG_PLATFORM_ACTIONS_ATM702X = n
CONFIG_PLATFORM_ACTIONS_ATV5201 = n
CONFIG_PLATFORM_ACTIONS_ATM705X = n
CONFIG_PLATFORM_ARM_SUN50IW1P1 = n
CONFIG_PLATFORM_ARM_RTD299X = n
CONFIG_PLATFORM_ARM_SPREADTRUM_6820 = n
CONFIG_PLATFORM_ARM_SPREADTRUM_8810 = n
CONFIG_PLATFORM_ARM_WMT = n
CONFIG_PLATFORM_TI_DM365 = n
CONFIG_PLATFORM_MOZART = n
CONFIG_PLATFORM_RTK119X = n
CONFIG_PLATFORM_RTK129X = n
CONFIG_PLATFORM_NOVATEK_NT72668 = n
CONFIG_PLATFORM_HISILICON = n
CONFIG_PLATFORM_NV_TK1 = n
CONFIG_PLATFORM_RTL8197D = n
###############################################################

CONFIG_DRVEXT_MODULE = n

export TopDIR ?= $(shell pwd)

########### COMMON  #################################
ifeq ($(CONFIG_GSPI_HCI), y)
HCI_NAME = gspi
endif

ifeq ($(CONFIG_SDIO_HCI), y)
HCI_NAME = sdio
endif

ifeq ($(CONFIG_USB_HCI), y)
HCI_NAME = usb
endif

ifeq ($(CONFIG_PCI_HCI), y)
HCI_NAME = pci
endif


_OS_INTFS_FILES :=	os_dep/osdep_service.o \
			os_dep/linux/os_intfs.o \
			os_dep/linux/$(HCI_NAME)_intf.o \
			os_dep/linux/$(HCI_NAME)_ops_linux.o \
			os_dep/linux/ioctl_linux.o \
			os_dep/linux/xmit_linux.o \
			os_dep/linux/mlme_linux.o \
			os_dep/linux/recv_linux.o \
			os_dep/linux/ioctl_cfg80211.o \
			os_dep/linux/rtw_cfgvendor.o \
			os_dep/linux/wifi_regd.o \
			os_dep/linux/rtw_android.o \
			os_dep/linux/rtw_proc.o

ifeq ($(CONFIG_MP_INCLUDED), y)
_OS_INTFS_FILES += os_dep/linux/ioctl_mp.o
endif

ifeq ($(CONFIG_SDIO_HCI), y)
_OS_INTFS_FILES += os_dep/linux/custom_gpio_linux.o
_OS_INTFS_FILES += os_dep/linux/$(HCI_NAME)_ops_linux.o
endif

ifeq ($(CONFIG_GSPI_HCI), y)
_OS_INTFS_FILES += os_dep/linux/custom_gpio_linux.o
_OS_INTFS_FILES += os_dep/linux/$(HCI_NAME)_ops_linux.o
endif


_HAL_INTFS_FILES :=	hal/hal_intf.o \
			hal/hal_com.o \
			hal/hal_com_phycfg.o \
			hal/hal_phy.o \
			hal/hal_dm.o \
			hal/hal_dm_acs.o \
			hal/hal_btcoex_wifionly.o \
			hal/hal_btcoex.o \
			hal/hal_mp.o \
			hal/hal_mcc.o \
			hal/hal_hci/hal_$(HCI_NAME).o \
			hal/led/hal_$(HCI_NAME)_led.o


EXTRA_CFLAGS += -I$(src)/platform
_PLATFORM_FILES := platform/platform_ops.o

EXTRA_CFLAGS += -I$(src)/hal/btc
_BTC_FILES += hal/btc/halbtc8723bwifionly.o \
				hal/btc/halbtc8822bwifionly.o \
				hal/btc/halbtc8821cwifionly.o
ifeq ($(CONFIG_BT_COEXIST), y)
_BTC_FILES += hal/btc/halbtc8192e1ant.o \
				hal/btc/halbtc8192e2ant.o \
				hal/btc/halbtc8723b1ant.o \
				hal/btc/halbtc8723b2ant.o \
				hal/btc/halbtc8812a1ant.o \
				hal/btc/halbtc8812a2ant.o \
				hal/btc/halbtc8821a1ant.o \
				hal/btc/halbtc8821a2ant.o \
				hal/btc/halbtc8703b1ant.o \
				hal/btc/halbtc8723d1ant.o \
				hal/btc/halbtc8723d2ant.o \
				hal/btc/halbtc8822b1ant.o \
				hal/btc/halbtc8822b2ant.o \
				hal/btc/halbtc8821c1ant.o \
				hal/btc/halbtc8821c2ant.o
endif

include $(TopDIR)/hal/phydm/phydm.mk

########### HAL_RTL8710B #################################
ifeq ($(CONFIG_RTL8710B), y)

RTL871X = rtl8710b
ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8188gu
MODULE_SUB_NAME = 8188gu
endif

EXTRA_CFLAGS += -DCONFIG_RTL8710B

_HAL_INTFS_FILES += hal/HalPwrSeqCmd.o \
                                        hal/$(RTL871X)/Hal8710BPwrSeq.o\
                                        hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=     hal/$(RTL871X)/$(RTL871X)_hal_init.o \
                        hal/$(RTL871X)/$(RTL871X)_phycfg.o \
                        hal/$(RTL871X)/$(RTL871X)_rf6052.o \
                        hal/$(RTL871X)/$(RTL871X)_dm.o \
                        hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
                        hal/$(RTL871X)/$(RTL871X)_cmd.o \
                        hal/$(RTL871X)/hal8710b_fw.o \
                        hal/$(RTL871X)/$(RTL871X)_lps_poff.o


_HAL_INTFS_FILES +=     \
                        hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
                        hal/$(RTL871X)/$(HCI_NAME)/rtl8710bu_led.o \
                        hal/$(RTL871X)/$(HCI_NAME)/rtl8710bu_xmit.o \
                        hal/$(RTL871X)/$(HCI_NAME)/rtl8710bu_recv.o

_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o

ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8710B_USB.o
endif

endif

########### HAL_RTL8188E #################################
ifeq ($(CONFIG_RTL8188E), y)

RTL871X = rtl8188e
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME = 8189es
endif

ifeq ($(CONFIG_GSPI_HCI), y)
MODULE_NAME = 8189es
endif

ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8188eu
endif

ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME = 8188ee
endif
EXTRA_CFLAGS += -DCONFIG_RTL8188E

_HAL_INTFS_FILES +=	hal/HalPwrSeqCmd.o \
					hal/$(RTL871X)/Hal8188EPwrSeq.o\
 					hal/$(RTL871X)/$(RTL871X)_xmit.o\
					hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=	hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o \
			hal/$(RTL871X)/hal8188e_s_fw.o \
			hal/$(RTL871X)/hal8188e_t_fw.o \
			hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_led.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_xmit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_recv.o

ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
else
ifeq ($(CONFIG_GSPI_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
else
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops_linux.o
endif
endif

ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8188E_USB.o
endif
ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8188E_PCIE.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8188E_SDIO.o
endif

endif

########### HAL_RTL8192E #################################
ifeq ($(CONFIG_RTL8192E), y)

RTL871X = rtl8192e
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME = 8192es
endif

ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8192eu
endif

ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME = 8192ee
endif
EXTRA_CFLAGS += -DCONFIG_RTL8192E
_HAL_INTFS_FILES += hal/HalPwrSeqCmd.o \
					hal/$(RTL871X)/Hal8192EPwrSeq.o\
					hal/$(RTL871X)/$(RTL871X)_xmit.o\
					hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=	hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o \
			hal/$(RTL871X)/hal8192e_fw.o \
			hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_led.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_xmit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_recv.o

ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
else
ifeq ($(CONFIG_GSPI_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
else
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops_linux.o
endif
endif

ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8192E_USB.o
endif
ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8192E_PCIE.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8192E_SDIO.o
endif

endif

########### HAL_RTL8812A_RTL8821A #################################

ifneq ($(CONFIG_RTL8812A)_$(CONFIG_RTL8821A), n_n)

RTL871X = rtl8812a
ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8812au
endif
ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME = 8812ae
endif
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME = 8812as
endif

_HAL_INTFS_FILES +=  hal/HalPwrSeqCmd.o \
					hal/$(RTL871X)/Hal8812PwrSeq.o \
					hal/$(RTL871X)/Hal8821APwrSeq.o\
					hal/$(RTL871X)/$(RTL871X)_xmit.o\
					hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=	hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o \
			hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_led.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_xmit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_recv.o

ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
else
ifeq ($(CONFIG_GSPI_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
else
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops_linux.o
endif
endif

ifeq ($(CONFIG_RTL8812A), y)
ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8812A_USB.o
endif
ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8812A_PCIE.o
endif
endif
ifeq ($(CONFIG_RTL8821A), y)
ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8821A_USB.o
endif
ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8821A_PCIE.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8821A_SDIO.o
endif
endif

ifeq ($(CONFIG_RTL8812A), y)
EXTRA_CFLAGS += -DCONFIG_RTL8812A
_HAL_INTFS_FILES +=	hal/rtl8812a/hal8812a_fw.o
endif

ifeq ($(CONFIG_RTL8821A), y)

ifeq ($(CONFIG_RTL8812A), n)

RTL871X = rtl8821a
ifeq ($(CONFIG_USB_HCI), y)
ifeq ($(CONFIG_BT_COEXIST), y)
MODULE_NAME := 8821au
else
MODULE_NAME := 8811au
endif
endif
ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME := 8821ae
endif
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME := 8821as
endif

endif

EXTRA_CFLAGS += -DCONFIG_RTL8821A

_HAL_INTFS_FILES +=	hal/rtl8812a/hal8821a_fw.o

endif

endif

########### HAL_RTL8723B #################################
ifeq ($(CONFIG_RTL8723B), y)

RTL871X = rtl8723b
ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8723bu
endif
ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME = 8723be
endif
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME = 8723bs
endif

EXTRA_CFLAGS += -DCONFIG_RTL8723B

_HAL_INTFS_FILES += hal/HalPwrSeqCmd.o \
					hal/$(RTL871X)/Hal8723BPwrSeq.o\
					hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=	hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o \
			hal/$(RTL871X)/hal8723b_fw.o

_HAL_INTFS_FILES +=	\
			hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_led.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_xmit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_recv.o

ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops_linux.o
else
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
endif

ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8723B_USB.o
endif
ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8723B_PCIE.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8723B_SDIO.o
endif

endif

########### HAL_RTL8814A #################################
ifeq ($(CONFIG_RTL8814A), y)
## ADD NEW VHT MP HW TX MODE ##
#EXTRA_CFLAGS += -DCONFIG_MP_VHT_HW_TX_MODE
#CONFIG_MP_VHT_HW_TX_MODE = y
##########################################
RTL871X = rtl8814a
ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8814au
endif
ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME = 8814ae
endif
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME = 8814as
endif

EXTRA_CFLAGS += -DCONFIG_RTL8814A

_HAL_INTFS_FILES +=  hal/HalPwrSeqCmd.o \
					hal/$(RTL871X)/Hal8814PwrSeq.o \
					hal/$(RTL871X)/$(RTL871X)_xmit.o\
					hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=	hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o \
			hal/$(RTL871X)/hal8814a_fw.o


_HAL_INTFS_FILES +=	\
			hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_led.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_xmit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_recv.o

ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
else
ifeq ($(CONFIG_GSPI_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
else
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops_linux.o
endif
endif

ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8814A_USB.o
endif
ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8814A_PCIE.o
endif

endif

########### HAL_RTL8723C #################################
ifeq ($(CONFIG_RTL8723C), y)

RTL871X = rtl8703b
ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8723cu
MODULE_SUB_NAME = 8703bu
endif
ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME = 8723ce
MODULE_SUB_NAME = 8703be
endif
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME = 8723cs
MODULE_SUB_NAME = 8703bs
endif

EXTRA_CFLAGS += -DCONFIG_RTL8703B

_HAL_INTFS_FILES += hal/HalPwrSeqCmd.o \
					hal/$(RTL871X)/Hal8703BPwrSeq.o\
					hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=	hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o \
			hal/$(RTL871X)/hal8703b_fw.o

_HAL_INTFS_FILES +=	\
			hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_SUB_NAME)_led.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_SUB_NAME)_xmit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_SUB_NAME)_recv.o

ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops_linux.o
else
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
endif

ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8703B_USB.o
endif
ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8703B_PCIE.o
endif

endif

########### HAL_RTL8723D #################################
ifeq ($(CONFIG_RTL8723D), y)

RTL871X = rtl8723d
ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8723du
MODULE_SUB_NAME = 8723du
endif
ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME = 8723de
MODULE_SUB_NAME = 8723de
endif
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME = 8723ds
MODULE_SUB_NAME = 8723ds
endif

EXTRA_CFLAGS += -DCONFIG_RTL8723D

_HAL_INTFS_FILES += hal/HalPwrSeqCmd.o \
					hal/$(RTL871X)/Hal8723DPwrSeq.o\
					hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=	hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o \
			hal/$(RTL871X)/hal8723d_fw.o \
			hal/$(RTL871X)/$(RTL871X)_lps_poff.o


_HAL_INTFS_FILES +=	\
			hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_SUB_NAME)_led.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_SUB_NAME)_xmit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_SUB_NAME)_recv.o

ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops_linux.o
else
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
endif

ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8723D_USB.o
endif
ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8723D_PCIE.o
endif

endif

########### HAL_RTL8188F #################################
ifeq ($(CONFIG_RTL8188F), y)

RTL871X = rtl8188f
ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME = 8188fu
endif
ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME = 8188fe
endif
ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME = 8189fs
endif

EXTRA_CFLAGS += -DCONFIG_RTL8188F

_HAL_INTFS_FILES += hal/HalPwrSeqCmd.o \
					hal/$(RTL871X)/Hal8188FPwrSeq.o\
					hal/$(RTL871X)/$(RTL871X)_sreset.o

_HAL_INTFS_FILES +=	hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o \
			hal/$(RTL871X)/hal8188f_fw.o

_HAL_INTFS_FILES +=	\
			hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_halinit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_led.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_xmit.o \
			hal/$(RTL871X)/$(HCI_NAME)/rtl$(MODULE_NAME)_recv.o

ifeq ($(CONFIG_PCI_HCI), y)
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops_linux.o
else
_HAL_INTFS_FILES += hal/$(RTL871X)/$(HCI_NAME)/$(HCI_NAME)_ops.o
endif

ifeq ($(CONFIG_USB_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8188F_USB.o
endif

ifeq ($(CONFIG_SDIO_HCI), y)
_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8188F_SDIO.o
endif

endif

########### HAL_RTL8822B #################################
ifeq ($(CONFIG_RTL8822B), y)
include $(TopDIR)/rtl8822b.mk
endif

########### HAL_RTL8821C #################################
ifeq ($(CONFIG_RTL8821C), y)
include $(TopDIR)/rtl8821c.mk
endif

########### AUTO_CFG  #################################

ifeq ($(CONFIG_AUTOCFG_CP), y)

ifeq ($(CONFIG_MULTIDRV), y)
$(shell cp $(TopDIR)/autoconf_multidrv_$(HCI_NAME)_linux.h $(TopDIR)/include/autoconf.h)
else
ifeq ($(CONFIG_RTL8188E)$(CONFIG_SDIO_HCI),yy)
$(shell cp $(TopDIR)/autoconf_rtl8189e_$(HCI_NAME)_linux.h $(TopDIR)/include/autoconf.h)
else ifeq ($(CONFIG_RTL8188F)$(CONFIG_SDIO_HCI),yy)
$(shell cp $(TopDIR)/autoconf_rtl8189f_$(HCI_NAME)_linux.h $(TopDIR)/include/autoconf.h)
else ifeq ($(CONFIG_RTL8723C),y)
$(shell cp $(TopDIR)/autoconf_rtl8723c_$(HCI_NAME)_linux.h $(TopDIR)/include/autoconf.h)
else
$(shell cp $(TopDIR)/autoconf_$(RTL871X)_$(HCI_NAME)_linux.h $(TopDIR)/include/autoconf.h)
endif
endif

endif

########### END OF PATH  #################################

ifeq ($(CONFIG_USB_HCI), y)
ifeq ($(CONFIG_USB_AUTOSUSPEND), y)
EXTRA_CFLAGS += -DCONFIG_USB_AUTOSUSPEND
endif
endif

ifeq ($(CONFIG_MP_INCLUDED), y)
#MODULE_NAME := $(MODULE_NAME)_mp
EXTRA_CFLAGS += -DCONFIG_MP_INCLUDED
endif

ifeq ($(CONFIG_POWER_SAVING), y)
EXTRA_CFLAGS += -DCONFIG_POWER_SAVING
endif

ifeq ($(CONFIG_HW_PWRP_DETECTION), y)
EXTRA_CFLAGS += -DCONFIG_HW_PWRP_DETECTION
endif

ifeq ($(CONFIG_WIFI_TEST), y)
EXTRA_CFLAGS += -DCONFIG_WIFI_TEST
endif

ifeq ($(CONFIG_BT_COEXIST), y)
EXTRA_CFLAGS += -DCONFIG_BT_COEXIST
endif

ifeq ($(CONFIG_INTEL_WIDI), y)
EXTRA_CFLAGS += -DCONFIG_INTEL_WIDI
endif

ifeq ($(CONFIG_WAPI_SUPPORT), y)
EXTRA_CFLAGS += -DCONFIG_WAPI_SUPPORT
endif


ifeq ($(CONFIG_EFUSE_CONFIG_FILE), y)
EXTRA_CFLAGS += -DCONFIG_EFUSE_CONFIG_FILE

#EFUSE_MAP_PATH
USER_EFUSE_MAP_PATH ?=
ifneq ($(USER_EFUSE_MAP_PATH),)
EXTRA_CFLAGS += -DEFUSE_MAP_PATH=\"$(USER_EFUSE_MAP_PATH)\"
else ifeq ($(MODULE_NAME), 8189es)
EXTRA_CFLAGS += -DEFUSE_MAP_PATH=\"/system/etc/wifi/wifi_efuse_8189e.map\"
else ifeq ($(MODULE_NAME), 8723bs)
EXTRA_CFLAGS += -DEFUSE_MAP_PATH=\"/system/etc/wifi/wifi_efuse_8723bs.map\"
else
EXTRA_CFLAGS += -DEFUSE_MAP_PATH=\"/system/etc/wifi/wifi_efuse_$(MODULE_NAME).map\"
endif

#WIFIMAC_PATH
USER_WIFIMAC_PATH ?=
ifneq ($(USER_WIFIMAC_PATH),)
EXTRA_CFLAGS += -DWIFIMAC_PATH=\"$(USER_WIFIMAC_PATH)\"
else
EXTRA_CFLAGS += -DWIFIMAC_PATH=\"/data/wifimac.txt\"
endif

endif

ifeq ($(CONFIG_EXT_CLK), y)
EXTRA_CFLAGS += -DCONFIG_EXT_CLK
endif

ifeq ($(CONFIG_TRAFFIC_PROTECT), y)
EXTRA_CFLAGS += -DCONFIG_TRAFFIC_PROTECT
endif

ifeq ($(CONFIG_LOAD_PHY_PARA_FROM_FILE), y)
EXTRA_CFLAGS += -DCONFIG_LOAD_PHY_PARA_FROM_FILE
#EXTRA_CFLAGS += -DREALTEK_CONFIG_PATH_WITH_IC_NAME_FOLDER
EXTRA_CFLAGS += -DREALTEK_CONFIG_PATH=\"/lib/firmware/\"
endif

ifeq ($(CONFIG_TXPWR_BY_RATE_EN), n)
EXTRA_CFLAGS += -DCONFIG_TXPWR_BY_RATE_EN=0
else ifeq ($(CONFIG_TXPWR_BY_RATE_EN), y)
EXTRA_CFLAGS += -DCONFIG_TXPWR_BY_RATE_EN=1
else ifeq ($(CONFIG_TXPWR_BY_RATE_EN), auto)
EXTRA_CFLAGS += -DCONFIG_TXPWR_BY_RATE_EN=2
endif

ifeq ($(CONFIG_TXPWR_LIMIT_EN), n)
EXTRA_CFLAGS += -DCONFIG_TXPWR_LIMIT_EN=0
else ifeq ($(CONFIG_TXPWR_LIMIT_EN), y)
EXTRA_CFLAGS += -DCONFIG_TXPWR_LIMIT_EN=1
else ifeq ($(CONFIG_TXPWR_LIMIT_EN), auto)
EXTRA_CFLAGS += -DCONFIG_TXPWR_LIMIT_EN=2
endif

ifneq ($(CONFIG_RTW_CHPLAN), 0xFF)
EXTRA_CFLAGS += -DCONFIG_RTW_CHPLAN=$(CONFIG_RTW_CHPLAN)
endif

ifeq ($(CONFIG_CALIBRATE_TX_POWER_BY_REGULATORY), y)
EXTRA_CFLAGS += -DCONFIG_CALIBRATE_TX_POWER_BY_REGULATORY
endif

ifeq ($(CONFIG_CALIBRATE_TX_POWER_TO_MAX), y)
EXTRA_CFLAGS += -DCONFIG_CALIBRATE_TX_POWER_TO_MAX
endif

ifeq ($(CONFIG_RTW_ADAPTIVITY_EN), disable)
EXTRA_CFLAGS += -DCONFIG_RTW_ADAPTIVITY_EN=0
else ifeq ($(CONFIG_RTW_ADAPTIVITY_EN), enable)
EXTRA_CFLAGS += -DCONFIG_RTW_ADAPTIVITY_EN=1
endif

ifeq ($(CONFIG_RTW_ADAPTIVITY_MODE), normal)
EXTRA_CFLAGS += -DCONFIG_RTW_ADAPTIVITY_MODE=0
else ifeq ($(CONFIG_RTW_ADAPTIVITY_MODE), carrier_sense)
EXTRA_CFLAGS += -DCONFIG_RTW_ADAPTIVITY_MODE=1
endif

ifeq ($(CONFIG_SIGNAL_SCALE_MAPPING), y)
EXTRA_CFLAGS += -DCONFIG_SIGNAL_SCALE_MAPPING
endif

ifeq ($(CONFIG_80211W), y)
EXTRA_CFLAGS += -DCONFIG_IEEE80211W
endif

ifeq ($(CONFIG_WOWLAN), y)
EXTRA_CFLAGS += -DCONFIG_WOWLAN -DRTW_WAKEUP_EVENT=$(CONFIG_WAKEUP_TYPE)
ifeq ($(CONFIG_SDIO_HCI), y)
EXTRA_CFLAGS += -DCONFIG_RTW_SDIO_PM_KEEP_POWER
endif
endif

ifeq ($(CONFIG_AP_WOWLAN), y)
EXTRA_CFLAGS += -DCONFIG_AP_WOWLAN
ifeq ($(CONFIG_SDIO_HCI), y)
EXTRA_CFLAGS += -DCONFIG_RTW_SDIO_PM_KEEP_POWER
endif
endif

ifeq ($(CONFIG_PNO_SUPPORT), y)
EXTRA_CFLAGS += -DCONFIG_PNO_SUPPORT
ifeq ($(CONFIG_PNO_SET_DEBUG), y)
EXTRA_CFLAGS += -DCONFIG_PNO_SET_DEBUG
endif
endif

ifeq ($(CONFIG_GPIO_WAKEUP), y)
EXTRA_CFLAGS += -DCONFIG_GPIO_WAKEUP
ifeq ($(CONFIG_HIGH_ACTIVE), y)
EXTRA_CFLAGS += -DHIGH_ACTIVE=1
else
EXTRA_CFLAGS += -DHIGH_ACTIVE=0
endif
endif

ifneq ($(CONFIG_WAKEUP_GPIO_IDX), default)
EXTRA_CFLAGS += -DWAKEUP_GPIO_IDX=$(CONFIG_WAKEUP_GPIO_IDX)
endif

ifeq ($(CONFIG_RTW_SDIO_PM_KEEP_POWER), y)
ifeq ($(CONFIG_SDIO_HCI), y)
EXTRA_CFLAGS += -DCONFIG_RTW_SDIO_PM_KEEP_POWER
endif
endif

ifeq ($(CONFIG_REDUCE_TX_CPU_LOADING), y)
EXTRA_CFLAGS += -DCONFIG_REDUCE_TX_CPU_LOADING
endif

ifeq ($(CONFIG_BR_EXT), y)
BR_NAME = br0
EXTRA_CFLAGS += -DCONFIG_BR_EXT
EXTRA_CFLAGS += '-DCONFIG_BR_EXT_BRNAME="'$(BR_NAME)'"'
endif


ifeq ($(CONFIG_TDLS), y)
EXTRA_CFLAGS += -DCONFIG_TDLS
endif

ifeq ($(CONFIG_WIFI_MONITOR), y)
EXTRA_CFLAGS += -DCONFIG_WIFI_MONITOR
endif

ifeq ($(CONFIG_MCC_MODE), y)
EXTRA_CFLAGS += -DCONFIG_MCC_MODE
endif

ifeq ($(CONFIG_RTW_NAPI), y)
EXTRA_CFLAGS += -DCONFIG_RTW_NAPI
endif

ifeq ($(CONFIG_RTW_GRO), y)
EXTRA_CFLAGS += -DCONFIG_RTW_GRO
endif

ifeq ($(CONFIG_RTW_REPEATER_SON), y)
EXTRA_CFLAGS += -DCONFIG_RTW_REPEATER_SON
endif

ifeq ($(CONFIG_RTW_IPCAM_APPLICATION), y)
EXTRA_CFLAGS += -DCONFIG_RTW_IPCAM_APPLICATION
ifeq ($(CONFIG_WIFI_MONITOR), n)
EXTRA_CFLAGS += -DCONFIG_WIFI_MONITOR
endif
endif

ifeq ($(CONFIG_RTW_WIFI_HAL), y)
#EXTRA_CFLAGS += -DCONFIG_RTW_WIFI_HAL_DEBUG
EXTRA_CFLAGS += -DCONFIG_RTW_WIFI_HAL
EXTRA_CFLAGS += -DCONFIG_RTW_CFGVEDNOR_LLSTATS
endif

ifeq ($(CONFIG_VHT_EXTRAS), y)
EXTRA_CFLAGS += -DCONFIG_VHT_EXTRAS
endif

ifeq ($(CONFIG_LED_CONTROL), y)
EXTRA_CFLAGS += -DCONFIG_LED_CONTROL
ifeq ($(CONFIG_LED_ENABLE), y)
EXTRA_CFLAGS += -DCONFIG_LED_ENABLE
endif
endif

ifeq ($(CONFIG_MP_VHT_HW_TX_MODE), y)
EXTRA_CFLAGS += -DCONFIG_MP_VHT_HW_TX_MODE
ifeq ($(CONFIG_PLATFORM_I386_PC), y)
## For I386 X86 ToolChain use Hardware FLOATING
EXTRA_CFLAGS += -mhard-float
else
## For ARM ToolChain use Hardware FLOATING
EXTRA_CFLAGS += -mfloat-abi=hard
endif
endif

ifeq ($(CONFIG_APPEND_VENDOR_IE_ENABLE), y)
EXTRA_CFLAGS += -DCONFIG_APPEND_VENDOR_IE_ENABLE
endif

ifeq ($(CONFIG_RTW_DEBUG), y)
EXTRA_CFLAGS += -DCONFIG_RTW_DEBUG
EXTRA_CFLAGS += -DRTW_LOG_LEVEL=$(CONFIG_RTW_LOG_LEVEL)
endif

EXTRA_CFLAGS += -DDM_ODM_SUPPORT_TYPE=0x04

ifeq ($(CONFIG_PLATFORM_I386_PC), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
SUBARCH := $(shell uname -m | sed -e s/i.86/i386/)
ARCH ?= $(SUBARCH)
CROSS_COMPILE ?=
KVER ?= $(shell uname -r)
KSRC ?= /lib/modules/$(KVER)/build
MODDESTDIR := /lib/modules/$(KVER)/kernel/drivers/net/wireless/
INSTALL_PREFIX :=
STAGINGMODDIR := /lib/modules/$(KVER)/kernel/drivers/staging
endif

ifeq ($(CONFIG_PLATFORM_ARM_RPI), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
ARCH ?= arm
CROSS_COMPILE ?=
KVER ?= $(shell uname -r)
KSRC ?= /lib/modules/$(KVER)/build
MODDESTDIR := /lib/modules/$(KVER)/kernel/drivers/net/wireless/
INSTALL_PREFIX :=
endif

ifeq ($(CONFIG_PLATFORM_NV_TK1), y)
EXTRA_CFLAGS += -DCONFIG_PLATFORM_NV_TK1
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_P2P_IPS -DCONFIG_PLATFORM_ANDROID
# Enable this for Android 5.0
EXTRA_CFLAGS += -DCONFIG_RADIO_WORK
EXTRA_CFLAGS += -DRTW_VENDOR_EXT_SUPPORT
EXTRA_CFLAGS += -DRTW_ENABLE_WIFI_CONTROL_FUNC
ARCH ?= arm
# for ubuntu environment
#CROSS_COMPILE ?=
#KVER := $(shell uname -r)
#KSRC := /lib/modules/$(KVER)/build
#MODDESTDIR := /lib/modules/$(KVER)/kernel/drivers/net/wireless/
#INSTALL_PREFIX :=
CROSS_COMPILE := /mnt/newdisk/android_sdk/nvidia_tk1/android_L/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
KSRC :=/mnt/newdisk/android_sdk/nvidia_tk1/android_L/out/target/product/shieldtablet/obj/KERNEL/
MODULE_NAME = wlan
endif

ifeq ($(CONFIG_PLATFORM_ACTIONS_ATM702X), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_ANDROID -DCONFIG_PLATFORM_ACTIONS_ATM702X
#ARCH := arm
ARCH := $(R_ARCH)
#CROSS_COMPILE := arm-none-linux-gnueabi-
CROSS_COMPILE := $(R_CROSS_COMPILE)
KVER:= 3.4.0
#KSRC := ../../../../build/out/kernel
KSRC := $(KERNEL_BUILD_PATH)
MODULE_NAME :=wlan
endif


ifeq ($(CONFIG_PLATFORM_ACTIONS_ATM705X), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
#EXTRA_CFLAGS += -DRTW_ENABLE_WIFI_CONTROL_FUNC
# default setting for Android 4.1, 4.2, 4.3, 4.4
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ACTIONS_ATM705X
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT

# Enable this for Android 5.0
EXTRA_CFLAGS += -DCONFIG_RADIO_WORK

ifeq ($(CONFIG_SDIO_HCI), y)
EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
_PLATFORM_FILES += platform/platform_arm_act_sdio.o
endif

ARCH := arm
CROSS_COMPILE := /opt/arm-2011.09/bin/arm-none-linux-gnueabi-
KSRC := /home/android_sdk/Action-semi/705a_android_L/android/kernel
endif

ifeq ($(CONFIG_PLATFORM_ARM_SUN50IW1P1), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUN50IW1P1
EXTRA_CFLAGS += -DCONFIG_TRAFFIC_PROTECT
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS += -DCONFIG_RESUME_IN_WORKQUEUE
EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS

# Enable this for Android 5.0
EXTRA_CFLAGS += -DCONFIG_RADIO_WORK

ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
_PLATFORM_FILES += platform/platform_ARM_SUNxI_usb.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_PLATFORM_FILES += platform/platform_ARM_SUN50IW1P1_sdio.o
endif

ARCH := arm64
# ===Cross compile setting for Android 5.1(64) SDK ===
CROSS_COMPILE := /home/android_sdk/Allwinner/a64/android-51/lichee/out/sun50iw1p1/android/common/buildroot/external-toolchain/bin/aarch64-linux-gnu-
KSRC :=/home/android_sdk/Allwinner/a64/android-51/lichee/linux-3.10/
endif

ifeq ($(CONFIG_PLATFORM_TI_AM3517), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_ANDROID -DCONFIG_PLATFORM_SHUTTLE
CROSS_COMPILE := arm-eabi-
KSRC := $(shell pwd)/../../../Android/kernel
ARCH := arm
endif

ifeq ($(CONFIG_PLATFORM_MSTAR_TITANIA12), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_MSTAR -DCONFIG_PLATFORM_MSTAR_TITANIA12
ARCH:=mips
CROSS_COMPILE:= /usr/src/Mstar_kernel/mips-4.3/bin/mips-linux-gnu-
KVER:= 2.6.28.9
KSRC:= /usr/src/Mstar_kernel/2.6.28.9/
endif

ifeq ($(CONFIG_PLATFORM_MSTAR), y)
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_PLATFORM_MSTAR
EXTRA_CFLAGS += -DCONFIG_PLATFORM_MSTAR_HIGH
ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX -DCONFIG_FIX_NR_BULKIN_BUFFER
endif
ARCH:=arm
CROSS_COMPILE:= /usr/src/bin/arm-none-linux-gnueabi-
KVER:= 3.1.10
KSRC:= /usr/src/Mstar_kernel/3.1.10/
endif

ifeq ($(CONFIG_PLATFORM_ANDROID_X86), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
SUBARCH := $(shell uname -m | sed -e s/i.86/i386/)
ARCH := $(SUBARCH)
CROSS_COMPILE := /media/DATA-2/android-x86/ics-x86_20120130/prebuilt/linux-x86/toolchain/i686-unknown-linux-gnu-4.2.1/bin/i686-unknown-linux-gnu-
KSRC := /media/DATA-2/android-x86/ics-x86_20120130/out/target/product/generic_x86/obj/kernel
MODULE_NAME :=wlan
endif

ifeq ($(CONFIG_PLATFORM_ANDROID_INTEL_X86), y)
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ANDROID_INTEL_X86
EXTRA_CFLAGS += -DCONFIG_PLATFORM_INTEL_BYT
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_ANDROID
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS += -DCONFIG_SKIP_SIGNAL_SCALE_MAPPING
ifeq ($(CONFIG_SDIO_HCI), y)
EXTRA_CFLAGS += -DCONFIG_RESUME_IN_WORKQUEUE
endif
endif

ifeq ($(CONFIG_PLATFORM_JB_X86), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
SUBARCH := $(shell uname -m | sed -e s/i.86/i386/)
ARCH := $(SUBARCH)
CROSS_COMPILE := /home/android_sdk/android-x86_JB/prebuilts/gcc/linux-x86/x86/i686-linux-android-4.7/bin/i686-linux-android-
KSRC := /home/android_sdk/android-x86_JB/out/target/product/x86/obj/kernel/
MODULE_NAME :=wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_PXA2XX), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ARCH := arm
CROSS_COMPILE := arm-none-linux-gnueabi-
KVER  := 2.6.34.1
KSRC ?= /usr/src/linux-2.6.34.1
endif

ifeq ($(CONFIG_PLATFORM_ARM_S3C2K4), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ARCH := arm
CROSS_COMPILE := arm-linux-
KVER  := 2.6.24.7_$(ARCH)
KSRC := /usr/src/kernels/linux-$(KVER)
endif

ifeq ($(CONFIG_PLATFORM_ARM_S3C6K4), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ARCH := arm
CROSS_COMPILE := arm-none-linux-gnueabi-
KVER  := 2.6.34.1
KSRC ?= /usr/src/linux-2.6.34.1
endif

ifeq ($(CONFIG_PLATFORM_RTD2880B), y)
EXTRA_CFLAGS += -DCONFIG_BIG_ENDIAN -DCONFIG_PLATFORM_RTD2880B
ARCH:=
CROSS_COMPILE:=
KVER:=
KSRC:=
endif

ifeq ($(CONFIG_PLATFORM_MIPS_RMI), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ARCH:=mips
CROSS_COMPILE:=mipsisa32r2-uclibc-
KVER:=
KSRC:= /root/work/kernel_realtek
endif

ifeq ($(CONFIG_PLATFORM_MIPS_PLM), y)
EXTRA_CFLAGS += -DCONFIG_BIG_ENDIAN
ARCH:=mips
CROSS_COMPILE:=mipsisa32r2-uclibc-
KVER:=
KSRC:= /root/work/kernel_realtek
endif

ifeq ($(CONFIG_PLATFORM_MSTAR389), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_MSTAR389
ARCH:=mips
CROSS_COMPILE:= mips-linux-gnu-
KVER:= 2.6.28.10
KSRC:= /home/mstar/mstar_linux/2.6.28.9/
endif

ifeq ($(CONFIG_PLATFORM_MIPS_AR9132), y)
EXTRA_CFLAGS += -DCONFIG_BIG_ENDIAN
ARCH := mips
CROSS_COMPILE := mips-openwrt-linux-
KSRC := /home/alex/test_openwrt/tmp/linux-2.6.30.9
endif

ifeq ($(CONFIG_PLATFORM_DMP_PHILIPS), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DRTK_DMP_PLATFORM
ARCH := mips
#CROSS_COMPILE:=/usr/local/msdk-4.3.6-mips-EL-2.6.12.6-0.9.30.3/bin/mipsel-linux-
CROSS_COMPILE:=/usr/local/toolchain_mipsel/bin/mipsel-linux-
KSRC ?=/usr/local/Jupiter/linux-2.6.12
endif

ifeq ($(CONFIG_PLATFORM_RTK_DMP), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DRTK_DMP_PLATFORM  -DCONFIG_WIRELESS_EXT
EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
ifeq ($(CONFIG_USB_HCI), y)
_PLATFORM_FILES += platform/platform_RTK_DMP_usb.o
endif
ARCH:=mips
CROSS_COMPILE:=mipsel-linux-
KVER:=
KSRC ?= /usr/src/DMP_Kernel/jupiter/linux-2.6.12
endif

ifeq ($(CONFIG_PLATFORM_MT53XX), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_MT53XX
ARCH:= arm
CROSS_COMPILE:= arm11_mtk_le-
KVER:= 2.6.27
KSRC?= /proj/mtk00802/BD_Compare/BDP/Dev/BDP_V301/BDP_Linux/linux-2.6.27
endif

ifeq ($(CONFIG_PLATFORM_ARM_MX51_241H), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_WISTRON_PLATFORM
ARCH := arm
CROSS_COMPILE := /opt/freescale/usr/local/gcc-4.1.2-glibc-2.5-nptl-3/arm-none-linux-gnueabi/bin/arm-none-linux-gnueabi-
KVER  := 2.6.31
KSRC ?= /lib/modules/2.6.31-770-g0e46b52/source
endif

ifeq ($(CONFIG_PLATFORM_FS_MX61), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ARCH := arm
CROSS_COMPILE := /home/share/CusEnv/FreeScale/arm-eabi-4.4.3/bin/arm-eabi-
KSRC ?= /home/share/CusEnv/FreeScale/FS_kernel_env
endif



ifeq ($(CONFIG_PLATFORM_ACTIONS_ATJ227X), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_ACTIONS_ATJ227X
ARCH := mips
CROSS_COMPILE := /home/cnsd4/project/actions/tools-2.6.27/bin/mipsel-linux-gnu-
KVER  := 2.6.27
KSRC := /home/cnsd4/project/actions/linux-2.6.27.28
endif

ifeq ($(CONFIG_PLATFORM_TI_DM365), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_TI_DM365
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_RX
EXTRA_CFLAGS += -DCONFIG_SINGLE_XMIT_BUF -DCONFIG_SINGLE_RECV_BUF
ARCH := arm
#CROSS_COMPILE := /home/cnsd4/Appro/mv_pro_5.0/montavista/pro/devkit/arm/v5t_le/bin/arm_v5t_le-
#KSRC := /home/cnsd4/Appro/mv_pro_5.0/montavista/pro/devkit/lsp/ti-davinci/linux-dm365
CROSS_COMPILE := /opt/montavista/pro5.0/devkit/arm/v5t_le/bin/arm-linux-
KSRC:= /home/vivotek/lsp/DM365/kernel_platform/kernel/linux-2.6.18
KERNELOUTPUT := ${PRODUCTDIR}/tmp
KVER  := 2.6.18
endif

ifeq ($(CONFIG_PLATFORM_MOZART), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_MOZART
ARCH := arm
CROSS_COMPILE := /home/vivotek/lsp/mozart3v2/Mozart3e_Toolchain/build_arm_nofpu/usr/bin/arm-linux-
KVER  := $(shell uname -r)
KSRC:= /opt/Vivotek/lsp/mozart3v2/kernel_platform/kernel/mozart_kernel-1.17
KERNELOUTPUT := /home/pink/sample/ODM/IP8136W-VINT/tmp/kernel
endif

ifeq ($(CONFIG_PLATFORM_TEGRA3_CARDHU), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DRTW_ENABLE_WIFI_CONTROL_FUNC
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
ARCH := arm
CROSS_COMPILE := /home/android_sdk/nvidia/tegra-16r3-partner-android-4.1_20120723/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
KSRC := /home/android_sdk/nvidia/tegra-16r3-partner-android-4.1_20120723/out/target/product/cardhu/obj/KERNEL
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_TEGRA4_DALMORE), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DRTW_ENABLE_WIFI_CONTROL_FUNC
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
ARCH := arm
CROSS_COMPILE := /home/android_sdk/nvidia/tegra-17r9-partner-android-4.2-dalmore_20130131/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-
KSRC := /home/android_sdk/nvidia/tegra-17r9-partner-android-4.2-dalmore_20130131/out/target/product/dalmore/obj/KERNEL
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_TCC8900), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ARCH := arm
CROSS_COMPILE := /home/android_sdk/Telechips/SDK_2304_20110613/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
KSRC := /home/android_sdk/Telechips/SDK_2304_20110613/kernel
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_TCC8920), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ARCH := arm
CROSS_COMPILE := /home/android_sdk/Telechips/v12.06_r1-tcc-android-4.0.4/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
KSRC := /home/android_sdk/Telechips/v12.06_r1-tcc-android-4.0.4/kernel
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_TCC8920_JB42), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
ARCH := arm
CROSS_COMPILE := /home/android_sdk/Telechips/v13.03_r1-tcc-android-4.2.2_ds_patched/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-
KSRC := /home/android_sdk/Telechips/v13.03_r1-tcc-android-4.2.2_ds_patched/kernel
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_RK2818), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_ANDROID -DCONFIG_PLATFORM_ROCKCHIPS
ARCH := arm
CROSS_COMPILE := /usr/src/release_fae_version/toolchain/arm-eabi-4.4.0/bin/arm-eabi-
KSRC := /usr/src/release_fae_version/kernel25_A7_281x
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_RK3188), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_ANDROID -DCONFIG_PLATFORM_ROCKCHIPS
# default setting for Android 4.1, 4.2, 4.3, 4.4
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
# default setting for Power control
EXTRA_CFLAGS += -DRTW_ENABLE_WIFI_CONTROL_FUNC
EXTRA_CFLAGS += -DRTW_SUPPORT_PLATFORM_SHUTDOWN
# default setting for Special function
ARCH := arm
CROSS_COMPILE := /home/android_sdk/Rockchip/Rk3188/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-
KSRC := /home/android_sdk/Rockchip/Rk3188/kernel
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_RK3066), y)
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_RK3066
EXTRA_CFLAGS += -DRTW_ENABLE_WIFI_CONTROL_FUNC
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211
ifeq ($(CONFIG_SDIO_HCI), y)
EXTRA_CFLAGS += -DRTW_SUPPORT_PLATFORM_SHUTDOWN
endif
EXTRA_CFLAGS += -fno-pic
ARCH := arm
CROSS_COMPILE := /home/android_sdk/Rockchip/rk3066_20130607/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-
#CROSS_COMPILE := /home/android_sdk/Rockchip/Rk3066sdk/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-
KSRC := /home/android_sdk/Rockchip/Rk3066sdk/kernel
MODULE_NAME :=wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_URBETTER), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN #-DCONFIG_MINIMAL_MEMORY_USAGE
ARCH := arm
CROSS_COMPILE := /media/DATA-1/urbetter/arm-2009q3/bin/arm-none-linux-gnueabi-
KSRC := /media/DATA-1/urbetter/ics-urbetter/kernel
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_ARM_TI_PANDA), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN #-DCONFIG_MINIMAL_MEMORY_USAGE
ARCH := arm
#CROSS_COMPILE := /media/DATA-1/aosp/ics-aosp_20111227/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
#KSRC := /media/DATA-1/aosp/android-omap-panda-3.0_20120104
CROSS_COMPILE := /media/DATA-1/android-4.0/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
KSRC := /media/DATA-1/android-4.0/panda_kernel/omap
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_MIPS_JZ4760), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_MINIMAL_MEMORY_USAGE
ARCH ?= mips
CROSS_COMPILE ?= /mnt/sdb5/Ingenic/Umido/mips-4.3/bin/mips-linux-gnu-
KSRC ?= /mnt/sdb5/Ingenic/Umido/kernel
endif

ifeq ($(CONFIG_PLATFORM_SZEBOOK), y)
EXTRA_CFLAGS += -DCONFIG_BIG_ENDIAN
ARCH:=arm
CROSS_COMPILE:=/opt/crosstool2/bin/armeb-unknown-linux-gnueabi-
KVER:= 2.6.31.6
KSRC:= ../code/linux-2.6.31.6-2020/
endif

ifeq ($(CONFIG_PLATFORM_ARM_SUNxI), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUNxI
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT

EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
_PLATFORM_FILES += platform/platform_ARM_SUNxI_usb.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
# default setting for A10-EVB mmc0
#EXTRA_CFLAGS += -DCONFIG_WITS_EVB_V13
_PLATFORM_FILES += platform/platform_ARM_SUNxI_sdio.o
endif

ARCH := arm
#CROSS_COMPILE := arm-none-linux-gnueabi-
CROSS_COMPILE=/home/android_sdk/Allwinner/a10/android-jb42/lichee-jb42/buildroot/output/external-toolchain/bin/arm-none-linux-gnueabi-
KVER  := 3.0.8
#KSRC:= ../lichee/linux-3.0/
KSRC=/home/android_sdk/Allwinner/a10/android-jb42/lichee-jb42/linux-3.0
endif

ifeq ($(CONFIG_PLATFORM_ARM_SUN6I), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUN6I
EXTRA_CFLAGS += -DCONFIG_TRAFFIC_PROTECT
# default setting for Android 4.1, 4.2, 4.3, 4.4
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS +=  -DCONFIG_QOS_OPTIMIZATION

EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
_PLATFORM_FILES += platform/platform_ARM_SUNxI_usb.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
# default setting for A31-EVB mmc0
EXTRA_CFLAGS += -DCONFIG_A31_EVB
_PLATFORM_FILES += platform/platform_ARM_SUNnI_sdio.o
endif

ARCH := arm
#Android-JB42
#CROSS_COMPILE := /home/android_sdk/Allwinner/a31/android-jb42/lichee/buildroot/output/external-toolchain/bin/arm-linux-gnueabi-
#KSRC :=/home/android_sdk/Allwinner/a31/android-jb42/lichee/linux-3.3
#ifeq ($(CONFIG_USB_HCI), y)
#MODULE_NAME := 8188eu_sw
#endif
# ==== Cross compile setting for kitkat-a3x_v4.5 =====
CROSS_COMPILE := /home/android_sdk/Allwinner/a31/kitkat-a3x_v4.5/lichee/buildroot/output/external-toolchain/bin/arm-linux-gnueabi-
KSRC :=/home/android_sdk/Allwinner/a31/kitkat-a3x_v4.5/lichee/linux-3.3
endif

ifeq ($(CONFIG_PLATFORM_ARM_SUN7I), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUN7I
EXTRA_CFLAGS += -DCONFIG_TRAFFIC_PROTECT
# default setting for Android 4.1, 4.2, 4.3, 4.4
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS +=  -DCONFIG_QOS_OPTIMIZATION

EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
_PLATFORM_FILES += platform/platform_ARM_SUNxI_usb.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_PLATFORM_FILES += platform/platform_ARM_SUNnI_sdio.o
endif

ARCH := arm
# ===Cross compile setting for Android 4.2 SDK ===
#CROSS_COMPILE := /home/android_sdk/Allwinner/a20_evb/lichee/out/android/common/buildroot/external-toolchain/bin/arm-linux-gnueabi-
#KSRC := /home/android_sdk/Allwinner/a20_evb/lichee/linux-3.3
# ==== Cross compile setting for Android 4.3 SDK =====
#CROSS_COMPILE := /home/android_sdk/Allwinner/a20/android-jb43/lichee/out/android/common/buildroot/external-toolchain/bin/arm-linux-gnueabi-
#KSRC := /home/android_sdk/Allwinner/a20/android-jb43/lichee/linux-3.4
# ==== Cross compile setting for kitkat-a20_v4.4 =====
CROSS_COMPILE := /home/android_sdk/Allwinner/a20/kitkat-a20_v4.4/lichee/out/android/common/buildroot/external-toolchain/bin/arm-linux-gnueabi-
KSRC := /home/android_sdk/Allwinner/a20/kitkat-a20_v4.4/lichee/linux-3.4
endif

ifeq ($(CONFIG_PLATFORM_ARM_SUN8I_W3P1), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUN8I
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUN8I_W3P1
EXTRA_CFLAGS += -DCONFIG_TRAFFIC_PROTECT
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT

EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
_PLATFORM_FILES += platform/platform_ARM_SUNxI_usb.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_PLATFORM_FILES += platform/platform_ARM_SUNnI_sdio.o
endif

ARCH := arm
# ===Cross compile setting for Android 4.2 SDK ===
#CROSS_COMPILE := /home/android_sdk/Allwinner/a23/android-jb42/lichee/out/android/common/buildroot/external-toolchain/bin/arm-linux-gnueabi-
#KSRC :=/home/android_sdk/Allwinner/a23/android-jb42/lichee/linux-3.4
# ===Cross compile setting for Android 4.4 SDK ===
CROSS_COMPILE := /home/android_sdk/Allwinner/a23/android-kk44/lichee/out/android/common/buildroot/external-toolchain/bin/arm-linux-gnueabi-
KSRC :=/home/android_sdk/Allwinner/a23/android-kk44/lichee/linux-3.4
endif

ifeq ($(CONFIG_PLATFORM_ARM_SUN8I_W5P1), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUN8I
EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUN8I_W5P1
EXTRA_CFLAGS += -DCONFIG_TRAFFIC_PROTECT
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT

# Enable this for Android 5.0
EXTRA_CFLAGS += -DCONFIG_RADIO_WORK

EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
_PLATFORM_FILES += platform/platform_ARM_SUNxI_usb.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_PLATFORM_FILES += platform/platform_ARM_SUNnI_sdio.o
endif

ARCH := arm
# ===Cross compile setting for Android L SDK ===
CROSS_COMPILE := /home/android_sdk/Allwinner/a33/android-L/lichee/out/sun8iw5p1/android/common/buildroot/external-toolchain/bin/arm-linux-gnueabi-
KSRC :=/home/android_sdk/Allwinner/a33/android-L/lichee/linux-3.4
endif

ifeq ($(CONFIG_PLATFORM_ACTIONS_ATV5201), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_ACTIONS_ATV5201
EXTRA_CFLAGS += -DCONFIG_SDIO_DISABLE_RXFIFO_POLLING_LOOP
ARCH := mips
CROSS_COMPILE := mipsel-linux-gnu-
KVER  := $(KERNEL_VER)
KSRC:= $(CFGDIR)/../../kernel/linux-$(KERNEL_VER)
endif

ifeq ($(CONFIG_PLATFORM_ARM_RTD299X), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DUSB_XMITBUF_ALIGN_SZ=1024 -DUSB_PACKET_OFFSET_SZ=0
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
ifeq ($(CONFIG_ANDROID), y)
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
# Enable this for Android 5.0
EXTRA_CFLAGS += -DCONFIG_RADIO_WORK
endif
#ARCH, CROSS_COMPILE, KSRC,and  MODDESTDIR are provided by external makefile
INSTALL_PREFIX :=
endif

ifeq ($(CONFIG_PLATFORM_HISILICON), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DCONFIG_PLATFORM_HISILICON
ifeq ($(SUPPORT_CONCURRENT),y)
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
endif
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
ARCH := arm
ifeq ($(CROSS_COMPILE),)
       CROSS_COMPILE = arm-hisiv200-linux-
endif
MODULE_NAME := rtl8192eu
ifeq ($(KSRC),)
       KSRC := ../../../../../../kernel/linux-3.4.y
endif
endif

# Platform setting
ifeq ($(CONFIG_PLATFORM_ARM_SPREADTRUM_6820), y)
ifeq ($(CONFIG_ANDROID_2X), y)
EXTRA_CFLAGS += -DANDROID_2X
endif
EXTRA_CFLAGS += -DCONFIG_PLATFORM_SPRD
EXTRA_CFLAGS += -DPLATFORM_SPREADTRUM_6820
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ifeq ($(RTL871X), rtl8188e)
EXTRA_CFLAGS += -DSOFTAP_PS_DURATION=50
endif
ifeq ($(CONFIG_SDIO_HCI), y)
EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
_PLATFORM_FILES += platform/platform_sprd_sdio.o
endif
endif

ifeq ($(CONFIG_PLATFORM_ARM_SPREADTRUM_8810), y)
ifeq ($(CONFIG_ANDROID_2X), y)
EXTRA_CFLAGS += -DANDROID_2X
endif
EXTRA_CFLAGS += -DCONFIG_PLATFORM_SPRD
EXTRA_CFLAGS += -DPLATFORM_SPREADTRUM_8810
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ifeq ($(RTL871X), rtl8188e)
EXTRA_CFLAGS += -DSOFTAP_PS_DURATION=50
endif
ifeq ($(CONFIG_SDIO_HCI), y)
EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
_PLATFORM_FILES += platform/platform_sprd_sdio.o
endif
endif

ifeq ($(CONFIG_PLATFORM_ARM_WMT), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS += -DCONFIG_PLATFORM_OPS
ifeq ($(CONFIG_SDIO_HCI), y)
_PLATFORM_FILES += platform/platform_ARM_WMT_sdio.o
endif
ARCH := arm
CROSS_COMPILE := /home/android_sdk/WonderMedia/wm8880-android4.4/toolchain/arm_201103_gcc4.5.2/mybin/arm_1103_le-
KSRC := /home/android_sdk/WonderMedia/wm8880-android4.4/kernel4.4/
MODULE_NAME :=8189es_kk
endif

ifeq ($(CONFIG_PLATFORM_RTK119X), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
#EXTRA_CFLAGS += -DCONFIG_PLATFORM_ARM_SUN7I
EXTRA_CFLAGS += -DCONFIG_TRAFFIC_PROTECT
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IFACE_NUMBER=3
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
#EXTRA_CFLAGS +=  -DCONFIG_QOS_OPTIMIZATION
EXTRA_CFLAGS += -DCONFIG_QOS_OPTIMIZATION

#EXTRA_CFLAGS += -DCONFIG_#PLATFORM_OPS
ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
#_PLATFORM_FILES += platform/platform_ARM_SUNxI_usb.o
endif
ifeq ($(CONFIG_SDIO_HCI), y)
_PLATFORM_FILES += platform/platform_ARM_SUNnI_sdio.o
endif

ARCH := arm

# ==== Cross compile setting for Android 4.4 SDK =====
#CROSS_COMPILE := arm-linux-gnueabihf-
KVER  := 3.10.24
#KSRC :=/home/android_sdk/Allwinner/a20/android-kitkat44/lichee/linux-3.4
CROSS_COMPILE := /home/realtek/software_phoenix/phoenix/toolchain/usr/local/arm-2013.11/bin/arm-linux-gnueabihf-
KSRC := /home/realtek/software_phoenix/linux-kernel
MODULE_NAME := 8192eu

endif

ifeq ($(CONFIG_PLATFORM_RTK129X), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DRTK_129X_PLATFORM
EXTRA_CFLAGS += -DCONFIG_TRAFFIC_PROTECT
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
#EXTRA_CFLAGS += -DCONFIG_P2P_IPS -DCONFIG_QOS_OPTIMIZATION
EXTRA_CFLAGS += -DCONFIG_QOS_OPTIMIZATION
# Enable this for Android 5.0
EXTRA_CFLAGS += -DCONFIG_RADIO_WORK
ifeq ($(CONFIG_RTL8821C)$(CONFIG_SDIO_HCI),yy)
EXTRA_CFLAGS += -DCONFIG_WAKEUP_GPIO_INPUT_MODE
EXTRA_CFLAGS += -DCONFIG_BT_WAKE_HST_OPEN_DRAIN
endif
EXTRA_CFLAGS += -Wno-error=date-time
# default setting for Android 7.0
ifeq ($(RTK_ANDROID_VERSION), nougat)
EXTRA_CFLAGS += -DRTW_P2P_GROUP_INTERFACE=1
endif
#EXTRA_CFLAGS += -DCONFIG_#PLATFORM_OPS
ifeq ($(CONFIG_USB_HCI), y)
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
endif

ARCH := arm64

# ==== Cross compile setting for Android 4.4 SDK =====
#CROSS_COMPILE := arm-linux-gnueabihf-
#KVER  := 4.1.10
#CROSS_COMPILE := $(CROSS)
#KSRC := $(LINUX_KERNEL_PATH)
CROSS_COMPILE := /home/android_sdk/DHC/trunk-6.0.0_r1-QA160627/phoenix/toolchain/asdk64-4.9.4-a53-EL-3.10-g2.19-a64nt-160307/bin/asdk64-linux-
KSRC := /home/android_sdk/DHC/trunk-6.0.0_r1-QA160627/linux-kernel
endif

ifeq ($(CONFIG_PLATFORM_NOVATEK_NT72668), y)
EXTRA_CFLAGS += -DCONFIG_PLATFORM_NOVATEK_NT72668
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_RX
EXTRA_CFLAGS += -DCONFIG_USE_USB_BUFFER_ALLOC_TX
ARCH ?= arm
CROSS_COMPILE := arm-linux-gnueabihf-
KVER := 3.8.0
KSRC := /Custom/Novatek/TCL/linux-3.8_header
#KSRC := $(KERNELDIR)
endif

ifeq ($(CONFIG_PLATFORM_ARM_TCC8930_JB42), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
# default setting for Android 4.1, 4.2
EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT
ARCH := arm
CROSS_COMPILE := /home/android_sdk/Telechips/v13.05_r1-tcc-android-4.2.2_tcc893x-evm_build/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-
KSRC := /home/android_sdk/Telechips/v13.05_r1-tcc-android-4.2.2_tcc893x-evm_build/kernel
MODULE_NAME := wlan
endif

ifeq ($(CONFIG_PLATFORM_RTL8197D), y)
EXTRA_CFLAGS += -DCONFIG_BIG_ENDIAN -DCONFIG_PLATFORM_RTL8197D
export DIR_LINUX=$(shell pwd)/../SDK/rlxlinux-sdk321-v50/linux-2.6.30
ARCH ?= rlx
CROSS_COMPILE:= $(DIR_LINUX)/../toolchain/rsdk-1.5.5-5281-EB-2.6.30-0.9.30.3-110714/bin/rsdk-linux-
KSRC := $(DIR_LINUX)
endif

ifeq ($(CONFIG_MULTIDRV), y)

ifeq ($(CONFIG_SDIO_HCI), y)
MODULE_NAME := rtw_sdio
endif

ifeq ($(CONFIG_USB_HCI), y)
MODULE_NAME := rtw_usb
endif

ifeq ($(CONFIG_PCI_HCI), y)
MODULE_NAME := rtw_pci
endif


endif

USER_MODULE_NAME ?=
ifneq ($(USER_MODULE_NAME),)
MODULE_NAME := $(USER_MODULE_NAME)
endif

ifneq ($(KERNELRELEASE),)

rtk_core :=	core/rtw_cmd.o \
		core/rtw_security.o \
		core/rtw_debug.o \
		core/rtw_io.o \
		core/rtw_ioctl_query.o \
		core/rtw_ioctl_set.o \
		core/rtw_ieee80211.o \
		core/rtw_mlme.o \
		core/rtw_mlme_ext.o \
		core/rtw_mi.o \
		core/rtw_wlan_util.o \
		core/rtw_vht.o \
		core/rtw_pwrctrl.o \
		core/rtw_rf.o \
		core/rtw_recv.o \
		core/rtw_sta_mgt.o \
		core/rtw_ap.o \
		core/rtw_xmit.o	\
		core/rtw_p2p.o \
		core/rtw_rson.o \
		core/rtw_tdls.o \
		core/rtw_br_ext.o \
		core/rtw_iol.o \
		core/rtw_sreset.o \
		core/rtw_btcoex_wifionly.o \
		core/rtw_btcoex.o \
		core/rtw_beamforming.o \
		core/rtw_odm.o \
		core/efuse/rtw_efuse.o

ifeq ($(CONFIG_SDIO_HCI), y)
rtk_core += core/rtw_sdio.o
endif

$(MODULE_NAME)-y += $(rtk_core)

$(MODULE_NAME)-$(CONFIG_INTEL_WIDI) += core/rtw_intel_widi.o

$(MODULE_NAME)-$(CONFIG_WAPI_SUPPORT) += core/rtw_wapi.o	\
					core/rtw_wapi_sms4.o

$(MODULE_NAME)-y += $(_OS_INTFS_FILES)
$(MODULE_NAME)-y += $(_HAL_INTFS_FILES)
$(MODULE_NAME)-y += $(_PHYDM_FILES)
$(MODULE_NAME)-y += $(_BTC_FILES)
$(MODULE_NAME)-y += $(_PLATFORM_FILES)

$(MODULE_NAME)-$(CONFIG_MP_INCLUDED) += core/rtw_mp.o

ifeq ($(CONFIG_RTL8723B), y)
$(MODULE_NAME)-$(CONFIG_MP_INCLUDED)+= core/rtw_bt_mp.o
endif

obj-$(CONFIG_RTL8710BU) := $(MODULE_NAME).o

else

export CONFIG_RTL8710BU = m

all: modules

modules:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KSRC) M=$(shell pwd)  modules

strip:
	$(CROSS_COMPILE)strip $(MODULE_NAME).ko --strip-unneeded

install:
	install -p -m 644 $(MODULE_NAME).ko  $(MODDESTDIR)
	/sbin/depmod -a ${KVER}

uninstall:
	rm -f $(MODDESTDIR)/$(MODULE_NAME).ko
	/sbin/depmod -a ${KVER}

backup_rtlwifi:
	@echo "Making backup rtlwifi drivers"
ifneq (,$(wildcard $(STAGINGMODDIR)/rtl*))
	@tar cPf $(wildcard $(STAGINGMODDIR))/backup_rtlwifi_driver.tar $(wildcard $(STAGINGMODDIR)/rtl*)
	@rm -rf $(wildcard $(STAGINGMODDIR)/rtl*)
endif
ifneq (,$(wildcard $(MODDESTDIR)realtek))
	@tar cPf $(MODDESTDIR)backup_rtlwifi_driver.tar $(MODDESTDIR)realtek
	@rm -fr $(MODDESTDIR)realtek
endif
ifneq (,$(wildcard $(MODDESTDIR)rtl*))
	@tar cPf $(MODDESTDIR)../backup_rtlwifi_driver.tar $(wildcard $(MODDESTDIR)rtl*)
	@rm -fr $(wildcard $(MODDESTDIR)rtl*)
endif
	@/sbin/depmod -a ${KVER}
	@echo "Please reboot your system"

restore_rtlwifi:
	@echo "Restoring backups"
ifneq (,$(wildcard $(STAGINGMODDIR)/backup_rtlwifi_driver.tar))
	@tar xPf $(STAGINGMODDIR)/backup_rtlwifi_driver.tar
	@rm $(STAGINGMODDIR)/backup_rtlwifi_driver.tar
endif
ifneq (,$(wildcard $(MODDESTDIR)backup_rtlwifi_driver.tar))
	@tar xPf $(MODDESTDIR)backup_rtlwifi_driver.tar
	@rm $(MODDESTDIR)backup_rtlwifi_driver.tar
endif
ifneq (,$(wildcard $(MODDESTDIR)../backup_rtlwifi_driver.tar))
	@tar xPf $(MODDESTDIR)../backup_rtlwifi_driver.tar
	@rm $(MODDESTDIR)../backup_rtlwifi_driver.tar
endif
	@/sbin/depmod -a ${KVER}
	@echo "Please reboot your system"

config_r:
	@echo "make config"
	/bin/bash script/Configure script/config.in


.PHONY: modules clean

clean:
	#$(MAKE) -C $(KSRC) M=$(shell pwd) clean
	cd hal ; rm -fr */*/*/*.mod.c */*/*/*.mod */*/*/*.o */*/*/*.o.* */*/*/.*.cmd */*/*/*.ko
	cd hal ; rm -fr */*/*.mod.c */*/*.mod */*/*.o */*/*.o.* */*/.*.cmd */*/*.ko
	cd hal ; rm -fr */*.mod.c */*.mod */*.o */*.o.* */.*.cmd */*.ko
	cd hal ; rm -fr *.mod.c *.mod *.o *.o.* .*.cmd *.ko
	cd core/efuse ; rm -fr *.mod.c *.mod *.o *.o.* .*.cmd *.ko
	cd core ; rm -fr *.mod.c *.mod *.o *.o.* .*.cmd *.ko
	cd os_dep/linux ; rm -fr *.mod.c *.mod *.o *.o.* .*.cmd *.ko
	cd os_dep ; rm -fr *.mod.c *.mod *.o *.o.* .*.cmd *.ko
	cd platform ; rm -fr *.mod.c *.mod *.o *.o.* .*.cmd *.ko
	rm -fr Module.symvers ; rm -fr Module.markers ; rm -fr modules.order
	rm -fr *.mod.c *.mod *.o *.o.* .*.cmd *.ko *~
	rm -fr .tmp_versions
	rm -fr .cache.mk
endif
