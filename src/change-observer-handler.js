function updateHandler(arr, cb) {
    if (arr) {
        for (let i = 0; i < arr.length; i++) {
            const updatedObj = arr[i];
            cb(updatedObj, i, arr);
        }
    }
}

export default function (changeDetails, arr, createNewObjFunc) {
    updateHandler(changeDetails.insertedObjects, (updatedObj, i) => {
        arr.splice(updatedObj.index, 0, createNewObjFunc(updatedObj.obj));
    });
    updateHandler(changeDetails.removedObjects, (updatedObj, i) => {
        arr.splice(updatedObj.index, 1);
    });
    if (changeDetails.moves) {
        let tempObj = {};
        for (let i = 0; i < changeDetails.moves.length; i = (i + 2)) {
            const fromIndex = changeDetails.moves[i];
            const toIndex = changeDetails.moves[i + 1];
            const fromObj = tempObj[fromIndex] || arr[fromIndex];
            tempObj[toIndex] = arr[toIndex];
            arr[toIndex] = fromObj;
        }
    }

    updateHandler(changeDetails.changedObjects, (updatedObj, i) => {
        arr[updatedObj.index] = createNewObjFunc(updatedObj.obj);
    });
    return arr;
}
