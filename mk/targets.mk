# Default Makefile targets, for Libreswan
#
# Copyright (C) 2015-2016, Andrew Cagney <cagney@gnu.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See <http://www.fsf.org/copyleft/gpl.txt>.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.

# Define a standard set of global (recursive) and local targets.

# Note: To prevent recursive explosion, recursive targets should
# depend directly on local targets, and not on other recursive
# targets.

# Note: To prevent a parallel recursion explosion, recursive targets
# should only depend on local targets.  For instance implementing
# "all" as "all: base manpages" would result in make attempting to, in
# parallel, recursively build both "base" and "manpages".  Rules
# building Makefile dependencies are not ready for this.
#
# Note: For reasons similar to the above target aliases should, at
# most, depend on on global (recursive) target.

# XXX: BROKEN_TARGETS, found in top-level/Makefile and mk/top.mk have
# custom rules and use ::.  They also, typically, descend into
# $(builddir) instead of $(srcdir).

# This is the default; unless your Makefile puts something earlier.

all:

# Map common, and historic targets, onto current names.  For historic
# reasons, "programs" also builds everything.

.PHONY: programs
programs: all
man: manpages

# Generate a recursive target.

define recursive-target
  .PHONY: $(1) local-$(1) recursive-$(1)
  $(1): local-$(1) recursive-$(1)
  local-$(1):

  # Building $(SUBDIRS) after all local targets is historic behaviour
  recursive-$(1): local-$(1)

  # Require $(builddir)/Makefile.  Targets that switch to builddir
  # require it.  In $(topsrcdir) this will trigger a re-build of the
  # Makefiles, in sub-directories this will simply barf.  It's assumed
  # that $(OBJDIR) has been created by the time a subdir build has
  # run.
  $(1) local-$(1) recursive-$(1): $$(builddir)/Makefile

  recursive-$(1):
	@set -eu $$(foreach subdir,$$(SUBDIRS),; $$(MAKE) -C $$(subdir) $$(patsubst recursive-%,%,$$@))
endef

# The build is split into several sub-targets - namely so that
# manpages are not built by default.
#
# For each define: TARGET clean-TARGET install-TARGET

TARGETS = base manpages

$(foreach target,$(TARGETS),$(eval $(call recursive-target,$(target))))

$(foreach target,$(TARGETS),$(eval $(call recursive-target,clean-$(target))))

$(foreach target,$(TARGETS),$(eval $(call recursive-target,install-$(target))))
# install requires up-to-date build; recursive make, being evil, makes
# this less than 100% reliable.
local-install-base: local-base
local-install-manpages: local-manpages

# More generic targets.   These, in each directory, invoke local
# versions of the above.

$(eval $(call recursive-target,all))
local-all: $(patsubst %,local-%,$(TARGETS))

$(eval $(call recursive-target,clean))
local-clean: $(patsubst %,local-clean-%,$(TARGETS))

$(eval $(call recursive-target,install))
local-install: $(patsubst %,local-install-%,$(TARGETS))

# Install:

# The install_file_list target is special; the command:
#
#    $ make install_file_list > file-list
#
# must only contain the list of files that would be installed
# (generated by list-local-base et.al.).  Consequently:
#
# - to stop "Nothing to be done" messages, the target is never empty
#
# - to stop make's directory messages, --no-print-directory is
#   specified

LOCAL_TARGETS = $(addprefix local-, $(TARGETS))
LIST_TARGETS = $(addprefix list-, $(TARGETS))
LIST_LOCAL_TARGETS = $(addprefix list-, $(LOCAL_TARGETS))
.PHONY: install_file_list $(LIST_TARGETS) $(LIST_LOCAL_TARGETS)
install_file_list $(LIST_TARGETS):
	@set -eu ; $(foreach dir,$(SUBDIRS), \
		echo $(PWD)/$(dir): 1>&2 ; \
		$(MAKE) -C $(dir) --no-print-directory $@ ; \
	)
install_file_list: list-local-base list-local-manpages
list-base: list-local-base
list-manpages: list-local-manpages

# Check: much simpler

GLOBAL_TARGETS += check
check:

# Checkprograms: XXX: should this be deleted; it doesn't do anything?
GLOBAL_TARGETS += checkprograms
checkprograms:
