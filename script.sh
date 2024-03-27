#!/bin/bash
FFVERSION=$1
FENIXVERSION=$2
VARIANT=$3


echo "Blocking about:config"
#cp ./$VARIANT-store/config.css ./$VARIANT-build/firefox-$FFVERSION/mobile/android/themes/geckoview/

echo "Converting BlueCoat Certificate from .crt to .der"
openssl x509 -inform PEM -in ./$VARIANT-store/CertEmulationCA.crt -out ./$VARIANT-store/CertEmulationCA.der -outform DER
echo "Converting MobiFilter Certificate from .crt to .der"
openssl x509 -inform PEM -in ./$VARIANT-store/mobifilter_rootCA.crt -out ./$VARIANT-store/mobifilter_rootCA.der -outform DER
echo "Converting Cloudveil Certificate from .crt to .der"
openssl x509 -inform PEM -in ./$VARIANT-store/cloudveil_blue_rootCA.crt -out ./$VARIANT-store/cloudveil_blue_rootCA.der -outform DER

echo "copying der file to nss folder "
cp ./$VARIANT-store/CertEmulationCA.der ./$VARIANT-build/firefox-$FFVERSION/security/nss/lib/ckfw/builtins/
cp ./$VARIANT-store/mobifilter_rootCA.der ./$VARIANT-build/firefox-$FFVERSION/security/nss/lib/ckfw/builtins/
cp ./$VARIANT-store/cloudveil_blue_rootCA.der ./$VARIANT-build/firefox-$FFVERSION/security/nss/lib/ckfw/builtins/

echo "Switching Directory"
cd ./$VARIANT-build/firefox-$FFVERSION/security/nss/lib/ckfw/builtins/

echo "Adding in custom certificate"
#/usr/local/Cellar/nss/3.20/bin/addbuiltin -n "CloudVeil" -t "CT,C,C" < ./CertEmulationCA.der >> ./certdata.txt
nss-addbuiltin -n "CloudVeil" -t "CT,C,C" < ./CertEmulationCA.der >> ./certdata.txt
#/usr/local/Cellar/nss/3.20/bin/addbuiltin -n "MobiFilter" -t "CT,C,C" < ./mobifilter_rootCA.der  >> ./certdata.txt
nss-addbuiltin -n "MobiFilter" -t "CT,C,C" < ./mobifilter_rootCA.der  >> ./certdata.txt
nss-addbuiltin -n "CloudVeilBlue" -t "CT,C,C" < ./cloudveil_blue_rootCA.der  >> ./certdata.txt


echo "I'm currently running here: "
pwd

read -p "Press [Enter] key continue.."
cd ../../../../../../../
pwd

echo "Applying app name and id"
sed -i -e 's/applicationId "org.mozilla"/applicationId "org.cloudveil.android_browser"/g' ./$VARIANT-build/fenix-$FENIXVERSION/fenix/app/build.gradle
sed -i -e 's/applicationIdSuffix ".firefox"//g' ./$VARIANT-build/fenix-$FENIXVERSION/fenix/app/build.gradle


echo "Writing proxy settings"
cd ./$VARIANT-build/firefox-$FFVERSION/modules/libpref/init/
pwd
read -p "Press [Enter] key continue.."sure

sed -i -e 's/pref("network.proxy.type",                  5);/pref("network.proxy.type",                  2);/g' all.js
sed -i -e 's/pref("network.proxy.http_port",             0);/pref("network.proxy.http_port",             12763);/g' all.js
sed -i -e 's/pref("network.proxy.http",                  "");/pref("network.proxy.http",                  "proxy1.cloudveil.org");/g' all.js
sed -i -e 's/pref("network.proxy.ssl",                   "");/pref("network.proxy.ssl",                   "proxy1.cloudveil.org");/g' all.js
sed -i -e 's/pref("network.proxy.ssl_port",              0);/pref("network.proxy.ssl_port",              12763);/g' all.js
sed -i -e 's/pref("network.proxy.no_proxies_on",         "localhost, 127.0.0.1");/pref("network.proxy.no_proxies_on",         "localhost,127.0.0.1,10.0.0.0\/8,172.16.0.0\/12,192.168.0.0\/16");/g' all.js
sed -i -e 's/pref("network.proxy.autoconfig_url", "");/pref("network.proxy.autoconfig_url", "https:\/\/api.mobifilter.net\/pac\/cloudveil\/android-browser-2022.pac");/g' all.js
sed -i -e 's/pref("network.proxy.autoconfig_retry_interval_min", 5);/pref("network.proxy.autoconfig_retry_interval_min", 5);/g' all.js
sed -i -e 's/pref("network.proxy.autoconfig_retry_interval_max", 300);/pref("network.proxy.autoconfig_retry_interval_max", 7200);/g' all.js
sed -i -e 's/pref("signon.autologin.proxy",              false);/pref("signon.autologin.proxy",              true);/g' all.js

sed -i -e 's/pref("network.proxy.failover_timeout",      1800);/pref("network.proxy.failover_timeout",      15);/g' all.js
sed -i -e 's/pref("network.stricttransportsecurity.preloadlist", true);/pref("network.stricttransportsecurity.preloadlist", false);/g' all.js

echo 'pref("network.proxy.type", 2);' >> all.js
echo 'pref("general.config.obscure_value", 0);' >> all.js
echo 'pref("general.config.filename", "http://cloudveil.mobifilter.net/firefox.cfg");' >> all.js
echo 'pref("security.cert_pinning.enforcement_level", 0);' >> all.js

cd ../../../../
echo "Current folder: "
pwd
sed -i -z -r -e 's/<receiver android:name="org.mozilla.gecko.search.SearchWidgetProvider">[^<]+<intent-filter>[^<]+<action android:name="android.appwidget.action.APPWIDGET_UPDATE" \/>[^<]+<\/intent-filter>[^<]+<meta-data[^a]+android:name="android.appwidget.provider"[^a]+android:resource="@xml\/search_widget_info" \/>[^<]+<\/receiver>//g' ./fenix-$FENIXVERSION/fenix/app/src/main/AndroidManifest.xml

read -p "Press [Enter] key to disable certificate pinning..."


echo "Disabling certificate pinning."
sed -i -e 's/pref("security.cert_pinning.enforcement_level", 1);/pref("security.cert_pinning.enforcement_level", 0);/g'  ./firefox-$FFVERSION/browser/app/profile/firefox.js
sed -i -e 's/pref("security.cert_pinning.enforcement_level", 1);/pref("security.cert_pinning.enforcement_level", 0);/g'  ./firefox-$FFVERSION/mobile/android/app/mobile.js
