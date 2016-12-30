function updateHandler(arr, cb) {
    if (arr) {
        for (let i = 0; i < arr.length; i++) {
            const updatedObj = arr[i];
            cb(updatedObj);
        }
    }
}
 
export function indeciesIsReversedNormalOrScrambled(arr, changeDetails) {
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

export function assetArrayObserverHandler(changeDetails, arr, createNewObjFunc) {
    const arrayOrder = indeciesIsReversedNormalOrScrambled(arr, changeDetails);
    if (arrayOrder === 'scrambled') {
        throw new Error(
            '[RNPhotosFramework] You can not use the automatic update function for change observing with scrambled or undefined indecies (property collectionIndex). Please submit the assets in their original order or do the update manully'
        );
        return;
    }
    let startIndex = 0;
    if(arr.length > 0) {
        startIndex = arrayOrder === 'normal' || arr.length === 0 ? arr[0].collectionIndex : arr[
        arr.length - 1].collectionIndex;
    }

    return collectionArrayObserverHandler(changeDetails, arr, createNewObjFunc,
        (index, arr, operation) => {

            let indexAffected = index + startIndex;
            if (arrayOrder === 'reversed') {
                indexAffected = (arr.length - (operation === 'insert' ? 0 : 1)) -
                    indexAffected;
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
        });
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

function getObjectIndex(updatedObj, indexTranslater, arr, operation) {
    const objectIndex = updatedObj.obj !== undefined && (updatedObj.obj.collectionIndex !==
        undefined) ? updatedObj.obj.collectionIndex : updatedObj.index;
    return indexTranslater !== undefined ? indexTranslater(
        objectIndex, arr, operation) : objectIndex;
}

export function collectionArrayObserverHandler(changeDetails, arr,
    createNewObjFunc, indexTranslater, afterModCb) {
    //This function is constructed from Apple's documentation on how to apply
    //incremental changes.

    let lastIndex = (arr.length - 1);
    updateHandler(changeDetails.removedObjects, (updatedObj) => {
        const index = getObjectIndex(updatedObj, indexTranslater, arr, 'remove');
        if (index <= lastIndex && index >= 0) {
            arr[index] = undefined;
            afterModCb && afterModCb(arr, index, 'remove');
        }
    });
    arr = arr.filter(obj => (obj !== undefined));

    lastIndex = (arr.length - 1);
    updateHandler(changeDetails.insertedObjects, (updatedObj) => {
        const index = getObjectIndex(updatedObj, indexTranslater, arr, 'insert');
        if (index <= (lastIndex + 1) && index >=
            0) {
            const newObj = createNewObjFunc(updatedObj
                .obj);
            arr.splice(index, 0, newObj);
            afterModCb && afterModCb(arr, index, 'insert', newObj);
        }
        lastIndex = (arr.length - 1);
    });

    //Moves will only happen if you update a property that affects the original sort order.
    if (changeDetails.moves) {
        let tempObj = {};
        for (let i = 0; i < changeDetails.moves.length; i = (i + 2)) {
            let fromIndex = changeDetails.moves[i];
            let toIndex = changeDetails.moves[i + 1];

            fromIndex = indexTranslater !== undefined ? indexTranslater(
                fromIndex) : fromIndex;
            toIndex = indexTranslater !== undefined ? indexTranslater(toIndex) :
                toIndex;

            const fromObj = tempObj[fromIndex] || arr[fromIndex];
            tempObj[toIndex] = arr[toIndex];
            arr[toIndex] = fromObj; 
        }
    }

    lastIndex = (arr.length - 1);
    updateHandler(changeDetails.changedObjects, (updatedObj) => {
        const index = getObjectIndex(updatedObj, indexTranslater, arr, 'change');
        if (index <= lastIndex && index >= 0) {
            arr[index] = createNewObjFunc(updatedObj.obj);
        }
    });
    return arr;
} 