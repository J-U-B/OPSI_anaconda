############################################################
# OPSI package Makefile (ANACONDA)
# Version: 2.9
# Jens Boettge <boettge@mpi-halle.mpg.de>
# 2022-02-10 10:30:46 +0100
############################################################

.PHONY: header clean mpimsp mpimsp_test o4i o4i_test dfn dfn_test all_test all_prod all help download pdf var_check dummy_build
.DEFAULT_GOAL := help

### defaults:
DEFAULT_SPEC = spec.json
DEFAULT_ALLINC = false
DEFAULT_KEEPFILES = false
DEFAULT_ARCHIVEFORMAT = cpio
### to keep the changelog inside the control set CHANGELOG_TGT to an empty string
### otherwise the given filename will be used:
CHANGELOG_TGT = changelog.txt
# CHANGELOG_TGT =
DEFAULT_PYVER = 3
#...vaild values: 2 | 3 | 2,3 | both
DEFAULT_DOWNLOADER = curl

#--- temporary for DFN - O4I transition ----------
DEFAULT_LEGACY = false
LEGACY ?= $(DEFAULT_LEGACY)
LEGACY_SEL := "[true] [false]"
LFX := $(firstword $(LEGACY))
LFY := $(shell echo $(LFX) | tr A-Z a-z)
LFZ := $(findstring [$(LFY)],$(LEGACY_SEL))
ifeq (,$(LFZ))
	IS_LEGACY := false
else
	IS_LEGACY := $(LFY)
endif
#-------------------------------------------------

PWD = ${CURDIR}
BUILD_DIR = BUILD
DL_DIR = $(PWD)/DOWNLOAD
PACKAGE_DIR = PACKAGES
SRC_DIR = SRC

OPSI_BUILDER := $(shell which opsi-makepackage)
ifeq ($(OPSI_BUILDER),)
	override OPSI_BUILDER := $(shell which opsi-makeproductfile)
	ifeq ($(OPSI_BUILDER),)
		$(error Error: opsi-make(package|productfile) not found!)
	endif
endif
$(info * OPSI_BUILDER = $(OPSI_BUILDER))


### spec file:
SPEC ?= $(DEFAULT_SPEC)
ifeq ($(shell test -f $(SPEC) && echo OK),OK)
    # $(info [INFO] spec file found: $(SPEC))
else
    $(error [ERROR] spec file NOT found: $(SPEC))
endif


### Which Python flavour 2, 3 or both (...or what's cominf next)
PYVER ?= $(DEFAULT_PYVER)
PYTHON_VERSIONS:="[2] [3] [2,3] [3,2] [both]"
PKGX := $(firstword $(PYVER))
PKGY := $(shell echo $(PKGX) | tr A-Z a-z)
PKGZ := $(findstring [$(PKGY)],$(PYTHON_VERSIONS))
ifeq (,$(PKGZ))
   $(error [ERROR] Invalid value for PYVER (valid values are "2", "3", "2,3", "both"))
else
	ifeq (both,$(PKGY))
		PY_VER := 2,3
	else
		PY_VER := $(PKGY)
	endif
    $(info [INFO] Building packages for Anaconda $(PYVER))
endif
PVS=$(shell echo $(PY_VER) | sed 's/,/ /')
#PY_VER := $(PYVER)
#PVS = $(PYVER)

SW_VER := $(shell grep '"O_SOFTWARE_VER"' $(SPEC)     	| sed -e 's/^.*\s*:\s*\"\(.*\)\".*$$/\1/' )
SW_BUILD := $(shell grep '"O_PKG_VER"' $(SPEC)        	| sed -e 's/^.*\s*:\s*\"\(.*\)\".*$$/\1/' )
SW_NAME := $(shell grep '"O_SOFTWARE"' $(SPEC)        	| sed -e 's/^.*\s*:\s*\"\(.*\)\".*$$/\1/' )
SW_ONLY64 := $(shell grep '"ifdef_64bit_only"' $(SPEC)	| sed -re 's/^\s*.*\s*:\s*\"?([a-Z]+)\"?,?.*$$/\1/' | tr A-Z a-z)

ifndef BUILD_PY_VER
 BUILD_PY_VER := $(PYVER)
endif

ifeq ($(BUILD_PY_VER),$(filter $(BUILD_PY_VER),2 3))
	ifeq ($(SW_ONLY64),true)
		override FILES_MASK := Anaconda$(BUILD_PY_VER)-$(SW_VER)-*_64.exe
		override FILES_EXPECTED := 1
	else
		override FILES_MASK = Anaconda$(BUILD_PY_VER)-$(SW_VER)-*.exe
		override FILES_EXPECTED := 2
	endif	
else
	ifeq ($(SW_ONLY64),true)
		override FILES_MASK = Anaconda?-$(SW_VER)-*_64.exe
		override FILES_EXPECTED := 2
	else
		override FILES_MASK = Anaconda?-$(SW_VER)-*.exe
		override FILES_EXPECTED := 4
	endif
endif


MUSTACHE = ./SRC/TOOLS/mustache.32
BUILD_JSON = $(BUILD_DIR)/build.json
CONTROL_IN = $(SRC_DIR)/OPSI/control.in
CONTROL = $(BUILD_DIR)/OPSI/control
DOWNLOAD_SH_IN = ./SRC/CLIENT_DATA/product_downloader.sh.in
DOWNLOAD_SH = $(PWD)/product_downloader.sh
OPSI_FILES := control preinst postinst
FILES_IN := $(basename $(shell (cd $(SRC_DIR)/CLIENT_DATA; ls *.in 2>/dev/null)))
FILES_OPSI_IN := $(basename $(shell (cd $(SRC_DIR)/OPSI; ls *.in 2>/dev/null)))
TODAY := $(shell date +"%Y-%m-%d")
TMP_FILE := $(shell mktemp -u)

### spec file:
SPEC ?= $(DEFAULT_SPEC)
ifeq ($(shell test -f $(SPEC) && echo OK),OK)
    $(info * spec file found: $(SPEC))
else
    $(error Error: spec file NOT found: $(SPEC))
endif

SW_VER := $(shell grep '"O_SOFTWARE_VER"' $(SPEC)     | sed -e 's/^.*\s*:\s*\"\(.*\)\".*$$/\1/' )
SW_BUILD := $(shell grep '"O_PKG_VER"' $(SPEC)        | sed -e 's/^.*\s*:\s*\"\(.*\)\".*$$/\1/' )
SW_NAME := $(shell grep '"O_SOFTWARE"' $(SPEC)        | sed -e 's/^.*\s*:\s*\"\(.*\)\".*$$/\1/' )

FILES_MASK := *.$(SW_VER).*exe
FILES_EXPECTED = 2

MD5SUM_FILE := $(SW_NAME).md5sums

### Only download packages?
ifeq ($(MAKECMDGOALS),download)
	ONLY_DOWNLOAD=true
else
	ONLY_DOWNLOAD=false
endif

### build "batteries included' package?
ALLINC ?= $(DEFAULT_ALLINC)
ALLINC_SEL := "[true] [false]"
AFX := $(firstword $(ALLINC))
AFY := $(shell echo $(AFX) | tr A-Z a-z)
AFZ := $(findstring [$(AFY)],$(ALLINC_SEL))
ifeq (,$(AFZ))
	ALLINCLUSIVE := false
else
	ALLINCLUSIVE := $(AFY)
endif

ifeq ($(ALLINCLUSIVE),true)
	CUSTOMNAME := ""
else
	CUSTOMNAME := "dl"
endif

### Keep all files in files/ directory?
KEEPFILES ?= $(DEFAULT_KEEPFILES)
KEEPFILES_SEL := "[true] [false]"
KFX := $(firstword $(KEEPFILES))
override KFX := $(shell echo $(KFX) | tr A-Z a-z)
override KFX := $(findstring [$(KFX)],$(KEEPFILES_SEL))
ifeq (,$(KFX))
	override KEEPFILES := false
else
	override KEEPFILES := $(shell echo $(KFX) | tr -d '[]')
endif

ARCHIVE_FORMAT ?= $(DEFAULT_ARCHIVEFORMAT)
ARCHIVE_TYPES :="[cpio] [tar]"
FFX := $(firstword $(ARCHIVE_FORMAT))
FFY := $(shell echo $(FFX) | tr A-Z a-z)

ifeq (,$(findstring [$(FFY)],$(ARCHIVE_TYPES)))
	BUILD_FORMAT = $(DEFAULT_ARCHIVEFORMAT)
else
	BUILD_FORMAT = $(FFY)
endif

DOWNLOADER ?= $(DEFAULT_DOWNLOADER)
DOWNLOADER_VALID :="[curl] [wget]"
override DFX := $(firstword $(DOWNLOADER))
override DFY := $(shell echo $(DFX) | tr A-Z a-z)

ifeq (,$(findstring [$(DFY)],$(DOWNLOADER_VALID)))
	override DOWNLOADER = $(DEFAULT_DOWNLOADER)
else
	override DOWNLOADER = $(DFY)
endif

### legacy level:
LEGACY_LEVEL ?= 0


leave_err:
	exit 1

var_check:
	@echo "=================================================================="
	@echo "* Software Name         : [$(SW_NAME)]"
	@echo "* Software Version      : [$(SW_VER)]"
	@echo "* Package Build         : [$(SW_BUILD)]"
	@echo "* SPEC file             : [$(SPEC)]"
	@echo "* Batteries included    : [default: $(ALLINC)] --> [$(ALLINCLUSIVE)]"
#	@echo "* Python version(s)     : [default: $(PYVER)] --> [$(PKGX)] --> [$(PKGY)] --> [$(PKGZ)] --> [$(PY_VER)]"
	@echo "* Python version(s)     : [default: $(PYVER)] --> [$(PY_VER)]"
	@echo "  * BUILD_PY_VER = $(BUILD_PY_VER)"
	@echo "  * PVS          = $(PVS)"
	@echo "* 64 bit only?          : [$(SW_ONLY64)]"
	@echo "* Custom Name           : [$(CUSTOMNAME)]"
	@#echo "* OPSI Archive Types    : [$(ARCHIVE_TYPES)]"
	@echo "* OPSI Archive Format   : [default: $(ARCHIVE_FORMAT)] --> $(BUILD_FORMAT)"
	@echo "* Downloader            : [default: $(DEFAULT_DOWNLOADER)] --> $(DOWNLOADER)"
	@echo "* Templates OPSI        : [$(FILES_OPSI_IN)]"
	@echo "* Templates CLIENT_DATA : [$(FILES_IN)]"
	@echo "* Files Mask            : [$(FILES_MASK)]"
	@echo "* Files expected        : [$(FILES_EXPECTED)]"
    @echo "* Keep files            : [$(KEEPFILES)]"
	@echo "* Legacy build          : [$(IS_LEGACY)]"
	@echo "* Changelog target      : [$(CHANGELOG_TGT)]"
	@echo "=================================================================="
	@echo "* Installer files in $(DL_DIR):"
	@for F in `ls -1 $(DL_DIR)/$(FILES_MASK) | sed -re 's/.*\/(.*)$$/\1/' `; do echo "    $$F"; done 
	@ $(eval NUM_FILES := $(shell ls -l $(DL_DIR)/$(FILES_MASK) 2>/dev/null | wc -l))
	@echo "* $(NUM_FILES) files found"
	@echo "=================================================================="
	@#for PV in $(PVS); do make BUILD_PY_VER=$${PV} dummy_build; done
	@#echo "=================================================================="

dummy_build:
	@echo "[Testing] PY_VER=$(BUILD_PY_VER)"
	@echo "          Files Mask: $(FILES_MASK)"
	@echo "          Files expected: $(FILES_EXPECTED)"

header: var_check
	@echo "=================================================================="
	@echo "                      Building OPSI package(s)"
	@echo "=================================================================="

fix_rights: header
	@echo "---------- setting rights for PACKAGES folder --------------------"
	chgrp opsiadmin .
	chgrp -R opsiadmin $(PACKAGE_DIR)
	chmod g+rx $(PACKAGE_DIR)
	chmod g+r $(PACKAGE_DIR)/*

download:
	@echo "=================================================================="
	@echo "                   Downloading installation packages "
	@echo "=================================================================="
	@for PV in $(PVS); do make 			\
			ONLY_DOWNLOAD="true"		\
			BUILD_PY_VER=$${PV} 		\
	pkgdownload; done

mpimsp: header
	@echo "---------- building MPIMSP package(s) -------------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX=""	 			\
			ORGNAME="MPIMSP" 			\
			ORGPREFIX=""     			\
			STAGE="release"  			\
	build; done

mpimsp_test: header
	@echo "---------- building MPIMSP testing package(s) -----------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX="0_"	 			\
			ORGNAME="MPIMSP" 			\
			ORGPREFIX=""     			\
			STAGE="testing"  			\
	build; done
	
	
o4i: header
	@echo "---------- building O4I package(s) ----------------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX=""    			\
			ORGNAME="O4I"    			\
			ORGPREFIX="o4i_" 			\
			STAGE="release"  			\
	build; done


o4i_test: header
	@echo "---------- building O4I testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX="test_"  		\
			ORGNAME="O4I"    			\
			ORGPREFIX="o4i_" 			\
			STAGE="testing"  			\
	build; done

o4i_test_0: header
	@echo "---------- building O4I testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX="0_"  			\
			ORGNAME="O4I"    			\
			ORGPREFIX="o4i_" 			\
			STAGE="testing"  			\
	build; done

o4i_test_noprefix: header
	@echo "---------- building O4I testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX=""    			\
			ORGNAME="O4I"    			\
			ORGPREFIX="o4i_" 			\
			STAGE="testing"  			\
	build; done
	

dfn: header
	@echo "---------- building DFN package(s) ----------------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX=""    			\
			ORGNAME="O4I"    			\
			ORGPREFIX="dfn_" 			\
			STAGE="release"  			\
			LEGACY="true"               \
			LEGACY_LEVEL="2"            \
	build; done


dfn_test: header
	@echo "---------- building DFN testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX="test_"  		\
			ORGNAME="O4I"    			\
			ORGPREFIX="dfn_" 			\
			STAGE="testing"  			\
			LEGACY="true"               \
			LEGACY_LEVEL="2"            \
	build; done

dfn_test_0: header
	@echo "---------- building DFN testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX="0_"  			\
			ORGNAME="O4I"    			\
			ORGPREFIX="dfn_" 			\
			STAGE="testing"  			\
			LEGACY="true"               \
			LEGACY_LEVEL="2"            \
	build; done

dfn_test_noprefix: header
	@echo "---------- building DFN testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX=""    			\
			ORGNAME="O4I"    			\
			ORGPREFIX="dfn_" 			\
			STAGE="testing"  			\
			LEGACY="true"               \
			LEGACY_LEVEL="2"            \
	build; done


pdf:
	@# requirements for ths script (under Debian/Ubuntu):
	@#    pandoc
	@#    texlive-latex-base
	@#    texlive-fonts-recommended
	@#    texlive-latex-recommended
	@if [ -f "readme.md" ]; then \
		if [ ! -e readme.pdf -o readme.pdf -ot readme.md ]; then \
			echo "* Converting readme.md to readme.pdf"; \
			pandoc "readme.md" \
				--latex-engine=xelatex \
				-f markdown \
				-H DOCU/readme.sty \
				-V linkcolor:blue \
				-V geometry:a4paper \
				-V geometry:margin=30mm \
				-V mainfont="DejaVu Serif" \
				-V monofont="DejaVu Sans Mono" \
				-o "readme.pdf"; \
		else \
			echo "* readme.pdf seems to be up to date"; \
		fi \
	else \
		echo "* Error: readme.md is missing!"; \
	fi


clean_packages: header
	@echo "---------- cleaning packages, checksums and zsync ----------------"
	@rm -f $(PACKAGE_DIR)/*.md5 $(PACKAGE_DIR)/*.opsi $(PACKAGE_DIR)/*.zsync
	
clean: header
	@echo "---------- cleaning  build directory -----------------------------"
	@rm -rf $(BUILD_DIR)	
	
realclean: header clean
	@echo "---------- cleaning  download directory --------------------------"
	@rm -rf $(DL_DIR)	
		
help: header
	@echo "Valid targets: "
	@echo "	download"
	@echo "	mpimsp"
	@echo "	mpimsp_test"
	@echo "	o4i"
	@echo "	o4i_test"
	@echo "	o4i_test_0"
	@echo "	o4i_test_noprefix"	
	@echo "	dfn"
	@echo "	dfn_test"
	@echo "	dfn_test_0"
	@echo "	dfn_test_noprefix"
	@echo "	all_prod"
	@echo "	all_test"
	@echo "	fix_rights"
	@echo "	var_check"
	@echo "	clean"
	@echo "	clean_packages"
	@echo "	download              - download installation archive(s) from vendor"
	@echo "	pdf                   - create PDF from readme.md (req. pandoc)"
	@echo ""
	@echo "Options:"
	@echo "	SPEC=<filename>                 (default: $(DEFAULT_SPEC))"
	@echo "			Use the given alternative spec file."
	@echo "	PYVER=<2|3|2,3|both>            (default: $(DEFAULT_PYVER))"
	@echo "			...build OPSI package for Python version 2 and/or 3"
	@echo "	ALLINC=[true|false]             (default: $(DEFAULT_ALLINC))"
	@echo "			Include software in OPSI package?"
	@echo "	KEEPFILES=[true|false]          (default: $(DEFAULT_KEEPFILES))"
	@echo "			Keep really all previous files from files/?"
	@echo "			If false only files matching this package version are kept."
	@echo "	ARCHIVE_FORMAT=[cpio|tar]       (default: $(DEFAULT_ARCHIVEFORMAT))"
	@echo "	DOWNLOADER=[curl|wget]          (default: $(DEFAULT_DOWNLOADER))"
	@echo "			Prefer to use the given download program for retieving the software"
	@echo "			(Try the other one if the preferred tool could not be found.)"
	@echo ""

build_dirs:
	@echo "* Creating/checking directories"
	@if [ ! -d "$(BUILD_DIR)" ]; then mkdir -p "$(BUILD_DIR)"; fi
	@if [ ! -d "$(BUILD_DIR)/OPSI" ]; then mkdir -p "$(BUILD_DIR)/OPSI"; fi
	@if [ ! -d "$(BUILD_DIR)/CLIENT_DATA" ]; then mkdir -p "$(BUILD_DIR)/CLIENT_DATA"; fi
	@if [ ! -d "$(PACKAGE_DIR)" ]; then mkdir -p "$(PACKAGE_DIR)"; fi

build_md5:
	@echo "* Creating md5sum file for installation archives ($(MD5SUM_FILE))"
	if [ -f "$(BUILD_DIR)/CLIENT_DATA/$(MD5SUM_FILE)" ]; then \
		rm -f $(BUILD_DIR)/CLIENT_DATA/$(MD5SUM_FILE); \
	fi
	grep -i "$(SW_NAME)$(BUILD_PY_VER)-$(SW_VER)-" $(DL_DIR)/$(MD5SUM_FILE)>> $(BUILD_DIR)/CLIENT_DATA/$(MD5SUM_FILE) 
		
copy_from_src:	build_dirs build_md5
	@echo "* Copying files"
	@cp -upL $(SRC_DIR)/CLIENT_DATA/LICENSE  $(BUILD_DIR)/CLIENT_DATA/
	@cp -upL $(SRC_DIR)/CLIENT_DATA/readme.md  $(BUILD_DIR)/CLIENT_DATA/
	@cp -upr $(SRC_DIR)/CLIENT_DATA/bin  $(BUILD_DIR)/CLIENT_DATA/
	@cp -upr $(SRC_DIR)/CLIENT_DATA/*.opsiscript  $(BUILD_DIR)/CLIENT_DATA/
	@cp -upr $(SRC_DIR)/CLIENT_DATA/*.opsiinc     $(BUILD_DIR)/CLIENT_DATA/
	@cp -upr $(SRC_DIR)/CLIENT_DATA/*.opsifunc    $(BUILD_DIR)/CLIENT_DATA/
	$(eval NUM_FILES := $(shell ls -l $(DL_DIR)/$(FILES_MASK) 2>/dev/null | wc -l))
	@if [ "$(ALLINCLUSIVE)" = "true" -a "${LEGACY_LEVEL}" != "3" ]; then \
		echo "  * building batteries included package"; \
		if [ ! -d "$(BUILD_DIR)/CLIENT_DATA/files" ]; then \
			echo "    * creating directory $(BUILD_DIR)/CLIENT_DATA/files"; \
			mkdir -p "$(BUILD_DIR)/CLIENT_DATA/files"; \
		else \
			echo "    * cleanup directory"; \
			rm -f $(BUILD_DIR)/CLIENT_DATA/files/*; \
		fi; \
		echo "    * including install packages"; \
		echo "      * files found   : $(NUM_FILES)"; \
		echo "      * files expected: $(FILES_EXPECTED)"; \
		[ "$(NUM_FILES)" -lt "$(FILES_EXPECTED)" ] && exit 1; \
		for F in `ls $(DL_DIR)/$(FILES_MASK)`; do echo "      + $$F"; ln $$F $(BUILD_DIR)/CLIENT_DATA/files/; done; \
		ls -l $(BUILD_DIR)/CLIENT_DATA/files/ ;\
	else \
		echo "    * removing $(BUILD_DIR)/CLIENT_DATA/files"; \
		rm -rf $(BUILD_DIR)/CLIENT_DATA/files ; \
	fi
	@if [ -d "$(SRC_DIR)/CLIENT_DATA/custom" ]; then  cp -upr $(SRC_DIR)/CLIENT_DATA/custom     $(BUILD_DIR)/CLIENT_DATA/ ; fi
	@if [ -d "$(SRC_DIR)/CLIENT_DATA/files" ];  then  cp -upr $(SRC_DIR)/CLIENT_DATA/files      $(BUILD_DIR)/CLIENT_DATA/ ; fi
	@if [ -d "$(SRC_DIR)/CLIENT_DATA/images" ];  then  \
		mkdir -p "$(BUILD_DIR)/CLIENT_DATA/images"; \
		cp -up $(SRC_DIR)/CLIENT_DATA/images/*.png  $(BUILD_DIR)/CLIENT_DATA/images/; \
	fi
	@if [ -f  "$(SRC_DIR)/OPSI/control" ];  then cp -up $(SRC_DIR)/OPSI/control   $(BUILD_DIR)/OPSI/; fi
	@if [ -f  "$(SRC_DIR)/OPSI/preinst" ];  then cp -up $(SRC_DIR)/OPSI/preinst   $(BUILD_DIR)/OPSI/; fi 
	@if [ -f  "$(SRC_DIR)/OPSI/postinst" ]; then cp -up $(SRC_DIR)/OPSI/postinst  $(BUILD_DIR)/OPSI/; fi

build_json:
	@if [ ! -f "$(SPEC)" ]; then echo "*Error* spec file not found: \"$(SPEC)\""; exit 1; fi
	@if [ ! -d "$(BUILD_DIR)" ]; then mkdir -p "$(BUILD_DIR)"; fi
	@$(if $(filter $(STAGE),testing), $(eval TESTING :="true"), $(eval TESTING := "false"))
	@$(if $(filter $(ORGPREFIX),dfn_), $(eval LEGACY :="true"), $(eval LEGACY := "false"))
	@echo "* Legacy build: $(LEGACY)"
	@echo "* Creating $(BUILD_JSON)"
	@rm -f $(BUILD_JSON)
	@echo "{\n\
              \"M_TODAY\"        : \"$(TODAY)\",\n\
              \"M_STAGE\"        : \"$(STAGE)\",\n\
              \"M_ORGNAME\"      : \"$(ORGNAME)\",\n\
              \"M_ORGPREFIX\"    : \"$(ORGPREFIX)\",\n\
              \"M_TESTPREFIX\"   : \"$(TESTPREFIX)\",\n\
              \"M_PY_VER\"       : \"$(BUILD_PY_VER)\",\n\
              \"M_KEEPFILES\"    : \"$(KEEPFILES)\",\n\
              \"M_LEGACY\"       : \"$(LEGACY)\",\n\
              \"M_LEGACY_LEVEL\" : \"$(LEGACY_LEVEL)\",  \
              \"M_ALLINC\"       : \"$(ALLINCLUSIVE)\",\n\
              \"M_DOWNLOADER\"   : \"$(DOWNLOADER)\",\n\
              \"M_TESTING\"      : \"$(TESTING)\"\n}"      > $(TMP_FILE)
	@cat  $(TMP_FILE)
	@$(MUSTACHE) $(TMP_FILE) $(SPEC)	 > $(BUILD_JSON)
	@rm -f $(TMP_FILE)

pkgdownload: build_json
	@echo "**Debug** [ALLINC=$(ALLINCLUSIVE)]  [ONLY_DOWNLOAD=$(ONLY_DOWNLOAD)]"
	@if [ "$(ALLINCLUSIVE)" = "true" -o  $(ONLY_DOWNLOAD) = "true" ]; then \
		rm -f $(DOWNLOAD_SH) ;\
		$(MUSTACHE) $(BUILD_JSON) $(DOWNLOAD_SH_IN) > $(DOWNLOAD_SH) ;\
		chmod +x $(DOWNLOAD_SH) ;\
		if [ ! -d "$(DL_DIR)" ]; then mkdir -p "$(DL_DIR)"; fi ;\
		DEST_DIR=$(DL_DIR) $(DOWNLOAD_SH) ;\
	fi

	
build: pkgdownload pdf clean copy_from_src
	@make build_json
	
	for F in $(FILES_OPSI_IN); do \
		echo "* Creating OPSI/$$F"; \
		rm -f $(BUILD_DIR)/OPSI/$$F; \
		${MUSTACHE} $(BUILD_JSON) $(SRC_DIR)/OPSI/$$F.in > $(BUILD_DIR)/OPSI/$$F; \
	done

	for E in txt md pdf; do \
		if [ -e readme.$$E ]; then \
			echo "Copying additional file: readme.$$E"; \
			cp -f readme.$$E $(BUILD_DIR)/OPSI/; \
		fi; \
	done

	if [ -e $(BUILD_DIR)/OPSI/control -a -e changelog ]; then \
		if [ -n "$(CHANGELOG_TGT)" ]; then \
			echo "* Using separate CHANGELOG file."; \
			echo "The logs were moved to $(CHANGELOG_TGT)" >> $(BUILD_DIR)/OPSI/control; \
			cp -f changelog $(BUILD_DIR)/OPSI/$(CHANGELOG_TGT); \
		else \
			echo "* Including changelogs in CONTROL file."; \
			cat changelog >> $(BUILD_DIR)/OPSI/control; \
		fi; \
	fi

	for F in $(FILES_IN); do \
		echo "* Creating CLIENT_DATA/$$F"; \
		rm -f $(BUILD_DIR)/CLIENT_DATA/$$F; \
		${MUSTACHE} $(BUILD_JSON) $(SRC_DIR)/CLIENT_DATA/$$F.in > $(BUILD_DIR)/CLIENT_DATA/$$F; \
	done
	chmod +x $(BUILD_DIR)/CLIENT_DATA/*.sh

	@echo "* OPSI Archive Format: $(BUILD_FORMAT)"
	@echo "* Building OPSI package"
	if [ -z $(CUSTOMNAME) ]; then \
		cd "$(CURDIR)/$(PACKAGE_DIR)" && $(OPSI_BUILDER) -F $(BUILD_FORMAT) -k -m $(CURDIR)/$(BUILD_DIR); \
	else \
		cd $(CURDIR)/$(BUILD_DIR) && \
		for D in OPSI CLIENT_DATA SERVER_DATA; do \
			if [ -d "$$D" ] ; then mv $$D $$D.$(CUSTOMNAME); fi; \
		done && \
		cd "$(CURDIR)/$(PACKAGE_DIR)" && $(OPSI_BUILDER) -F $(BUILD_FORMAT) -k -m $(CURDIR)/$(BUILD_DIR) -c $(CUSTOMNAME); \
	fi; \
	cd $(CURDIR)


all_test:  header mpimsp_test o4i_test_0 dfn_test dfn_test_0

all_prod : header mpimsp o4i dfn

all : header download mpimsp o4i dfn
