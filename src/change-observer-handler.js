function updateHandler(arr, cb) {
    if (arr) {
        for (let i = 0; i < arr.length; i++) {
            const updatedObj = arr[i];
            cb(updatedObj);
        }
    }
}

function enumerateMoves(arr, changeDetails, indexTranslater, cb) {
    if (changeDetails.moves && changeDetails.moves.length) {
        for (let i = 0; i < changeDetails.moves.length; i = (i + 2)) {
            let fromIndex = changeDetails.moves[i];
            let toIndex = changeDetails.moves[i + 1];

            let fromIndexMod = indexTranslater !== undefined ? indexTranslater(
                fromIndex, arr, 'move') : fromIndex;
            let toIndexMod = indexTranslater !== undefined ? indexTranslater(toIndex, arr, 'move') :
                toIndex;
            cb(fromIndexMod, toIndexMod, fromIndex, toIndex);
        }
    }
}

export function indeciesIsReversedNormalOrScrambled(arr, changeDetails, preferedOrder) {
    if (!arr || arr.length <= 1) {
        return preferedOrder || 'normal';
    }
    const indecies = arr.map(x => x.collectionIndex);
    if (indecies.some(index => index === undefined)) {
        return 'scrambled';
    }
    let order;
    for (let i = 0; i < arr.length; i++) {
        let thisOrder = 'scrambled';
        let previousIndex;
        let currentIndex = arr[i].collectionIndex;
        if (i !== 0 && arr[i - 1]) {
            previousIndex = arr[i - 1].collectionIndex;
        }
        if (previousIndex !== undefined) {
            if (currentIndex === previousIndex + 1) {
                thisOrder = 'normal';
            }
            if (currentIndex === previousIndex - 1) {
                thisOrder = 'reversed';
            }
            if (order && order !== thisOrder) {
                order = 'scrambled';
                break;
            } else {
                order = thisOrder;
            }
        }
    }
    return order;
}

function getObjectIndex(updatedObj, indexTranslater, arr, operation) {
    const objectIndex = updatedObj.obj !== undefined && (updatedObj.obj.collectionIndex !==
        undefined) ? updatedObj.obj.collectionIndex : updatedObj.index;
    return indexTranslater !== undefined ? indexTranslater(
        objectIndex, arr, operation) : objectIndex;
}

function getMissingIndecies(changeDetails, arr, indexTranslater) {
    const missingIndecies = [];
    enumerateMoves(arr, changeDetails,
        indexTranslater, (fromIndex, toIndex, originalFromIndex, originalToIndex) => {
            const fromIndexIsOutsideOfRange = (fromIndex > (arr.length - 1) || fromIndex < 0);
            const toIndexIsWithinRange = (toIndex <= (arr.length - 1) && toIndex >= 0);
            if ((fromIndexIsOutsideOfRange && toIndexIsWithinRange) &&
                missingIndecies.indexOf(originalFromIndex) === -1) {
                //This might seem wrong (to push toIndex and not fromIndex), 
                //but we need to ask for the item we don't have in it's new position.
                //In native the collection is already up to date:
                missingIndecies.push(originalToIndex);
            }
        });
    return missingIndecies;
}

export function assetArrayObserverHandler(changeDetails, arr, createNewObjFunc, requestNewItemsCb, preferedOrder, stepCompletedCb) {
    const arrayOrder = indeciesIsReversedNormalOrScrambled(arr, changeDetails, preferedOrder);
    if (arrayOrder === 'scrambled') {
        throw new Error(
            '[RNPhotosFramework] You can not use the automatic update function for change observing with scrambled or undefined indecies (property collectionIndex). Please submit the assets in their original order or do the update manully'
        );
        return;
    }

    return collectionArrayObserverHandler(changeDetails, arr, createNewObjFunc, requestNewItemsCb,
        (index, arr, operation) => {
            let startIndex = 0;
            const arrWithoutUndefined = arr.filter(x => !!x);
            if (arrWithoutUndefined.length > 0) {
                startIndex = arrayOrder === 'normal' ? arrWithoutUndefined[0].collectionIndex : arrWithoutUndefined[
                    arrWithoutUndefined.length - 1].collectionIndex;
            }
            let indexAffected = index - startIndex;
            if (arrayOrder === 'reversed') {
                indexAffected = ((arr.length - (operation === 'insert' ? 0 : 1)) -
                    indexAffected);
            }
            return indexAffected;
        }, (arr, index, operation, newObj) => {
            if (arrayOrder === 'normal') {
                for (let i = index + 1; i < arr.length; i++) {
                    modifyIndex(arr, i, operation);
                }
            } else if (arrayOrder === 'reversed') {
                for (let i = index - 1; i >= 0; i--) {
                    modifyIndex(arr, i, operation);
                }
            }
        }, stepCompletedCb);
}

function modifyIndex(arr, index, operation) {
    const affectedObj = arr[index];
    if (affectedObj) {
        if (operation === 'insert') {
            affectedObj.collectionIndex++;
        } else if (operation === 'remove') {
            affectedObj.collectionIndex--;
        }
    }
}


export function collectionArrayObserverHandler(changeDetails, arr,
    createNewObjFunc, requestNewItemsCb, indexTranslater, afterModCb, stepCompletedCb) {
    //This function is constructed from Apple's documentation on how to apply
    //incremental changes.
    return new Promise((resolve, reject) => {
        if (changeDetails.hasIncrementalChanges !== undefined &&
            !changeDetails.hasIncrementalChanges) {
            return resolve(arr);
        }
        performInsertAndDelete();

        function performInsertAndDelete() {
            let lastIndex = (arr.length - 1);
            updateHandler(changeDetails.removedObjects, (updatedObj) => {
                const index = getObjectIndex(updatedObj, indexTranslater, arr, 'remove');
                if (index <= lastIndex && index >= 0) {
                    arr[index] = undefined;
                    afterModCb && afterModCb(arr, index, 'remove');
                } else {
                    //insertion is before our indecies, we need to increment
                    afterModCb && afterModCb(arr, index, 'remove');
                }
            });
            arr = arr.filter(obj => (obj !== undefined));
            stepCompletedCb && stepCompletedCb('remove', arr);

            lastIndex = (arr.length - 1);
            updateHandler(changeDetails.insertedObjects, (updatedObj) => {
                const index = getObjectIndex(updatedObj, indexTranslater, arr, 'insert');
                if (index <= (lastIndex + 1) && index >=
                    0) {
                    const newObj = createNewObjFunc(updatedObj
                        .obj);
                    arr.splice(index, 0, newObj);
                    afterModCb && afterModCb(arr, index, 'insert', newObj);
                } else {
                    //insertion is before our indecies, we need to increment
                    afterModCb && afterModCb(arr, index, 'insert');
                }
                lastIndex = (arr.length - 1);
            });
            stepCompletedCb && stepCompletedCb('insert', arr);


            if (requestNewItemsCb) {
                const missingIndecies = getMissingIndecies(changeDetails, arr, indexTranslater);
                stepCompletedCb && stepCompletedCb('fetch', missingIndecies);
                if (missingIndecies && missingIndecies.length) {
                    requestNewItemsCb(missingIndecies, (missingItems) => {
                        return performMoveAndChange(missingItems);
                    });
                } else {
                    return performMoveAndChange();
                }
            } else {
                return performMoveAndChange();
            }
        }

        function performMoveAndChange(missingItems) {
            //Moves will only happen if you update a property that affects the original sort order.
            if (changeDetails.moves) {
                let tempObj = {};
                let asyncMoves = [];
                enumerateMoves(arr, changeDetails,
                    indexTranslater, (fromIndex, toIndex, orginalFromIndex, originalToIndex) => {
                        const fromIndexIsOutsideOfRange = (fromIndex > (arr.length - 1) || fromIndex < 0);
                        const toIndexIsWithinRange = (toIndex <= (arr.length - 1) && toIndex >= 0);
                        if (fromIndexIsOutsideOfRange && !toIndexIsWithinRange) {
                            return;
                        }
                        let reInsertedCollectionIndex;
                        if (!tempObj[fromIndex] && arr[fromIndex] && arr[fromIndex] && arr[fromIndex].collectionIndex !== undefined) {
                            reInsertedCollectionIndex = arr[fromIndex].collectionIndex;
                        }

                        let fromObj = tempObj[fromIndex] || arr[fromIndex];
                        if (!fromObj && missingItems) {
                            fromObj = missingItems.find(item => item.collectionIndex === originalToIndex);
                        }
                        if (!fromObj) {
                            console.warn('Could not find aset with collectionIndex', orginalFromIndex);
                            afterModCb(arr, toIndex, 'remove');
                        }
                        tempObj[toIndex] = arr[toIndex];

                        if ((arr[toIndex] && arr[toIndex].collectionIndex !== undefined) &&
                            (fromObj && fromObj.collectionIndex !== undefined)) {
                            fromObj.collectionIndex = arr[toIndex].collectionIndex;
                        }

                        if (toIndex <= arr.length - 1 && toIndex >= 0) {
                            arr[toIndex] = fromObj;
                        }

                        if (reInsertedCollectionIndex !== undefined) {
                            arr[fromIndex] = {
                                collectionIndex: reInsertedCollectionIndex
                            }
                        }
                        arr = arr.filter(item => item !== undefined);
                    });
            }
            stepCompletedCb && stepCompletedCb('move', arr);

            let lastIndex = (arr.length - 1);
            updateHandler(changeDetails.changedObjects, (updatedObj) => {
                const index = getObjectIndex(updatedObj, indexTranslater, arr, 'change');
                if (index <= lastIndex && index >= 0) {
                    arr[index] = createNewObjFunc(updatedObj.obj);
                } 
            });
            stepCompletedCb && stepCompletedCb('change', arr);
            return resolve(arr);
        }
    });
} 