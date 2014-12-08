TAR_SOURCE := tar-1.28.tar.gz
TAR_SOURCE_PACKAGE := "http://ftp.gnu.org/gnu/tar/$(TAR_SOURCE)"

COREUTILS_SOURCE := coreutils-8.23.tar.xz
COREUTILS_SOURCE_TAR := coreutils-8.23.tar
COREUTILS_SOURCE_PACKAGE := "http://ftp.gnu.org/gnu/coreutils/$(COREUTILS_SOURCE)"

.PHONY: coreutils.download
coreutils.download: $(DL)/$(COREUTILS_SOURCE)
$(DL)/$(COREUTILS_SOURCE):
	$(MKDIR) $(DL)
	wget -O $@ $(COREUTILS_SOURCE_PACKAGE)

$(call get_stamp_target,coreutils.extract): $(DL)/$(COREUTILS_SOURCE)
	$(CAT) $< | $(XZ) -d > $(DL)/$(COREUTILS_SOURCE_TAR)
	$(MKDIR) coreutils
	$(TAR) -xvf $(DL)/$(COREUTILS_SOURCE_TAR) --strip-components 1 -C coreutils
	$(stamp_target)

.PHONY: coreutils.compile
coreutils.compile: $(call get_stamp_target,coreutils.compile)
$(call get_stamp_target,coreutils.compile): $(call get_stamp_target,coreutils.extract)
	$(shell cd coreutils;./configure > /dev/null)
	$(MAKE) -C coreutils all
	$(stamp_target)

.PHONY: tar.download
tar.download: $(DL)/$(TAR_SOURCE)
$(DL)/$(TAR_SOURCE):
	$(MKDIR) $(DL)
	wget -O $@ $(TAR_SOURCE_PACKAGE)

$(call get_stamp_target,tar.extract): $(DL)/$(TAR_SOURCE)
	$(MKDIR) tar
	$(TAR) -xzvf $< --strip-components 1 -C tar
	$(stamp_target)

.PHONY: tar.compile
tar.compile: $(call get_stamp_target,tar.compile)
$(call get_stamp_target,tar.compile): $(call get_stamp_target,tar.extract)
	$(shell cd tar;./configure > /dev/null)
	$(MAKE) -C tar all
	$(stamp_target)

ARC_BUILD_INTERMEDIATE_TARGETS := $(foreach r,$(REVISION_LIST),arc_build-$r)

.PHONY: arc_build_all
arc_build_all:
	$(MAKE)  http_proxy=$(HTTP_PROXY) https_proxy=$(HTTPS_PROXY) tar.compile
	$(MAKE) TAR=$(CURDIR)/tar/src/tar http_proxy=$(HTTP_PROXY) https_proxy=$(HTTPS_PROXY) downloads
	$(MAKE) TAR=$(CURDIR)/tar/src/tar $(ARC_BUILD_INTERMEDIATE_TARGETS)
	$(MAKE) PATH=$(CURDIR)/coreutils/src:$(PATH) TAR=$(CURDIR)/tar/src/tar all

	
define arc_build_project

.PHONY: arc_build-$1
arc_build-$1:
	arc submit -i --watch -- arc vnc make -j1 $1.all

endef

$(foreach r,$(REVISION_LIST),$(eval $(call arc_build_project,$r)))
