#!/bin/sh
#BUILDSTYLE="\"Deployment - Tiger - G4\""
BUILDCONFIGURATION="\"Deployment\""
export BUILDCONFIGURATION

make $@
make -C Extras/GrowlMail $@
make -C Extras/GrowlSafari $@
make -C Extras/GrowlDict $@
make -C Extras/growlnotify $@
make -C Extras/HardwareGrowler $@
make -C Extras/growlctl $@
make -C Extras/GrowlWidget $@
#make -C Extras/GrowlImporter $@
#make -C Extras/GrowlAction $@
make -C Extras/GrowlTunes $@
make -C Extras/Rawr-jour $@
make -C Extras/Feed $@

