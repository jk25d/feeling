http://code.google.com/p/maven-android-plugin/wiki/GettingStarted

# jdk 1.6+
# android sdk http://developer.android.com/sdk/index.html
# maven 3.1.1+
# ANDROID_HOME, $ANDROID_HOME/platform-tools, $ANDROID_HOME/tools

# SDK Manager.exe
# install API 16

# configure eclipse
--launcher.XXMaxPermSize
1024m
-XX:MaxPermSize=1024M
-Xms512m
-Xmx2048m

# run eclipse
# setup Android Virtual Device Manager
# create Default AVD
android avd

# create maven project
mvn archetype:generate -DarchetypeArtifactId=android-quickstart -DarchetypeGroupId=de.akquinet.android.archetypes -DarchetypeVersion=1.0.11 -DgroupId=com.sds -DartifactId=android-test

# build
mvn clean install

# run emulator
mvn android:emulator-start

# deploy app to emulator
mvn android:deploy


phonegap
--------

# http://cordova.apache.org/docs/en/3.1.0/guide_cli_index.md.html#The%20Command-line%20Interface

# install ant and set ant to PATH

npm install -g cordova

# if hava unauthorized issue, do follows
# set NODE_TLS_REJECT_UNAUTHORIZED=0
# npm config set strict-ssl false
cordova create hello com.example.hello HelloWorld

cordova platform add android

cordova build

# run emulator
android avd

# deploy
cordova emulate

# add plubins
cordova plugin add org.apache.cordova.device-motion
cordova plugin add org.apache.cordova.device-orientation
cordova plugin add org.apache.cordova.geolocation



