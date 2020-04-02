BUNDLE_IDENTIFIER=space.celestia.Celestia
DISTRIBUTION_FILE=$APPCENTER_OUTPUT_DIRECTORY/CelestiaApp_distribution.zip
xcrun altool --notarize-app --primary-bundle-id $BUNDLE_IDENTIFIER --username $AC_USERNAME --password $AC_PASSWORD -f $DISTRIBUTION_FILE
