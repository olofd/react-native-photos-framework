function updateHandler(arr, cb) {
    if (arr) {
        for (let i = 0; i < arr.length; i++) {
            const updatedObj = arr[i];
            cb(updatedObj);
        }
    }
}

export default function (changeDetails, arr, createNewObjFunc) {
    //This function is constructed from Apple's documentation on how to handle
    //incremental changes.
    let lastIndex = (arr.length - 1);
    updateHandler(changeDetails.removedObjects, (updatedObj) => {
        if (updatedObj.index <= lastIndex) {
            arr[updatedObj.index] = undefined;
        }
    });
    arr = arr.filter(obj => (obj !== undefined));

    lastIndex = (arr.length - 1);
    updateHandler(changeDetails.insertedObjects, (updatedObj) => {
        if (updatedObj.index <= (lastIndex + 1)) {
            arr.splice(updatedObj.index, 0, createNewObjFunc(updatedObj.obj));
            lastIndex = (arr.length - 1);
        }
    });

    //Moves will only happen if you update a property that affects the sortorder.
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

    lastIndex = (arr.length - 1);
    updateHandler(changeDetails.changedObjects, (updatedObj) => {
        if (updatedObj.index <= lastIndex) {
            arr[updatedObj.index] = createNewObjFunc(updatedObj.obj);
        }
    });
    return arr;
}
