# react-native-photos-framework [![Build Status](https://travis-ci.org/olofd/react-native-photos-framework.svg?branch=master)](https://travis-ci.org/olofd/react-native-photos-framework) [![npm version](https://badge.fury.io/js/react-native-photos-framework.svg)](https://badge.fury.io/js/react-native-photos-framework)

###Example project
####NOTE: This is not a GUI-component, it's an API. The example project just shows off some of the the capabilities of this API.
![](https://media.giphy.com/media/3o6Ztqdc8OF3FAgAiQ/source.gif)

###Description
Load photos/videos and more from CameraRoll and iCloud.
Uses Apples photos framework.

React Native comes with it's own CameraRoll library.
This however uses ALAssetLibrary which is a deprecated API from Apple
and can only load photos and videos stored on the users device.
This is not what your user expects today. Most users photos live on iCloud and these won't show if you use ALAssetLibrary.

If you use this library (Photos framework) you can display the users local resources and the users iCloud resources.

###Installation:
`npm i react-native-photos-framework --save && react-native link react-native-photos-framework`

NOTE: When running `npm install` this library will try to automatically add `NSPhotoLibraryUsageDescription` to your Info.plist.
Check that it is there after the install or update it's value from the default:
`Using photo library to select pictures`
 (Will not do anything if you have already defined this key in Info.plist)

##Library (Top level):

##Static methods:

###authorizationStatus
~~~~
  RNPhotosFramework.authorizationStatus().then(() => {
  });
~~~~

Signature: `RNPhotosFramework.authorizationStatus() : Promise<{status : string, isAuthorized : boolean}>`.
Fetches the current authorization-status.
NOTE: You can receive the following statuses :
* `notDetermined` //Before user has granted permission,
* `restricted` //User is restricted by policy, cannot use Photos,
* `denied` //User has denied permission,
* `authorized` //User has granted permission

###requestAuthorization
~~~~
  RNPhotosFramework.requestAuthorization().then((statusObj) => {
    if(statusObj.isAuthorized) {
      ...start using the library.
    }
  });
~~~~

Signature: `RNPhotosFramework.requestAuthorization() : Promise<{status : string, isAuthorized : boolean}>`.
This will prompt the user to grant access to the user library at first start.
If you do not call this method explicitly before using any of the other functions in this library, the grant-access-dialog will appear for the user automatically at the first function-call into the library. But only one function-call can automatically
trigger this dialog, so if another call comes into Photos Framework before the user has granted you access, that function-call will fail. Therefore I urge you to call this method explicitly before you start using the rest of the library to not experience unexpected behaviour.
NOTE: You do not have to first check the authorizationStatus before calling this. If the user has granted access before, this will just return authorized-status.
NOTE: See available statuses in doc. about: `authorizationStatus`

##Working with Content:
##### `fetchOptions`
fetchOptions is a query-object which can be sent both when fetching albums with
`getAlbums` and when fetching assets with `getAssets`. Below you can see the available options
for fetchOptions. You can also read Apple's documentation around [PHFetchOptions here](https://developer.apple.com/reference/photos/phfetchoptions).
(Many of the args map one-to-one with native data structures.)

| Prop  | Default  | Type | Description |
| :------------ |:---------------:| :---------------:| :-----|
| mediaTypes (Only for `getAssets`) | - | `array<string>` | Defines what mediaType the asset should be. Array combined with OR-operator. e.g. ['image', 'video'] will return both photos and videos. Converted in Native to PHAssetMediaType. Accepted values: `image`, `video`, `audio`, `unknown` |
| mediaSubTypes (Only for `getAssets`) | - | `array<string>` | Defines what subtype the asset should be. Array combined with OR-operator. e.g. ['photoPanorama', 'photoHDR'] will return both panorama and HDR-assets. Converted in Native to PHAssetMediaSubtype. Accepted enum-values: `none`, `photoPanorama`, `photoHDR`, `photoScreenshot`, `photoLive`, `videoStreamed`, `videoHighFrameRate`, `videoTimeLapse` (mediaTypes and mediaSubTypes are combined with AND-operator) |
| sourceTypes (Only for `getAssets`) | - | `array<string>` | Defines where the asset should come from originally. Array combined with OR-operator. Converted in Native to PHAssetSourceType. Accepted enum-values: `none`, `userLibrary`, `cloudShared`, `itunesSynced`. |
| includeHiddenAssets | false | `boolean` | A Boolean value that determines whether the fetch result includes assets marked as hidden. |
| includeAllBurstAssets | false | `boolean` | A Boolean value that determines whether the fetch result includes all assets from burst photo sequences. |
| fetchLimit | 0 | `number` | The maximum number of objects to include in the fetch result. Remember to not use this in the wrong way combined with startIndex and endIndex. 0 means unlimited. |
| sortDescriptors | - | `array<{key : <string>, ascending : <boolean>}>` |  Multiple sortDescriptors which decide how the result should be sorted. |

# Retrieving Assets (photos/videos/audio):
~~~~
import RNPhotosFramework from 'react-native-photos-framework';

  RNPhotosFramework.getAssets({
    //Example props below. Many optional.
    // You can call this function multiple times providing startIndex and endIndex as
    // pagination.
    startIndex: 0,
    endIndex: 100,

    fetchOptions : {
      // Media types you wish to display. See table below for possible options. Where
      // is the image located? See table below for possible options.
      sourceTypes: ['userLibrary'],

      sortDescriptors : [
        {
          key: 'creationDate',
          ascending: true,
        }
      ]
    }
  }).then((response) => console.log(response.assets));

~~~~

###### Props to `getAssets`

| Prop  | Default  | Type | Description |
| :------------ |:---------------:| :---------------:| :-----|
| fetchOptions | - | `object` | See above. |
| startIndex | 0 | `number` | startIndex-offset for fetching |
| endIndex | 0 | `number` | endIndex-offset stop for fetching |
| includeMetadata | false | `boolean` | Include a lot of metadata about the asset (See below). You can also choose to get this metaData at a later point by calling asset.getMetadata (See below) |
| includeResourcesMetadata | false | `boolean` | Include metadata about the orginal resources that make up the asset. Like type and original filename. You can also choose to get this metaData at a later point by calling asset.getResourcesMetadata. You can also choose to get this metaData at a later point by calling asset.getResourcesMetadata (See below) |
| prepareForSizeDisplay | - | `Rect(width, height)` | The size of the image you soon will display after running the query. This is highly optional and only there for optimizations of big lists. Prepares the images for display in Photos by using PHCachingImageManager |
| prepareScale | 2.0 | `number` | The scale to prepare the image in. |
| assetDisplayStartToEnd | false | `boolean` | Retrieves assets from the beginning of the library when set to true. Using this sorting option preserves the native order of assets as they are viewed in the Photos app.  |
| assetDisplayBottomUp | false | `boolean` | Used to arrange assets from the bottom to top of screen when scrolling up to view paginated results. |

###Example of asset response with `includeMetadata : true`
~~~~
creationDate : 1466766146
duration : 17.647 (video)
width : 1920
height : 1080
isFavorite : false
isHidden : false
localIdentifier : "3D5E6260-2B63-472E-A38A-3B543E936E8C/L0/001"
location : Object
mediaSubTypes : null
mediaType : "video"
modificationDate : 1466766146
sourceType : "userLibrary"
uri : "pk://3D5E6260-2B63-472E-A38A-3B543E936E8C/L0/001"
~~~~

# Retrieving albums and enumerating their assets:
~~~~
  RNPhotosFramework.getAlbums({
    type: 'album',
    subType: 'any',
    assetCount: 'exact',
    fetchOptions: {
      sortDescriptors : [
        {
          key: 'title',
          ascending: true
        }
      ],
      includeHiddenAssets: false,
      includeAllBurstAssets: false
    },
    //When you say 'trackInsertsAndDeletes or trackChanges' for an albums query result,
    //They will be cached and tracking will start.
    //Call queryResult.stopTracking() to stop this. ex. on componentDidUnmount
    trackInsertsAndDeletes : true,
    trackChanges : false

  }).then((queryResult) => {
    const album = queryResult.albums[0];
    return album.getAssets({
      //The fetch-options from the outer query will apply here, if we get
      startIndex: 0,
      endIndex: 10,
      //When you say 'trackInsertsAndDeletes or trackAssetsChange' for an albums assets,
      //They will be cached and tracking will start.
      //Call album.stopTracking() to stop this. ex. on componentDidUnmount
      trackInsertsAndDeletes : true,
      trackChanges : false
    }).then((response) => {
      console.log(response.assets, 'The assets in the first album');
    });
  });
~~~~

###### Props to `getAlbums`

Get albums allow to query the Photos Framework for asset-albums. Both User-created ones and Smart-albums.
Note that Apple creates a lot of dynamic, so called Smart Albums, like : 'Recently added', 'Favourites' etc.

NOTE: There is also another method called `getAlbumsMany`. This could be considered a low-level-method of the API. It is constructed so that this library can build more accessible methods on top of one joint native-call: like getUserTopAlbums in pure JS.
The getAlbumsMany-api can take multiple queries (array<albumquery>) and return an array<albumqueryresult>.

| Prop  | Default  | Type | Description |
| :------------ |:---------------:| :---------------:| :-----|
| fetchOptions | - | `object` | See above. |
| assetFetchOptions | - | `object` | Fetch options used when loading assets from album returned. You can choose to pass these fetchOptions here to affect `previewAssets` and `assetCount` in the album according to these options. Note: If you supply fetchOptions when later calling getAssets, those options will override these options.  |
| :------------ |:---------------:| :---------------:| :-----|
| type | `album` | `string` | Defines what type of album/collection you wish to retrieve. Converted in Native to PHAssetCollectionType. Accepted enum-values: `album`, `smartAlbum`, `moment` |
| subType | `any` | `string` | Defines what subType the album/collection you wish to retrieve should have. Converted in Native to PHAssetCollectionSubtype. Accepted enum-values: `any`, `albumRegular`, `syncedEvent`, `syncedFaces`, `syncedAlbum`, `imported`, `albumMyPhotoStream`, `albumCloudShared`, `smartAlbumGeneric`, `smartAlbumPanoramas`, `smartAlbumVideos`, `smartAlbumFavorites`, `smartAlbumTimelapses`, `smartAlbumAllHidden`, `smartAlbumRecentlyAdded`, `smartAlbumBursts`, `smartAlbumSlomoVideos`, `smartAlbumUserLibrary`, `smartAlbumSelfPortraits`, `smartAlbumScreenshots` |
| assetCount | `estimated` | `string/enum` | You can choose to get `estimated` count of the collection or `exact`-count. Of course these have different performance-impacts. Returns -1 if the estimated count can't be fetched quickly. Remember that your of course fetchOptions affects this count. |
| previewAssets | - | `number` | If you set this to a number, say 2, you will get the first two images from the album included in the album-response. This is so you can show a small preview-thumbnail for the album if you like to. |
| includeMetadata | false | `boolean` | Include some meta data about the album. You can also choose to get this metaData at a later point by calling album.getMetadata (See below) |
| noCache | `false` | `boolean` | If you set this flag to true. The result won't get cached or tracked for changes. |
| preCacheAssets | `false` | `boolean` | If you set this property to true all assets of all albums your query returned will be cached and change-tracking will start. |
| trackInsertsAndDeletes | `false` | `boolean` | If you set this to true. You will get called back on `queryResult.onChange` when a Insert or Delete happens. See observing changes below for more details. |
| trackChanges | `false` | `boolean` | If you set this to true. You will get called back on `queryResult.onChange` when a Change happens to the query-result. See observing changes below for more details. |

# Working with Albums:

##Static methods:

###Base methods:
~~~~
//Fetches albums for params. See above
RNPhotosFramework.getAlbums(params)
//Fetches many queries
//as SingleQueryResult : boolean. if true, will return response as one single response.
RNPhotosFramework.getAlbumsMany([params, params...], asSingleQueryResult);
//Prebuilt query for fetching the most typical albums:
//Camera-Roll, User-albums and user-shared-albums.
RNPhotosFramework.getAlbumsCommon(params)
~~~~

###createAlbum
~~~~
  RNPhotosFramework.createAlbum('test-album').then((album) => {
    //You can now use the album like any other album:
    return album.getAssets().then((photos) => {});
  });
~~~~

Signature: RNPhotosFramework.createAlbum(albumTitle) : Promise<album>.
There is also another multi-method you can use here:
Signature: RNPhotosFramework.createAlbums(albumTitles) : Promise<album>.

NOTE: Alums can have the same name. All resources in Photos are unique on their
localIdentifier. You can use the below methods to tackle this:

###getAlbumsByTitle
~~~~
  RNPhotosFramework.getAlbumsByTitle('test-album').then((albums) => {});
~~~~
Signature: RNPhotosFramework.getAlbumsByTitle(albumTitle) : Promise<array<album>>.
Many albums can have the same title. Returns all matching albums.
There is also another multi-method you can use here:
Signature: RNPhotosFramework.getAlbumsByTitles(albumTitles) : Promise<array<album>>.
Signature: RNPhotosFramework.getAlbumsWithParams({albumTitles, ...otherThingLikeFetchOptionsOrType/SubType}) : Promise<array<album>>.

###getAlbumByLocalIdentifier and getAlbumByLocalIdentifiers
~~~~
  RNPhotosFramework.getAlbumByLocalIdentifier(localIdentifier).then((album) => {});
~~~~
Signature: RNPhotosFramework.getAlbumByLocalIdentifier(localIdentifier) : Promise<album>.
All alums carry their localIdentifier on album.localIdentifier.

##Album instance-methods:

###addAssetToAlbum and addAssetsToAlbum
~~~~
  album.addAssetToAlbum(asset).then((status) => {});
~~~~
Signature: album.addAssetToAlbum(asset) : Promise<status>.
Add an asset/assets to an album.
NOTE: Can only be called with assets that are stored in the library already.
If you have a image that you want to save to the library see createAsset.


###removeAssetFromAlbum and removeAssetsFromAlbum
~~~~
  album.removeAssetFromAlbum(asset).then((status) => {});
~~~~
Signature: album.removeAssetFromAlbum(asset) : Promise<status>.
Remove asset from album.
NOTE: Can only be called with assets that are stored in the library already.
If you have a image that you want to save to the library see createAsset.

###updateTitle
~~~~
  album.updateTitle(newTitle).then((status) => {});
~~~~
Signature: album.updateTitle(string) : Promise<status>.
Change title on an album.

###delete
~~~~
  album.delete().then((status) => {});
~~~~
Signature: album.delete() : Promise<status>.
Delete an album.

###getMetadata
~~~~
  album.getMetadata().then((mutatedAlbumWithMetadata) => {});
~~~~
Fetch meta data for a specific album. You can also include metadata on all albums in the first `getAlbum`-call
by explicitly setting option `includeMetadata: true`.

# Working with Assets (Images/Photos):
When you retrieve assets from the API you will get back an Asset object.
There is nothing special about this object. I've defined it as a class so
that it can have some instance-methods. But it should be highly compatible with
native RN-elements like `<Image source={asset.image}></Image>`.
NOTE: Use the property .image on an asset for the <Image>-tag. Otherwise
RN will freeze your asset object. And they are, right now at least mutable.
//More info about videos/audio coming soon

##Images/Photos

An Image/Photo-asset is fully compatible with RN's <Image>-tag.
This includes all resizeModes.

##Asset instance-methods:

###getMetadata
~~~~
  asset.getMetadata().then((mutatedAssetWithMetadata) => {});
~~~~
Fetch metadata for a specific asset. You can also include metadata on all assets in the first `getAsset`-call by explicitly setting option `includeMetadata: true`.

###getResourcesMetadata
~~~~
  asset.getResourcesMetadata().then((mutatedAssetWithResourcesMetadata) => {
    console.log(mutatedAssetWithResourcesMetadata.resourcesMetadata);
  });
~~~~
Fetch resource-metadata for a specific asset, this includes original filename, type, uti (uniformTypeIdentifier) and localidentifier. You can also include resource-metadata on all assets in the first `getAsset`-call by explicitly setting option `includeResourcesMetadata: true`.

###delete
~~~~
  asset.delete().then((status) => {
  });
~~~~
Delete asset.

##ImageAsset instance-methods:
###getImageMetadata
~~~~
  asset.getImageMetadata().then((mutatedAssetWithImageMetadata) => {
    console.log(mutatedAssetWithResourcesMetadata.imageMetadata);
  });
~~~~
Fetch image specific metadata for a specific image-asset, this includes formats and sizes.

##withOptions
See below (ImageLoader Concept).

###ImageLoader Concept:
~~~~
NOTE about RN's concept of Image loaders:
RN has a plugin-like system for displaying Images/Photos.
This means that any library (like this library) can define it's own
ImageLoader. When RN later gets a request to display a <Image> it will query
all ImageLoaders loaded in the system and ask which loader can load a specific resource.
If the resource starts with `https://` for instance, RN's own network-image-loader will take care of loading that resource. While if the scheme of the resource is `asset-library://` another ImageLoader will load that Image.

This library defines it's own ImageLoader which can load images from iCloud. (RN actually already have a ImageLoader that can load iCloud images, but we define our own/extend their original loader so we can have some extra functionality on our loader. (See deliveryMode below)).
A ´uri´ that our loader can load is defined in scheme: `pk://` and localIdentifier eg: `9509A678-2A07-405F-B3C6-49FD806915CC/L0/001`
URI-example: pk://9509A678-2A07-405F-B3C6-49FD806915CC/L0/001
~~~~

###deliveryMode (Advanced)
Apple's Photo Framework will download images from iCloud on demand, and will generally be very smart about caching and loading resources quickly. You can however define how an Image should be loaded. We have 3 different options in PHImageRequestOptionsDeliveryMode:

~~~~
PHImageRequestOptionsDeliveryModeOpportunistic = 0, // client may get several image results when the call is asynchronous or will get one result when the call is synchronous
PHImageRequestOptionsDeliveryModeHighQualityFormat = 1, // client will get one result only and it will be as asked or better than asked (sync requests are automatically processed this way regardless of the specified mode)
PHImageRequestOptionsDeliveryModeFastFormat = 2 // client will get one result only and it may be degraded
~~~~

This library defaults to loading assets with `PHImageRequestOptionsDeliveryModeHighQualityFormat`.
This can be considered to be the same as RN normally loads images. It will simply download the image in the size of your <Image> (iCloud-images are stored in multiple sizes, and Photos Framework will download the one closest to your target size) and display it.

But you can choose to use the other two deliveryMode's to. you do this by calling:
~~~~
  const newAssetWithAnotherDeliveryMode = asset.withOptions({
      //one of opportunistic|highQuality|fast
      deliveryMode : 'opportunistic'
  });
~~~~
If you choose to use opportunistic here you will see a low-res-version of the image displayed
while the highQuality version of the resource is downloaded. NOTE: This library will call correct lifecycle callback's on your image-tag when this is used: the
`<Image onPartialLoad={//Low-res-callback} onLoad={//High-res-callback} onProgress={//downloadCallback}>`

#Creating Assets:
You can use this library to save images and videos to the users iCloud library.

##Images/Photos
Creating image-assets uses RN's ImageLoader-system behind the scenes and should therefore be able to accept/save any image/photo that you can display in RN.

###Static methods:

###createImageAsset
~~~~
  RCTCameraRollRNPhotosFrameworkManager.createImageAsset(imageWithUriProp);
~~~~
Signature: album.createImageAsset(params) : Promise<Asset>.
Create a image-asset

###createVideoAsset
~~~~
  RCTCameraRollRNPhotosFrameworkManager.createVideoAsset(videoWithUriProp);
~~~~
Signature: album.createVideoAsset(params) : Promise<Asset>.
Create a image-asset

###createAssets
~~~~
  RCTCameraRollRNPhotosFrameworkManager.createAssets({
    images : [{ uri : 'https://some-uri-local-or-remote.jpg' }],
    videos : [{ uri : 'https://some-uri-local-or-remote.jpg' }]
    album : album //(OPTIONAL) some album that you want to add the asset to when it's been added to the library.
    includeMetadata : true //The result of this function call will return new assets. should this have metadata on them? See docs of getAssets for more info.
  });
~~~~
Signature: album.createAssets(params) : Promise<array<Asset>>.
Base function for creating assets. Will return the successfully created new assets.
If the function returns less Assets then you sent as input, the ones not returned did fail.


#Observing library changes
You can register listeners for library-change-detection on different levels of the api.

##Library-level
You can detect globally if the library changed by:
~~~~
RNPhotosFramework.onLibraryChange(() => {
  console.log('Library Change');
});
~~~~
No details provided

##AlbumQueryResult-level
You can register a listener that receives updates when any of the albums that result contains
changes (Not if their assets change, only the Albums get those messages, see below).
You currently receive the following events: `AlbumTitleChanged` (More to come).
~~~~
const unsubscribeFunc = albumsFetchResult.onChange((changeDetails, update) => {
    if(changeDetails.hasIncrementalChanges) {
      update((updatedFetchResult) => {
         this.setState({albumsFetchResult: updatedFetchResult});
      });
    } else {
      //Do full reload here..
    }
});
~~~~
NOTE: If a change occures that affects one of the AlbumQueryResults albums that change will also be passed along to the album.

##Album/Assets-level
To receive change-updates on an album's assets you need to supply at least one of these
two arguments when calling `getAssets` on that album:
`trackInsertsAndDeletes : true` or
`trackChanges : true`
(See `Retrieving albums and enumerating their assets` above)

On an album object you can do:
~~~~
const unsubscribeFunc = album.onChange((changeDetails, update) => {
  if(changeDetails.hasIncrementalChanges) {
    //Important! Assets must be supplied in original fetch-order.
    update(this.state.assets, (updatedAssetArray) => {
      this.setState({
        assets : updatedAssetArray
      });
    }, 
    //If RNPF needs to retrive more assets to complete the change,
    //eg. a move happened that moved a previous out of array-index asset into your corrently loaded assets.
    //Here you can apply a param obj for options on how to load those assets. eg. ´includeMetadata : true´.
    {
      includeMetadata : true
    });
  }else {
    //Do full reload here..
  }
});
~~~~
The update-function will apply the changes to your collection.
