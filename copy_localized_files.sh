#!/bin/sh

CELESTIA_MAC_ROOT=$SRCROOT/CelestiaApp/Resources
CELESTIA_LOCALIZATION_REPO_ROOT=$SRCROOT/../CelestiaLocalization
CELESTIA_LOCALIZATION_MAC_ROOT=$CELESTIA_LOCALIZATION_REPO_ROOT/mac

rsync -rv --quiet $CELESTIA_LOCALIZATION_MAC_ROOT/* $CELESTIA_MAC_ROOT
