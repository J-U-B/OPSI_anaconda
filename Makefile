############################################################
# OPSI package Makefile (ANACONDA)
# Version: 2.4.1
# Jens Boettge <boettge@mpi-halle.mpg.de>
# 2018-10-25 14:02:34 +0200
############################################################

.PHONY: header clean mpimsp mpimsp_test o4i o4i_test dfn dfn_test all_test all_prod all help download dummy_build
.DEFAULT_GOAL := help

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
SPEC ?= spec.json
ifeq ($(shell test -f $(SPEC) && echo OK),OK)
    # $(info [INFO] spec file found: $(SPEC))
else
    $(error [ERROR] spec file NOT found: $(SPEC))
endif


### Which Python flavour 2, 3 or both
PYVER ?= both
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


PYSTACHE = ./SRC/SCRIPTS/pystache_opsi.py
BUILD_JSON = $(BUILD_DIR)/build.json
CONTROL_IN = $(SRC_DIR)/OPSI/control.in
CONTROL = $(BUILD_DIR)/OPSI/control
DOWNLOAD_SH_IN = ./SRC/CLIENT_DATA/product_downloader.sh.in
DOWNLOAD_SH = $(PWD)/product_downloader.sh
OPSI_FILES := control preinst postinst
FILES_IN := $(basename $(shell (cd $(SRC_DIR)/CLIENT_DATA; ls *.in 2>/dev/null)))
FILES_OPSI_IN := $(basename $(shell (cd $(SRC_DIR)/OPSI; ls *.in 2>/dev/null)))
TODAY := $(shell date +"%Y-%m-%d")

### spec file:
SPEC ?= spec.json
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
ALLINC ?= false
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
KEEPFILES ?= false
KEEPFILES_SEL := "[true] [false]"
KFX := $(firstword $(KEEPFILES))
override KFX := $(shell echo $(KFX) | tr A-Z a-z)
override KFX := $(findstring [$(KFX)],$(KEEPFILES_SEL))
ifeq (,$(KFX))
	override KEEPFILES := false
else
	override KEEPFILES := $(shell echo $(KFX) | tr -d '[]')
endif

ARCHIVE_FORMAT ?= cpio
ARCHIVE_TYPES :="[cpio] [tar]"
AFX := $(firstword $(ARCHIVE_FORMAT))
AFY := $(shell echo $(AFX) | tr A-Z a-z)

ifeq (,$(findstring [$(AFY)],$(ARCHIVE_TYPES)))
	BUILD_FORMAT = cpio
else
	BUILD_FORMAT = $(AFY)
endif


leave_err:
	exit 1

var_test:
	@echo "=================================================================="
	@echo "* Software Name         : [$(SW_NAME)]"
	@echo "* Software Version      : [$(SW_VER)]"
	@echo "* Package Build         : [$(SW_BUILD)]"
	@echo "* SPEC file             : [$(SPEC)]"
	@echo "* Batteries included    : [default: $(ALLINC)] --> [$(ALLINCLUSIVE)]"
	@echo "* Python version(s)     : [default: $(PYVER)] --> [$(PKGX)] --> [$(PKGY)] --> [$(PKGZ)] --> [$(PY_VER)]"
	@echo "		* BUILD_PY_VER = $(BUILD_PY_VER)"
	@echo "		* PVS = $(PVS)"
	@echo "* 64 bit only?          : [$(SW_ONLY64)]"
	@echo "* Custom Name           : [$(CUSTOMNAME)]"
	@#echo "* OPSI Archive Types    : [$(ARCHIVE_TYPES)]"
	@echo "* OPSI Archive Format   : [default: $(ARCHIVE_FORMAT)] --> $(BUILD_FORMAT)"
	@echo "* Templates OPSI        : [$(FILES_OPSI_IN)]"
	@echo "* Templates CLIENT_DATA : [$(FILES_IN)]"
	@echo "* Files Mask            : [$(FILES_MASK)]"
	@echo "* Files expected        : [$(FILES_EXPECTED)]"
    @echo "* Keep files            : [$(KEEPFILES)]"
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

header: var_test
	@echo "=================================================================="
	@echo "                      Building OPSI package(s)"
	@echo "=================================================================="

fix_rights: header
	@echo "---------- setting rights for PACKAGES folder --------------------"
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
			ORGNAME="DFN"    			\
			ORGPREFIX="dfn_" 			\
			STAGE="release"  			\
	build; done


dfn_test: header
	@echo "---------- building DFN testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX="test_"  		\
			ORGNAME="DFN"    			\
			ORGPREFIX="dfn_" 			\
			STAGE="testing"  			\
	build; done

dfn_test_0: header
	@echo "---------- building DFN testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX="0_"  			\
			ORGNAME="DFN"    			\
			ORGPREFIX="dfn_" 			\
			STAGE="testing"  			\
	build; done

dfn_test_noprefix: header
	@echo "---------- building DFN testing package(s) --------------------------"
	@for PV in $(PVS); do make 			\
			BUILD_PY_VER=$${PV} 		\
			TESTPREFIX=""    			\
			ORGNAME="DFN"    			\
			ORGPREFIX="dfn_" 			\
			STAGE="testing"  			\
	build; done

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
	@echo "	clean"
	@echo "	clean_packages"
	@echo ""
	@echo "Options:"
	@echo "	SPEC=<filename>                 (default: spec.json)"
	@echo "			Use the given alternative spec file."
	@echo "	PYVER=<2|3|2,3|both>            (default: both)"
	@echo "			...build OPSI package for Python version 2 and/or 3"
	@echo "	ALLINC=[true|false]             (default: false)"
	@echo "			Include software in OPSI package?"
	@echo "	KEEPFILES=[true|false]          (default: false)"
	@echo "			Keep really all previous files from files/?"
	@echo "			If false only files matching this package version are kept."
	@echo "	ARCHIVE_FORMAT=[cpio|tar]       (default: cpio)"
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
    # @cp -upr $(SRC_DIR)/CLIENT_DATA/*.opsifunc    $(BUILD_DIR)/CLIENT_DATA/
	$(eval NUM_FILES := $(shell ls -l $(DL_DIR)/$(FILES_MASK) 2>/dev/null | wc -l))
	@if [ "$(ALLINCLUSIVE)" = "true" ]; then \
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
	@echo "* Creating $(BUILD_JSON)"
	@rm -f $(BUILD_JSON)
	$(PYSTACHE) $(SPEC)   "{ \"M_TODAY\"      : \"$(TODAY)\",         \
	                         \"M_STAGE\"      : \"$(STAGE)\",         \
	                         \"M_ORGNAME\"    : \"$(ORGNAME)\",       \
	                         \"M_ORGPREFIX\"  : \"$(ORGPREFIX)\",     \
	                         \"M_TESTPREFIX\" : \"$(TESTPREFIX)\",    \
	                         \"M_PY_VER\"     : \"$(BUILD_PY_VER)\",  \
	                         \"M_KEEPFILES\"  : \"$(KEEPFILES)\",     \
	                         \"M_ALLINC\"     : \"$(ALLINCLUSIVE)\",  \
	                         \"M_TESTING\"    : \"$(TESTING)\"        }" > $(BUILD_JSON)

pkgdownload: build_json
	@echo "**Debug** [ALLINC=$(ALLINCLUSIVE)]  [ONLY_DOWNLOAD=$(ONLY_DOWNLOAD)]"
	@if [ "$(ALLINCLUSIVE)" = "true" -o  $(ONLY_DOWNLOAD) = "true" ]; then \
		rm -f $(DOWNLOAD_SH) ;\
		$(PYSTACHE) $(DOWNLOAD_SH_IN) $(BUILD_JSON) > $(DOWNLOAD_SH) ;\
		chmod +x $(DOWNLOAD_SH) ;\
		if [ ! -d "$(DL_DIR)" ]; then mkdir -p "$(DL_DIR)"; fi ;\
		DEST_DIR=$(DL_DIR) $(DOWNLOAD_SH) ;\
	fi

	
build: pkgdownload clean copy_from_src
	@make build_json
	
	for F in $(FILES_OPSI_IN); do \
		echo "* Creating OPSI/$$F"; \
		rm -f $(BUILD_DIR)/OPSI/$$F; \
		${PYSTACHE} $(SRC_DIR)/OPSI/$$F.in $(BUILD_JSON) > $(BUILD_DIR)/OPSI/$$F; \
	done	
	
	if [ -e $(BUILD_DIR)/OPSI/control -a -e changelog ]; then \
		cat changelog >> $(BUILD_DIR)/OPSI/control; \
	fi
	
	for F in $(FILES_IN); do \
		echo "* Creating CLIENT_DATA/$$F"; \
		rm -f $(BUILD_DIR)/CLIENT_DATA/$$F; \
		${PYSTACHE} $(SRC_DIR)/CLIENT_DATA/$$F.in $(BUILD_JSON) > $(BUILD_DIR)/CLIENT_DATA/$$F; \
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


all_test:  header mpimsp_test o4i_test dfn_test dfn_test_0

all_prod : header mpimsp o4i dfn

all : header download mpimsp o4i dfn
