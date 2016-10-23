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

# Retrieving images:
~~~~
import RNPhotosFramework from 'react-native-photos-framework';

    RNPhotosFramework.getPhotos({
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

#### Props to `getPhotos`

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
| sortDescriptorKey | 'creationDate' | `string` | Defines feild to sort on. More example options to come.  |
| prepareForSizeDisplay | - | `Rect(width, height)` | The size of the image you soon will display after running the query. This is highly optional and only there for optimizations of big lists. Prepares the images for display in Photos by using PHCachingImageManager |
| prepareScale | 2.0 | `number` | The scale to prepare the image in. |


# Retrieving albums and enumerating their images:
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
  return album.getPhotos({
    //The fetch-options from the outer query will apply 	here, if we get
    startIndex : 0,
    endIndex : 10,
    prepareForSizeDisplay: {
      width: 91.5,
      height: 91.5
    },
    prepareScale: 2
  }).then((photos) => {
   	  console.log(photos, 'The photos in the first album');
  });
});
~~~~

#### Props to `getAlbums`

Get collections allow to query the Photos Framework for photo-albums. Both User-created ones and Smart-albums.
Note that Apple creates a lot of dynamic, so called Smart Albums, like : 'Recently added', 'Favourites' etc.

NOTE: There is also another method called getAlbumsMany. This could be considered a low-level-method of the API. It is constructed so that this library can build more accessable methods on top of one joint native-call: like getUserTopAlbums in pure JS.
The getAlbumsMany-api can take multiple queries (array<albumquery>) and return an array<albumqueryresult>.


| Prop  | Default  | Type | Description |
| :------------ |:---------------:| :---------------:| :-----|
| type | `album` | `string` | Defines what type of album/collection you wish to retrieve. Converted in Native to PHAssetCollectionType. Accepted enum-values: `album`, `smartAlbum`, `moment` |
| subType | `any` | `string` | Defines what subType the album/collection you wish to retrieve should have. Converted in Native to PHAssetCollectionSubtype. Accepted enum-values: `any`, `albumRegular`, `syncedEvent`, `syncedFaces`, `syncedAlbum`, `imported`, `albumMyPhotoStream`, `albumCloudShared`, `smartAlbumGeneric`, `smartAlbumPanoramas`, `smartAlbumVideos`, `smartAlbumFavorites`, `smartAlbumTimelapses`, `smartAlbumAllHidden`, `smartAlbumRecentlyAdded`, `smartAlbumBursts`, `smartAlbumSlomoVideos`, `smartAlbumUserLibrary`, `smartAlbumSelfPortraits`, `smartAlbumScreenshots` |
| assetCount | `none` | `string/enum` | By default you wont get any asset-count from the collection. But you can choose to get `estimated` count of the collection or `exact`-count. Of course these have different performance-impacts. Remember that your of course fetchOptions affects this count. |
| prepareForEnumeration | `false` | `boolean` | If this property is `true` then the collections will get cached in native and you will be able to call `getPhotos` on any album returned from the query effectively enumerating the result. |
