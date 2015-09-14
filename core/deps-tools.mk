# Copyright (c) 2013-2015, Loïc Hoguin <essen@ninenines.eu>
# Copyright (c) 2015, Jean-Sébastien Pédron <jean-sebastien@rabbitmq.com>
# This file is part of erlang.mk and subject to the terms of the ISC License.

# Fetch dependencies (without building them).

.PHONY: fetch-deps fetch-doc-deps fetch-rel-deps fetch-test-deps \
	fetch-shell-deps

ifneq ($(SKIP_DEPS),)
fetch-deps fetch-doc-deps fetch-rel-deps fetch-test-deps fetch-shell-deps:
	@:
else
# By default, we fetch "normal" dependencies. They are also included no
# matter the type of requested dependencies.
#
# $(ALL_DEPS_DIRS) includes $(BUILD_DEPS).
fetch-deps: $(ALL_DEPS_DIRS)
fetch-doc-deps: $(ALL_DEPS_DIRS) $(ALL_DOC_DEPS_DIRS)
fetch-rel-deps: $(ALL_DEPS_DIRS) $(ALL_REL_DEPS_DIRS)
fetch-test-deps: $(ALL_DEPS_DIRS) $(ALL_TEST_DEPS_DIRS)
fetch-shell-deps: $(ALL_DEPS_DIRS) $(ALL_SHELL_DEPS_DIRS)

# Allow to use fetch-deps and $(DEP_TYPES) to fetch multiple types of
# dependencies with a single target.
ifneq ($(filter doc,$(DEP_TYPES)),)
fetch-deps: $(ALL_DOC_DEPS_DIRS)
endif
ifneq ($(filter rel,$(DEP_TYPES)),)
fetch-deps: $(ALL_REL_DEPS_DIRS)
endif
ifneq ($(filter test,$(DEP_TYPES)),)
fetch-deps: $(ALL_TEST_DEPS_DIRS)
endif
ifneq ($(filter shell,$(DEP_TYPES)),)
fetch-deps: $(ALL_SHELL_DEPS_DIRS)
endif

fetch-deps fetch-doc-deps fetch-rel-deps fetch-test-deps fetch-shell-deps:
ifndef IS_APP
	$(verbose) for dep in $(ALL_APPS_DIRS) ; do \
		$(MAKE) -C $$dep $@ IS_APP=1 || exit $$?; \
	done
endif
ifneq ($(IS_DEP),1)
	$(verbose) rm -f $(ERLANG_MK_TMP)/$@.log
endif
	$(verbose) mkdir -p $(ERLANG_MK_TMP)
	$(verbose) for dep in $^ ; do \
		if ! grep -qs ^$$dep$$ $(ERLANG_MK_TMP)/$@.log; then \
			echo $$dep >> $(ERLANG_MK_TMP)/$@.log; \
			if grep -qs -E "^[[:blank:]]*include[[:blank:]]+(erlang\.mk|.*/erlang\.mk)$$" \
			 $$dep/GNUmakefile $$dep/makefile $$dep/Makefile; then \
				$(MAKE) -C $$dep fetch-deps IS_DEP=1 || exit $$?; \
			fi \
		fi \
	done
endif # ifneq ($(SKIP_DEPS),)

# List dependencies recursively.

.PHONY: list-deps list-doc-deps list-rel-deps list-test-deps \
	list-shell-deps

ifneq ($(SKIP_DEPS),)
$(ERLANG_MK_RECURSIVE_DEPS_LIST) \
$(ERLANG_MK_RECURSIVE_DOC_DEPS_LIST) \
$(ERLANG_MK_RECURSIVE_REL_DEPS_LIST) \
$(ERLANG_MK_RECURSIVE_TEST_DEPS_LIST) \
$(ERLANG_MK_RECURSIVE_SHELL_DEPS_LIST):
	$(verbose) :> $@
else
LIST_DIRS = $(ALL_DEPS_DIRS)
LIST_DEPS = $(BUILD_DEPS) $(DEPS)

$(ERLANG_MK_RECURSIVE_DEPS_LIST): fetch-deps

ifneq ($(IS_DEP),1)
$(ERLANG_MK_RECURSIVE_DOC_DEPS_LIST): LIST_DIRS += $(ALL_DOC_DEPS_DIRS)
$(ERLANG_MK_RECURSIVE_DOC_DEPS_LIST): LIST_DEPS += $(DOC_DEPS)
$(ERLANG_MK_RECURSIVE_DOC_DEPS_LIST): fetch-doc-deps
else
$(ERLANG_MK_RECURSIVE_DOC_DEPS_LIST): fetch-deps
endif

ifneq ($(IS_DEP),1)
$(ERLANG_MK_RECURSIVE_REL_DEPS_LIST): LIST_DIRS += $(ALL_REL_DEPS_DIRS)
$(ERLANG_MK_RECURSIVE_REL_DEPS_LIST): LIST_DEPS += $(REL_DEPS)
$(ERLANG_MK_RECURSIVE_REL_DEPS_LIST): fetch-rel-deps
else
$(ERLANG_MK_RECURSIVE_REL_DEPS_LIST): fetch-deps
endif

ifneq ($(IS_DEP),1)
$(ERLANG_MK_RECURSIVE_TEST_DEPS_LIST): LIST_DIRS += $(ALL_TEST_DEPS_DIRS)
$(ERLANG_MK_RECURSIVE_TEST_DEPS_LIST): LIST_DEPS += $(TEST_DEPS)
$(ERLANG_MK_RECURSIVE_TEST_DEPS_LIST): fetch-test-deps
else
$(ERLANG_MK_RECURSIVE_TEST_DEPS_LIST): fetch-deps
endif

ifneq ($(IS_DEP),1)
$(ERLANG_MK_RECURSIVE_SHELL_DEPS_LIST): LIST_DIRS += $(ALL_SHELL_DEPS_DIRS)
$(ERLANG_MK_RECURSIVE_SHELL_DEPS_LIST): LIST_DEPS += $(SHELL_DEPS)
$(ERLANG_MK_RECURSIVE_SHELL_DEPS_LIST): fetch-shell-deps
else
$(ERLANG_MK_RECURSIVE_SHELL_DEPS_LIST): fetch-deps
endif

$(ERLANG_MK_RECURSIVE_DEPS_LIST) \
$(ERLANG_MK_RECURSIVE_DOC_DEPS_LIST) \
$(ERLANG_MK_RECURSIVE_REL_DEPS_LIST) \
$(ERLANG_MK_RECURSIVE_TEST_DEPS_LIST) \
$(ERLANG_MK_RECURSIVE_SHELL_DEPS_LIST):
ifneq ($(IS_DEP),1)
	$(verbose) rm -f $@.orig
endif
ifndef IS_APP
	$(verbose) for app in $(filter-out $(CURDIR),$(ALL_APPS_DIRS)); do \
		$(MAKE) -C "$$app" --no-print-directory $@ IS_APP=1 || :; \
	done
endif
	$(verbose) for dep in $(filter-out $(CURDIR),$(LIST_DIRS)); do \
		if grep -qs -E "^[[:blank:]]*include[[:blank:]]+(erlang\.mk|.*/erlang\.mk)$$" \
		 $$dep/GNUmakefile $$dep/makefile $$dep/Makefile; then \
			$(MAKE) -C "$$dep" --no-print-directory $@ IS_DEP=1; \
		fi; \
	done
	$(verbose) for dep in $(LIST_DEPS); do \
		echo $(DEPS_DIR)/$$dep; \
	done >> $@.orig
ifndef IS_APP
ifneq ($(IS_DEP),1)
	$(verbose) sort < $@.orig | uniq > $@
	$(verbose) rm -f $@.orig
endif
endif
endif # ifneq ($(SKIP_DEPS),)

ifneq ($(SKIP_DEPS),)
list-deps list-doc-deps list-rel-deps list-test-deps list-shell-deps:
	@:
else
list-deps: $(ERLANG_MK_RECURSIVE_DEPS_LIST)
list-doc-deps: $(ERLANG_MK_RECURSIVE_DOC_DEPS_LIST)
list-rel-deps: $(ERLANG_MK_RECURSIVE_REL_DEPS_LIST)
list-test-deps: $(ERLANG_MK_RECURSIVE_TEST_DEPS_LIST)
list-shell-deps: $(ERLANG_MK_RECURSIVE_SHELL_DEPS_LIST)

# Allow to use fetch-deps and $(DEP_TYPES) to fetch multiple types of
# dependencies with a single target.
ifneq ($(IS_DEP),1)
ifneq ($(filter doc,$(DEP_TYPES)),)
list-deps: $(ERLANG_MK_RECURSIVE_DOC_DEPS_LIST)
endif
ifneq ($(filter rel,$(DEP_TYPES)),)
list-deps: $(ERLANG_MK_RECURSIVE_REL_DEPS_LIST)
endif
ifneq ($(filter test,$(DEP_TYPES)),)
list-deps: $(ERLANG_MK_RECURSIVE_TEST_DEPS_LIST)
endif
ifneq ($(filter shell,$(DEP_TYPES)),)
list-deps: $(ERLANG_MK_RECURSIVE_SHELL_DEPS_LIST)
endif
endif

list-deps list-doc-deps list-rel-deps list-test-deps list-shell-deps:
	$(verbose) cat $^ | sort | uniq
endif # ifneq ($(SKIP_DEPS),)
