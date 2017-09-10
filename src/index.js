import ReactPropTypes from "prop-types";
import { NativeEventEmitter, NativeModules, Platform } from "react-native";
import Asset from "./asset";
import Album from "./album";
import AlbumQueryResult from "./album-query-result";
import AlbumQueryResultCollection from "./album-query-result-collection";
import EventEmitter from "../event-emitter";
import ImageAsset from "./image-asset";
import VideoAsset from "./video-asset";
import videoPropsResolver from "./video-props-resolver";
import uuidGenerator from "./uuid-generator";

const RNPFManager = NativeModules.RNPFManager;
if (!RNPFManager && Platform.OS === "ios") {
    throw new Error(
        "Could not find react-native-photos-framework's native module. It seems it's not linked correctly in your xcode-project."
    );
}
export const eventEmitter = new EventEmitter();

// Main JS-implementation Most methods are written to handle array of input
// operations.
class RNPhotosFramework {
    constructor() {
        this.nativeEventEmitter = new NativeEventEmitter(
            NativeModules.RNPFManager
        );
        this.nativeEventEmitter.addListener("onObjectChange", changeDetails => {
            eventEmitter.emit("onObjectChange", changeDetails);
        });
        this.nativeEventEmitter.addListener(
            "onLibraryChange",
            changeDetails => {
                eventEmitter.emit("onLibraryChange", changeDetails);
            }
        );

        //We need to make sure we clean cache in native before any calls
        //go into RNPF. This is important when running in DEV because we reastart
        //often in RN. (Live reload).
        const methodsWithoutCacheCleanBlock = [
            "constructor",
            "libraryStartup",
            "authorizationStatus",
            "requestAuthorization",
            "createJsAsset",
            "withUniqueEventListener",
        ];
        const methodNames = Object.getOwnPropertyNames(
            RNPhotosFramework.prototype
        ).filter(
            method => methodsWithoutCacheCleanBlock.indexOf(method) === -1
        );
        methodNames.forEach(methodName => {
            const originalMethod = this[methodName];
            this[methodName] = function(...args) {
                if (!this.libraryStartupPromise) {
                    this.libraryStartupPromise = this.libraryStartup();
                }
                return this.libraryStartupPromise.then(() =>
                    originalMethod.apply(this, args)
                );
            }.bind(this);
        });
    }

    onLibraryChange(cb) {
        return eventEmitter.addListener("onLibraryChange", cb);
    }

    libraryStartup() {
        return RNPFManager.libraryStartup(true);
    }

    authorizationStatus() {
        return RNPFManager.authorizationStatus();
    }

    requestAuthorization() {
        return RNPFManager.requestAuthorization();
    }

    setAllowsCachingHighQualityImages(allowed) {
        return RNPFManager.setAllowsCachingHighQualityImages(allowed);
    }

    addAssetsToAlbum(params) {
        return RNPFManager.addAssetsToAlbum(params);
    }

    removeAssetsFromAlbum(params) {
        return RNPFManager.removeAssetsFromAlbum(params);
    }

    getAssets(params) {
        //This might look hacky, but it is!
        //We default to assetDisplayStartToEnd == false because photos framework will by default
        //give us the results in the same order as the photos-app displays them. The most recent image last that is.
        //BUT in this library we have decided to reverse that default, because most third-party apps wants (our guesses)
        //the most recent photo first. So by default we load the results in reverse by saying assetDisplayStartToEnd = false.
        //However. If this option is not expicitly set and you provide a saortDescriptor, we no longer want to reverse the ordser
        //of the photos. Then we want to display them as is. So here we check for that scenario. If the key assetDisplayStartToEnd is
        //not explicitly set and there is a sortDescriptor, do not reverse the order of the photos by assetDisplayStartToEnd = true.
        if (
            params &&
            params.fetchOptions &&
            params.assetDisplayStartToEnd === undefined &&
            params.fetchOptions.sortDescriptors &&
            params.fetchOptions.sortDescriptors.length
        ) {
            params.assetDisplayStartToEnd = true;
        }
        return RNPFManager.getAssets(params).then(assetsResponse => {
            return {
                assets: assetsResponse.assets.map(this.createJsAsset),
                includesLastAsset: assetsResponse.includesLastAsset,
            };
        });
    }

    getAssetsWithIndecies(params) {
        return RNPFManager.getAssetsWithIndecies(
            params
        ).then(assetsResponse => {
            return assetsResponse.assets.map(this.createJsAsset);
        });
    }

    getAlbumsCommon(params, asSingleQueryResult) {
        return this.getAlbumsMany(
            [
                Object.assign(
                    {
                        type: "smartAlbum",
                        subType: "any",
                    },
                    params
                ),
                Object.assign(
                    {
                        type: "album",
                        subType: "any",
                    },
                    params
                ),
            ],
            asSingleQueryResult
        ).then(albumQueryResult => {
            return albumQueryResult;
        });
    }

    getAlbums(params) {
        return this.getAlbumsMany([params]).then(queryResults => {
            return queryResults[0];
        });
    }

    getAlbumsMany(params, asSingleQueryResult) {
        return this._getAlbumsManyRaw(params).then(albumQueryResultList => {
            const albumQueryResults = albumQueryResultList.map(
                (collection, index) =>
                    new AlbumQueryResult(
                        collection,
                        params[index],
                        eventEmitter
                    )
            );
            if (asSingleQueryResult) {
                return new AlbumQueryResultCollection(
                    albumQueryResults,
                    params,
                    eventEmitter
                );
            }
            return albumQueryResults;
        });
    }

    _getAlbumsManyRaw(params) {
        return RNPFManager.getAlbumsMany(params);
    }

    getAlbumsByTitle(title) {
        return this.getAlbumsWithParams({
            albumTitles: [title],
        });
    }

    getAlbumsByTitles(titles) {
        return this.getAlbumsWithParams({
            albumTitles: titles,
        });
    }

    // param should include property called albumTitles : array<string> But can also
    // include things like fetchOptions and type/subtype.
    getAlbumsWithParams(params) {
        return RNPFManager.getAlbumsByTitles(params).then(albumQueryResult => {
            return new AlbumQueryResult(albumQueryResult, params, eventEmitter);
        });
    }

    createAlbum(albumTitle) {
        return this.createAlbums([albumTitle]).then(albums => {
            return albums[0];
        });
    }

    createAlbums(albumTitles) {
        return RNPFManager.createAlbums(albumTitles).then(albums => {
            return albums.map(
                album => new Album(album, undefined, eventEmitter)
            );
        });
    }

    updateAlbumTitle(params) {
        //minimum params: {newTitle : 'x', albumLocalIdentifier : 'guid'}
        return RNPFManager.updateAlbumTitle(params);
    }

    updateAssets(assetUpdateObjs) {
        /* assetUpdateObj : {localIdentifier : {creationDate, location, favorite, hidden}} */
        const arrayWithLocalIdentifiers = Object.keys(assetUpdateObjs);
        return RNPFManager.updateAssets(
            arrayWithLocalIdentifiers,
            assetUpdateObjs
        ).then(result => {
            return result;
        });
    }

    getAssetsMetadata(assetsLocalIdentifiers) {
        return RNPFManager.getAssetsMetadata(assetsLocalIdentifiers);
    }

    getAssetsResourcesMetadata(assetsLocalIdentifiers) {
        return RNPFManager.getAssetsResourcesMetadata(assetsLocalIdentifiers);
    }

    updateAssetsWithResoucesMetadata(assets) {
        return new Promise((resolve, reject) => {
            const assetsWithoutRoesourceMetaData = assets.filter(
                asset => asset.resourcesMetadata === undefined
            );
            if (assetsWithoutRoesourceMetaData.length) {
                RNPFManager.getAssetsResourcesMetadata(
                    assetsWithoutRoesourceMetaData.map(
                        asset => asset.localIdentifier
                    )
                ).then(result => {
                    assetsWithoutRoesourceMetaData.forEach(asset => {
                        Object.assign(asset, result[asset.localIdentifier]);
                    });
                    resolve(assets);
                });
            } else {
                resolve(assets);
            }
        });
    }

    getImageAssetsMetadata(assetsLocalIdentifiers) {
        return RNPFManager.getImageAssetsMetadata(assetsLocalIdentifiers);
    }

    deleteAssets(assets) {
        return RNPFManager.deleteAssets(
            assets.map(asset => asset.localIdentifier)
        );
    }

    deleteAlbums(albums) {
        return RNPFManager.deleteAlbums(
            albums.map(album => album.localIdentifier)
        );
    }

    createImageAsset(image) {
        return this.createAssets({
            images: [image],
        }).then(result => result[0]);
    }

    createVideoAsset(video) {
        return this.createAssets({
            videos: [video],
        }).then(result => result[1]);
    }

    getPostableAssets(localIdentifiers) {
        return RNPFManager.getPostableAssets(localIdentifiers);
    }

    createAssets(params, onProgress) {
        const images = params.images;
        const videos =
            params.videos !== undefined
                ? params.videos.map(videoPropsResolver)
                : params.videos;
        let media = [];
        if (images && images.length) {
            media = media.concat(
                images.map(image => ({
                    type: "image",
                    source: image,
                }))
            );
        }
        if (videos && videos.length) {
            media = media.concat(
                videos.map(video => ({
                    type: "video",
                    source: video,
                }))
            );
        }

        const { args, unsubscribe } = this.withUniqueEventListener(
            "onCreateAssetsProgress",
            {
                media: media,
                albumLocalIdentifier: params.album
                    ? params.album.localIdentifier
                    : undefined,
                includeMetadata: params.includeMetadata,
            },
            onProgress
        );
        return RNPFManager.createAssets(args).then(result => {
            unsubscribe && this.nativeEventEmitter.removeListener(unsubscribe);
            return result.assets.map(this.createJsAsset);
        });
    }

    withUniqueEventListener(eventName, params, cb) {
        let subscription;
        if (cb) {
            params[eventName] = uuidGenerator();
            subscription = this.nativeEventEmitter.addListener(
                eventName,
                data => {
                    if (cb && data.id && data.id === params[eventName]) {
                        cb(data);
                    }
                }
            );
        }
        return {
            args: params,
            unsubscribe: subscription,
        };
    }

    stopTracking(cacheKey) {
        return new Promise((resolve, reject) => {
            if (cacheKey) {
                return resolve(RNPFManager.stopTracking(cacheKey));
            } else {
                resolve({
                    success: true,
                    status: "was-not-tracked",
                });
            }
        });
    }

    asSingleQueryResult(albumQueryResultList, params, eventEmitter) {
        return new AlbumQueryResultCollection(
            albumQueryResultList,
            params,
            eventEmitter
        );
    }

    createJsAsset(nativeObj, options) {
        switch (nativeObj.mediaType) {
            case "image":
                return new ImageAsset(nativeObj, options);
            case "video":
                return new VideoAsset(nativeObj, options);
        }
    }

    /*
      assets,
      options : {
        dir : '/path', //optional
      },
      generateFileName : (asset, resourceMetadata) => {
        return 'newFileName';
      }
  */

    saveAssetsToDisk(assetsWithOptions, options, generateFileName) {
        const { args, unsubscribe } = this.withUniqueEventListener(
            "onSaveAssetsToFileProgress",
            {},
            options.onProgress
        );

        return this.updateAssetsWithResoucesMetadata(
            assetsWithOptions.map(assetWithOption => assetWithOption.asset)
        ).then(() => {
            return RNPFManager.saveAssetsToDisk({
                media: assetsWithOptions.map(assetWithOption => {
                    const { asset } = assetWithOption;
                    const resourceMetadata =
                        assetWithOption.asset.resourcesMetadata[0];
                    const fileName =
                        generateFileName !== undefined
                            ? generateFileName(
                                  assetWithOption.asset,
                                  resourceMetadata
                              )
                            : resourceMetadata.originalFilename;
                    return {
                        fileName,
                        ...resourceMetadata,
                        uri: asset.uri,
                        localIdentifier: asset.localIdentifier,
                        mediaType: asset.mediaType,
                        ...assetWithOption.options,
                    };
                }),
                events: {
                    onSaveAssetsToFileProgress: args.onSaveAssetsToFileProgress,
                },
            });
        });
    }
}

export default new RNPhotosFramework();
