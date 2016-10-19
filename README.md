# react-native-photos-framework

`npm i react-native-photos-framework --save`

Load photos and albums from CameraRoll and iCloud.
Uses Apples photos framework.

React Native comes with it's own CameraRoll library.
This however uses ALAssetLibrary which is deprecated from Apple
and can only load photos and videos stored on the users device.
This is not what your user expects today. Most of users photos
today live on iCloud and these won't show if you use ALAssetLibrary.

If you use this library/Photos framework you can display the users local resources and the users iCloud resources.

~~~~

~~~~
