##########################
### Versioning:
###   * Set VERSION and BETA below. BETA should be TRUE or FALSE.
#
VERSION=1.0
BETA=TRUE

#
#########################
#
# No changes should be needed below this line
#
#########################
RELEASE_FILENAME=MacCode-$(VERSION)
RELEASE_NAME="MacCode $(VERSION)"

SRC_DIR=`pwd`/..
BUILD_DIR=build
SOURCE_DIR=$(BUILD_DIR)/Source
#SDK_DIR=$(BUILD_DIR)/SDK
BUILDSTYLE=Deployment
BUILDFLAGS="BUILDCONFIGURATION=$(BUILDSTYLE)"
PRODUCT_DIR=$(shell defaults read com.apple.Xcode PBXProductDirectory 2> /dev/null)
ifeq ($(strip $(PRODUCT_DIR)),)
	MACCODE_BUILD_DIR=$(SRC_DIR)/build/$(BUILDSTYLE)
else
	TARGET_BUILD_DIR=$(PRODUCT_DIR)/$(BUILDSTYLE)
endif
#PACKAGE_MAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
ART_DIR=Artwork

#########################

.PHONY: all compile clean release

all: compile release
all-withlocalchanges: compile release

#assertnochanges:
#	if [[ 0 -ne `svn st $(SRC_DIR) | wc -l` ]]; then \
		echo 'You have local changes. Please do not build releases from an unclean checkout. You must revert the changes, commit them, or check out another working copy and build from that.' 1>&2; \
		exit 1; \
#	fi
#assertnoconflicts:
#	if [[ 0 -ne `svn st $(SRC_DIR) | egrep '^C' | wc -l` ]]; then \
		echo 'You have conflicts in your checkout. You will not be able to build until these are resolved. Also, remember that even after you have fixed all conflict marks, you must use "svn resolved"; otherwise, svn will still believe the files are conflicted.' 1>&2; \
		exit 2; \
#	fi


#compile:
#	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)
#	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlMail
#	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlSafari
#	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/growlnotify
#	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/HardwareGrowler
#	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlTunes

clean:
	rm -rf $(BUILD_DIR)


release:
#	@# clean build directory
	rm -rf $(BUILD_DIR)
	mkdir $(BUILD_DIR)
	mkdir $(SOURCE_DIR)
	
	@# copy webloc files
	cp -R "MacCode.webloc" $(BUILD_DIR)
	
	@# hide extensions of webloc files
	/Developer/Tools/SetFile -a E $(BUILD_DIR)/*.webloc
	
	
	
	cp -R $(SRC_DIR)/Utilities $(BUILD_DIR)/Source
	cp -R $(SRC_DIR)/Snippets $(BUILD_DIR)/Source
	cp -R $(SRC_DIR)/pxmLib $(BUILD_DIR)/Source
	
	
	@# delete svn and backup files
	find $(BUILD_DIR)/source \( -name build -or -name .svn -or -name "*~.nib" \) -type d -exec rm -rf {} \; -prune
	find $(BUILD_DIR)/source \( -name "*~" -or -name .DS_Store \) -type f -delete

	
#	@# optimize nib files, making them uneditable, for releases only
#ifeq ($(BETA),FALSE)
#	find $(BUILD_DIR) \( -name classes.nib -or -name info.nib \) -type f -delete
#endif

	@# make MacCode disk image
	mkdir $(BUILD_DIR)/.background
	cp $(SRC_DIR)/images/dmg/maccodeDMGBackground.png $(BUILD_DIR)/.background
	./ensureCustomIconsExtracted $(ART_DIR)
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_FILENAME).dmg $(BUILD_DIR) $(RELEASE_NAME) maccode_dmg_builder.applescript $(ART_DIR)
	
#	@# make SDK disk image
#	mkdir $(SDK_DIR)/.background
#	cp $(SRC_DIR)/images/dmg/growlSDK.png $(SDK_DIR)/.background
#	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_FILENAME)-SDK.dmg $(SDK_DIR) $(RELEASE_SDK_NAME) dmg_sdk.applescript
	
	@echo Build finished
