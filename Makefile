# Makefile for Apple Build + Integration
#
# We first build Git for each architecture by creating a
# symbolic link farm in subdirectories of $(OBJROOT) (e.g.
# $(OBJROOT)/i386) and building there using Git's own
# Makefiles.  Once all architectures are built, we use
# the first architecture's subdirectory to combine the
# per-architecture binaries into universal binaries.
# Finally, we use Git's own Makefiles to perform the
# installation from the first architecture's subdirectory.
# 
export makefile := $(realpath $(lastword $(MAKEFILE_LIST)))
export srcdir   := $(dir $(makefile))
export mandir   := $(srcdir)/src/git-manpages

.PHONY: all build install installsrc installhdrs root merge \
  install-bin install-man

export SRCROOT ?= $(CURDIR)
export OBJROOT ?= $(CURDIR)/roots/obj
export SYMROOT ?= $(CURDIR)/roots/sym
export DSTROOT ?= $(CURDIR)/roots/dst

ifndef CC
ifdef SDKROOT
CC := $(shell xcrun -find -sdk $(SDKROOT) cc)
else
CC := $(shell xcrun -find cc)
endif
endif

tmp := $(strip $(shell expr '$(RC_ProjectSourceVersion)' : \
  '\([0-9]\{1,4\}\(\.[0-9]\{0,3\}\)\{0,1\}\)$$'))
ifeq (,$(tmp))
override RC_ProjectSourceVersion := 9999
else
override RC_ProjectSourceVersion := $(tmp)
endif
export RC_ProjectSourceVersion
ifndef RC_ARCHS
RC_ARCHS := $(shell uname -m) $(warning using host architecture)
endif
cflags := $(strip $(RC_CFLAGS))
$(foreach arch,$(RC_ARCHS),$(eval cflags := $(subst $(cflags),-arch $(arch) ,)))
export RC_CFLAGS := $(cflags)

STRIP := strip -S
LNDIR := /usr/X11/bin/lndir
submakevars := -j`sysctl -n hw.activecpu` prefix=/usr \
  NO_FINK=YesPlease NO_DARWIN_PORTS=YesPlease \
  RUNTIME_PREFIX=YesPlease \
  GITGUI_VERSION=0.12.0 V=1 \
  CFLAGS='-ggdb3 -Os -pipe -Wall -Wformat-security -D_FORTIFY_SOURCE=2'

objarch   := $(foreach arch,$(RC_ARCHS),$(OBJROOT)/$(arch))
firstarch := $(firstword $(objarch))

all: build

ifeq ($(realpath $(SRCROOT)), $(realpath $(srcdir)))
installsrc:
	@echo Nothing to do for installsrc
else
installsrc:
	mkdir -p $(SRCROOT)
	tar -cp --exclude .git --exclude .svn --exclude CVS . | tar -pox -C "$(SRCROOT)"
endif

installhdrs:
	@echo No headers to install.

build: $(OBJROOT)/dsyms.timestamp

install: install-bin install-man
	if [ -f "$(DSTROOT)/usr/share/git-gui/lib/Git Gui.app/Contents/MacOS/Wish Shell" ] ; then \
		rm "$(DSTROOT)/usr/share/git-gui/lib/Git Gui.app/Contents/MacOS/Wish Shell" ; \
		ln -s "/System/Library/Frameworks/Tk.framework/Resources/Wish Shell.app/Contents/MacOS/Wish Shell" "$(DSTROOT)/usr/share/git-gui/lib/Git Gui.app/Contents/MacOS/Wish Shell" ; \
	else \
		rm "$(DSTROOT)/usr/share/git-gui/lib/Git Gui.app/Contents/MacOS/Wish" ; \
		ln -s "/System/Library/Frameworks/Tk.framework/Resources/Wish.app/Contents/MacOS/Wish" "$(DSTROOT)/usr/share/git-gui/lib/Git Gui.app/Contents/MacOS/Wish" ; \
	fi
	install -d -o root -g wheel -m 0755 $(DSTROOT)/usr/local/OpenSourceVersions
	install -o root -g wheel -m 0644 $(SRCROOT)/Git.plist $(DSTROOT)/usr/local/OpenSourceVersions

install-bin: $(OBJROOT)/dsyms.timestamp
	$(MAKE) -C $(firstarch) $(submakevars) \
	  'CC=$(CC) -arch $(firstword $(RC_ARCHS))' \
	  'DESTDIR=$(DSTROOT)' \
	  install
	rm -fr $(DSTROOT)/usr/System #XXX Bogus perldoc installation

install-man: $(OBJROOT)/dir.timestamp
	for section in 1 5 7; do \
	    install -d -o root -g wheel -m 0755 \
	      $(DSTROOT)/usr/share/man/man$$section; \
	    find $(mandir)/man$$section -type f -name "*.$$section" | \
	      while read page; do \
	          page_="$(OBJROOT)/$$(basename $$page).gz"; \
	          gzip -c < "$$page" > "$$page_"; \
		  install -C -o root -g wheel -m 0644 "$$page_" \
		    $(DSTROOT)/usr/share/man/man$$section; \
	      done; \
	done

$(OBJROOT)/programs-list: $(firstarch)/build.timestamp
	$(MAKE) -C $(firstarch) -f $(CURDIR)/examine.make $(submakevars) \
	  print-programs > $@

$(OBJROOT)/universal.timestamp: \
  $(OBJROOT)/programs-list \
  $(SYMROOT)/dir.timestamp \
  $(foreach x,$(objarch),$(x)/build.timestamp)
	for prog in $$(cat $<); do \
	    (set -x; lipo -create -output $(firstarch)/$$prog.u \
	      $(foreach x,$(objarch),$(x)/$$prog) && \
	      mv $(firstarch)/$$prog.u $(firstarch)/$$prog && \
	      cp $(firstarch)/$$prog $(SYMROOT)/ && \
	      $(STRIP) $(firstarch)/$$prog); \
	done
	touch $@

$(OBJROOT)/dsyms.timestamp: $(OBJROOT)/universal.timestamp
	cd $(SYMROOT) && \
	  find . -type f -perm -001 -print0 | xargs -n 1 -0 dsymutil
	touch $@

clean:: $(OBJROOT)/dir.timestamp
	cd $(OBJROOT) && rm -fr *

root:
	cd $(OBJROOT) && ditto -cz $(DSTROOT) \
	  $(or $(RC_ProjectName),git)-$(RC_ProjectSourceVersion).cpgz

merge:
	ditto -V $(DSTROOT) /

$(OBJROOT)/dir.timestamp:
	mkdir -p $(dir $@) && touch $@

$(SYMROOT)/dir.timestamp:
	mkdir -p $(dir $@) && touch $@

define each_arch
$(OBJROOT)/$(1)/dir.timestamp:
	mkdir -p $$(dir $$@) && touch $$@

$(OBJROOT)/$(1)/lndir.timestamp: $(OBJROOT)/$(1)/dir.timestamp
	$$(LNDIR) $$(CURDIR)/src/git $$(dir $$@) && touch $$@

$(OBJROOT)/$(1)/build.timestamp: $(OBJROOT)/$(1)/lndir.timestamp
	cat /dev/null > $$(OBJROOT)/$(1)/program-list
	$$(MAKE) -C $$(dir $$@) $$(submakevars) \
	  'CC=$$(CC) -arch $(1)' \
	  'uname_M=$(1)' 'uname_P=$(1)' \
	  && touch $$@

endef

$(foreach arch,$(RC_ARCHS),$(eval $(call each_arch,$(arch))))

# ;; Local Variables: **
# ;; mode: makefile-gmake **
# ;; mode: ruler **
# ;; fill-column: 72 **
# ;; tab-width: 8 **
# ;; End: **
