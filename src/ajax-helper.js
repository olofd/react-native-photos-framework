import Asset from './asset';
import NativeApi from './index';
export function postAssets(assets, {
    url,
    method,  
    onProgress,
    onComplete,
    onError,
    onFinnished,
    modifyAssetData,
    headers
}) {
    let totalProgressLoaded = {};
    let completedItems = [];
    let lastLoadedProgress;
    const onTotalProgress = (assetUpdatePorgress) => {
        if (onProgress) {
            totalProgressLoaded[assetUpdatePorgress.asset.uri] = assetUpdatePorgress;
            const loadedProgress = Object.keys(totalProgressLoaded).reduce((loaded, uri) => {
                const assetProgress = totalProgressLoaded[uri];
                return (loaded + assetProgress.percentComplete);
            }, 0);
            const loadedProgressTotal = Math.ceil(loadedProgress / assets.length);
            if (lastLoadedProgress && lastLoadedProgress === loadedProgressTotal) {
                return;
            }
            lastLoadedProgress = loadedProgressTotal;
            onProgress(lastLoadedProgress, totalProgressLoaded);
        }
    };

    const onItemComplete = (asset, status, responseText, xhr) => {
        completedItems.push({
            asset,
            status,
            responseText,
            xhr
        });
        if (status === 200) {
            onComplete && onComplete(asset, status, responseText, xhr);
        } else {
            onError && onError(asset, status, responseText, xhr);
        }
        if (completedItems.length === assets.length) {
            onFinnished && onFinnished(completedItems);
        }
    };

    const prepareAssets = (assets) => {
        return new Promise((resolve, reject) => {
            const assetsWithoutRoesourceMetaData = assets.filter(asset => asset.resourcesMetadata === undefined);
            if (assetsWithoutRoesourceMetaData.length) {
                NativeApi.getAssetsResourcesMetadata(assetsWithoutRoesourceMetaData.map(asset => asset.localIdentifier)).then((result) => {
                    assetsWithoutRoesourceMetaData.forEach((asset) => {
                        Object.assign(asset, result[asset.localIdentifier]);
                    });
                    resolve(assets);
                });
            } else {
                resolve(assets);
            }
        });
    };

    return prepareAssets(assets).then((preparedAssets) => {
        const createPostableAsset = (asset) => {
            const resourceMetaData = asset.resourcesMetadata[0];
            let postableAsset = {
                uri: asset.uri,
                name: resourceMetaData.originalFilename,
                type: resourceMetaData.mimeType
            };
            if (modifyAssetData) {
                postableAsset = modifyAssetData(postableAsset, asset, resourceMetaData);
            }
            return postableAsset;
        };
        return Promise.all(preparedAssets.map(createPostableAsset).map((postableAsset) => {
            return postAsset(postableAsset, {
                url,
                method,
                headers,
                onProgress: onTotalProgress,
                onComplete: onItemComplete,
                onError: onItemComplete,
            });
        }));
    });
}

export function postAsset(postableAsset, {
    url,
    method,
    headers,
    onProgress,
    onComplete,
    onError
}) {
    return new Promise((resolve, reject) => {
        const body = new FormData();
        body.append('asset', postableAsset);
        const xhr = new XMLHttpRequest();
        let lastPercentageComplete;
        xhr.upload.onprogress = (evt) => {
            if (evt.lengthComputable) {
                const percentComplete = Math.ceil((evt.loaded / evt.total) * 100);
                if (lastPercentageComplete && percentComplete === lastPercentageComplete) {
                    return;
                }
                lastPercentageComplete = percentComplete;
                onProgress({
                    asset: postableAsset,
                    percentComplete: percentComplete,
                    loaded: evt.loaded,
                    total: evt.total
                });
            }
        };
        xhr.open(method !== undefined ? method : 'POST', url);
        xhr.send(body);

        xhr.onreadystatechange = (aEvt) => {
            if (xhr.readyState === 1) {
                if (headers) {
                    Object.keys(headers).map((key) => {
                        xhr.setRequestHeader(key, headers[key]);
                    });
                }
            }
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    onComplete(postableAsset, xhr.status, xhr.responseText, xhr);
                    resolve({
                        postableAsset,
                        status: xhr.status,
                        responseText: xhr.responseText,
                        xhr
                    });
                } else {
                    onError(postableAsset, xhr.status, xhr.responseText, xhr);
                    reject({
                        postableAsset,
                        status: xhr.status,
                        responseText: xhr.responseText,
                        xhr
                    });
                }
            }
        };
    });
}