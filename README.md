# react-native-photos-framework
`npm i react-native-photos-framework --save`

Load photos/videos and more from CameraRoll and iCloud.
Uses Apples photos framework.

React Native comes with it's own CameraRoll library.
This however uses ALAssetLibrary which is a deprecated API from Apple
and can only load photos and videos stored on the users device.
This is not what your user expects today. Most users photos live on iCloud and these won't show if you use ALAssetLibrary.

If you use this library/Photos framework you can display the users local resources and the users iCloud resources.

# Retrieving photos/videos/audio:
~~~~
import RNPhotosFramework from 'react-native-photos-framework';

    RNPhotosFramework.getAssets({
          //You can call this function multiple times providing startIndex and endIndex as pagination
          startIndex : 0,
          endIndex : 100,

          //Media types you wish to display. See table bellow for possible options.
          mediaTypes : ['photo', 'video'],
          mediaSubTypes : ['photoPanorama'],

			//Where is the image located? See table bellow for possible options.
			sourceTypes : ['userLibrary']

          sortAscending : true,
          sortDescriptorKey : 'creationDate',

          //Start loading images into memory with these displayOptions (Not required)
          prepareForSizeDisplay : {
            width : 91.5,
            height : 91.5
          },
          prepareScale : 2
        }).then((images) => console.log(images));

~~~~

###### Props to `getAssets`

| Prop  | Default  | Type | Description |
| :------------ |:---------------:| :---------------:| :-----|
| startIndex | 0 | `number` | startIndex-offset for fetching |
| endIndex | 0 | `number` | endIndex-offset stop for fetching |
| mediaTypes | ['photo'] | `array<string>` | Defines what mediaType the asset should be. Array combined with OR-operator. eg. ['photo', 'video'] will return both photos and videos. Converted in Native to PHAssetMediaType. Accepted values: `photo`, `video`, `audio`, `unknown` |
| mediaSubTypes | [`none`] | `array<string>` | Defines what subtype the asset should be. Array combined with OR-operator. eg. ['photoPanorama', 'photoHDR'] will return both panorama and HDR-assets. Converted in Native to PHAssetMediaSubtype. Accepted enum-values: `none`, `photoPanorama`, `photoHDR`, `photoScreenshot`, `photoLive`, `videoStreamed`, `videoHighFrameRate`, `videoTimeLapse` (mediaTypes and mediaSubTypes are combined with AND-operator) |
| sourceTypes | - | `array<string>` | Defines where the asset should come from originally. Array combined with OR-operator. Converted in Native to PHAssetSourceType. Accepted enum-values: `none`, `userLibrary`, `cloudShared`, `itunesSynced`. |
| includeHiddenAssets | false | `boolean` | A Boolean value that determines whether the fetch result includes assets marked as hidden. |
| includeAllBurstAssets | false | `boolean` | A Boolean value that determines whether the fetch result includes all assets from burst photo sequences. |
| fetchLimit | 0 | `number` | The maximum number of objects to include in the fetch result. Remember to not use this in the wrong way combined with startIndex and endIndex. 0 means unlimited. |
| sortAscending | false | `boolean` |  Defines sort-order |
| sortDescriptorKey | 'creationDate' | `string` | Defines field to sort on. More example options to come.  |
| prepareForSizeDisplay | - | `Rect(width, height)` | The size of the image you soon will display after running the query. This is highly optional and only there for optimizations of big lists. Prepares the images for display in Photos by using PHCachingImageManager |
| prepareScale | 2.0 | `number` | The scale to prepare the image in. |


# Retrieving albums and enumerating their assets:
~~~~
return RNPhotosFramework.getAlbums(
    {
      type: 'album',
      subType: 'any',
      assetCount: 'exact',
      prepareForEnumeration: true,
      fetchOptions: {
        sortDescriptorKey: 'creationDate',
        sortAscending: true,
        includeHiddenAssets: false,
        includeAllBurstAssets: false
      }
    }
  ).then((queryResult) => {
  const album = queryResult.albums[0];
  return album.getAssets({
    //The fetch-options from the outer query will apply 	here, if we get
    startIndex : 0,
    endIndex : 10,
    prepareForSizeDisplay: {
      width: 91.5,
      height: 91.5
    },
    prepareScale: 2
  }).then((assets) => {
   	  console.log(assets, 'The assets in the first album');
  });
});
~~~~

###### Props to `getAlbums`

Get collections allow to query the Photos Framework for asset-albums. Both User-created ones and Smart-albums.
Note that Apple creates a lot of dynamic, so called Smart Albums, like : 'Recently added', 'Favourites' etc.

NOTE: There is also another method called `getAlbumsMany`. This could be considered a low-level-method of the API. It is constructed so that this library can build more accessable methods on top of one joint native-call: like getUserTopAlbums in pure JS.
The getAlbumsMany-api can take multiple queries (array<albumquery>) and return an array<albumqueryresult>.


| Prop  | Default  | Type | Description |
| :------------ |:---------------:| :---------------:| :-----|
| type | `album` | `string` | Defines what type of album/collection you wish to retrieve. Converted in Native to PHAssetCollectionType. Accepted enum-values: `album`, `smartAlbum`, `moment` |
| subType | `any` | `string` | Defines what subType the album/collection you wish to retrieve should have. Converted in Native to PHAssetCollectionSubtype. Accepted enum-values: `any`, `albumRegular`, `syncedEvent`, `syncedFaces`, `syncedAlbum`, `imported`, `albumMyPhotoStream`, `albumCloudShared`, `smartAlbumGeneric`, `smartAlbumPanoramas`, `smartAlbumVideos`, `smartAlbumFavorites`, `smartAlbumTimelapses`, `smartAlbumAllHidden`, `smartAlbumRecentlyAdded`, `smartAlbumBursts`, `smartAlbumSlomoVideos`, `smartAlbumUserLibrary`, `smartAlbumSelfPortraits`, `smartAlbumScreenshots` |
| assetCount | `none` | `string/enum` | By default you wont get any asset-count from the collection. But you can choose to get `estimated` count of the collection or `exact`-count. Of course these have different performance-impacts. Remember that your of course fetchOptions affects this count. |
| prepareForEnumeration | `false` | `boolean` | If this property is `true` then the collections will get cached in native and you will be able to call `getAssets` on any album returned from the query effectively enumerating the result. |

# Working with Albums:

##Static methods:

###createAlbum
~~~~
return RNPhotosFramework.createAlbum('test-album').then((album) => {
  //You can now use the album like any other album:
  return album.getAssets().then((photos) => {

  });
});
~~~~

Signature: RNPhotosFramework.createAlbum(albumName) : Promise<album>.
NOTE: Alums can have the same name. All resources in Photos are unique on their
localIdentifier. You can use the bellow methods to tackle this:

###getAlbumsByTitle
~~~~
return RNPhotosFramework.getAlbumsByTitle('test-album').then((albums) => {

});
~~~~
Signature: RNPhotosFramework.getAlbumsByTitle(albumTitle) : Promise<array<album>>.
May albums can have the same title. Returns all matching albums.

###getAlbumByLocalIdentifier and getAlbumByLocalIdentifiers
~~~~
return RNPhotosFramework.getAlbumByLocalIdentifier(localIdentifier).then((album) => {

});
~~~~
Signature: RNPhotosFramework.getAlbumByLocalIdentifier(localIdentifier) : Promise<album>.
All alums carry their localIdentifier on album.localIdentifier.

##Album instance-methods:

###addAssetToAlbum and addAssetsToAlbum
~~~~
return album.addAssetToAlbum(asset).then((status) => {

});
~~~~
Signature: album.addAssetToAlbum(asset) : Promise<status>.
Add an asset/assets to an album.
NOTE: Can only be called with assets that are stored in the library already.
If you have a image that you want to save to the library see createAsset.


###removeAssetFromAlbum and removeAssetsFromAlbum
~~~~
return album.removeAssetFromAlbum(asset).then((status) => {

});
~~~~
Signature: album.removeAssetFromAlbum(asset) : Promise<status>.
Remove asset from album.
NOTE: Can only be called with assets that are stored in the library already.
If you have a image that you want to save to the library see createAsset.

###updateTitle
~~~~
return album.updateTitle(newTitle).then((status) => {

});
~~~~
Signature: album.updateTitle(string) : Promise<status>.
Change title on an album.

###remove
~~~~
return album.remove().then((status) => {

});
~~~~
Signature: album.remove() : Promise<status>.
Remove an album.

# Working with Assets (Images/Photos):
When you retrieve assets from the API you will get back an Asset object.
There is nothing special about this object. I've defined it as a class so
that it can have some instance-methods. But it should be highly compatible with
native RN-elements like `<Image source={asset}></Image>`.
//More info about videos/audio coming soon

##Images/Photos

An Image/Photo-asset is fully compatible with RN's <Image>-tag.
This includes all resizeModes.

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

This library defaults to loading assets with PHImageRequestOptionsDeliveryModeHighQualityFormat.
This can be considered to be the same as RN normally loads images. It will simply download the image and and display it.

But you can choose to use the other two deliveryMode's to. you do this by calling:
~~~~
  const newAssetWithAnotherDeliveryMode = asset.withOptions({
      //one of opportunistic|highQuality|fast
      deliveryMode : 'opportunistic'
  });
~~~~
If you choose to use opportunistic here you will see a low-res-version of the image displayed
while the highQuality version of the resource is downloaded. NOTE: This library will call correct lifecycle callback's on your image-obj when this is used: the <Image onPartialLoad={//Low-res-callback} onLoad={//High-res-callback} onProgress={//downloadCallback}>




documentation in progress...
