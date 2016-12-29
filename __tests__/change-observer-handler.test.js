import {
    assetArrayObserverHandler,
    collectionArrayObserverHandler
} from '../src/change-observer-handler.js';

function toNumberedCollectionIndex(arr) {
    return arr.reduce((str, asset) => {
        return str += asset.collectionIndex.toString() + asset.id.toString();
    }, '');
}

test('should throw when input is scrambled', () => {
    const changeDetails = {
        insertedObjects: [{
            obj: {
                collectionIndex: 1
            }
        }]
    };
    const arr = [{
        collectionIndex: 1
    }, {
        collectionIndex: 0
    }, {
        collectionIndex: 2
    }];
    expect(() => {
        assetArrayObserverHandler(changeDetails, arr, (obj) => {});
    }).toThrow();
});


//START---------SINGULAR ADD--------------START

test('insert singular in middle of assetCollection with normal order', () => {
    const changeDetails = {
        insertedObjects: [{
            obj: {
                id: 'b',
                collectionIndex: 1
            }
        }]
    };
    const arr = [{
        id: 'a',
        collectionIndex: 0
    }, {
        id: 'c',
        collectionIndex: 1
    }, {
        id: 'd',
        collectionIndex: 2
    }];
    const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
        return obj;
    });
    expect(toNumberedCollectionIndex(result)).toBe('0a1b2c3d');
});

test('insert singular in middle of assetCollection with reversed order', () => {
    const changeDetails = {
        insertedObjects: [{
            obj: {
                id: 'b',
                collectionIndex: 2
            }
        }]
    };
    const arr = [{
        id: 'a',
        collectionIndex: 2
    }, {
        id: 'c',
        collectionIndex: 1
    }, {
        id: 'd',
        collectionIndex: 0
    }];
    const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
        return obj;
    });
    expect(toNumberedCollectionIndex(result)).toBe('3a2b1c0d');
});

//END---------SINGULAR ADD--------------END

//START---------PLURALIS ADD--------------START
test('insert multiple in middle of assetCollection with normal order', () => {
    const changeDetails = {
        insertedObjects: [{
            obj: {
                id: 'a',
                collectionIndex: 0
            }
        }, {
            obj: {
                id: 'c',
                collectionIndex: 2
            }
        }]
    };
    const arr = [{
        id: 'b',
        collectionIndex: 0
    }, {
        id: 'd',
        collectionIndex: 1
    }, {
        id: 'e',
        collectionIndex: 2
    }];
    const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
        return obj;
    });
    expect(toNumberedCollectionIndex(result)).toBe('0a1b2c3d4e');
});

test('insert multiple in middle of assetCollection with reversed order', () => {
    const changeDetails = {
        insertedObjects: [{
            obj: {
                id: 'd',
                collectionIndex: 3
            }
        }, {
            obj: {
                id: 'e',
                collectionIndex: 4
            }
        }]
    };
    const arr = [{
        id: 'c',
        collectionIndex: 2
    }, {
        id: 'b',
        collectionIndex: 1
    }, {
        id: 'a',
        collectionIndex: 0
    }];
    const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
        return obj;
    });
    expect(toNumberedCollectionIndex(result)).toBe('4e3d2c1b0a');
});
