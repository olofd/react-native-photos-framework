import {assetArrayObserverHandler, collectionArrayObserverHandler} from '../src/change-observer-handler.js';

function toNumberedCollectionIndex(arr) {
    return arr.reduce((str, asset) => {
        return str += asset.collectionIndex.toString() + asset.id.toString();
    }, '');
}

it('should throw when input is scrambled', () => {
    const changeDetails = {
        insertedObjects: [
            {
                obj: {
                    collectionIndex: 1
                }
            }
        ]
    };
    const arr = [
        {
            collectionIndex: 1
        }, {
            collectionIndex: 0
        }, {
            collectionIndex: 2
        }
    ];
    expect(() => {
        assetArrayObserverHandler(changeDetails, arr, (obj) => {});
    }).toThrow();
});

//START---------SINGULAR ADD--------------START
describe('SINGULAR ADD', () => {
    it('insert singular in middle of assetCollection with normal order', () => {
        const changeDetails = {
            insertedObjects: [
                {
                    obj: {
                        id: 'b',
                        collectionIndex: 1
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'a',
                collectionIndex: 0
            }, {
                id: 'c',
                collectionIndex: 1
            }, {
                id: 'd',
                collectionIndex: 2
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('0a1b2c3d');
    });

    it('insert singular in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            insertedObjects: [
                {
                    obj: {
                        id: 'b',
                        collectionIndex: 2
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'a',
                collectionIndex: 2
            }, {
                id: 'c',
                collectionIndex: 1
            }, {
                id: 'd',
                collectionIndex: 0
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('3a2b1c0d');
    });
});
//END---------SINGULAR ADD--------------END

//START---------PLURALIS ADD--------------START
describe('PLURALIS ADD', () => {
    it('insert multiple in middle of assetCollection with normal order', () => {
        const changeDetails = {
            insertedObjects: [
                {
                    obj: {
                        id: 'a',
                        collectionIndex: 0
                    }
                }, {
                    obj: {
                        id: 'c',
                        collectionIndex: 2
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'b',
                collectionIndex: 0
            }, {
                id: 'd',
                collectionIndex: 1
            }, {
                id: 'e',
                collectionIndex: 2
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('0a1b2c3d4e');
    });

    it('insert multiple in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            insertedObjects: [
                {
                    obj: {
                        id: 'd',
                        collectionIndex: 3
                    }
                }, {
                    obj: {
                        id: 'e',
                        collectionIndex: 4
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'c',
                collectionIndex: 2
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'a',
                collectionIndex: 0
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('4e3d2c1b0a');
    });
});
//END---------PLURALIS ADD--------------END

//START---------SINGULAR REMOVE--------------START
describe('SINGULAR REMOVE', () => {
    it('remove singular in middle of assetCollection with normal order', () => {
        const changeDetails = {
            removedObjects: [
                {
                    obj: {
                        id: 'b',
                        collectionIndex: 1
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'a',
                collectionIndex: 0
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'c',
                collectionIndex: 2
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('0a1c');
    });

    it('remove singular in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            removedObjects: [
                {
                    obj: {
                        id: 'c',
                        collectionIndex: 2
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'c',
                collectionIndex: 2
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'a',
                collectionIndex: 0
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('1b0a');
    });
});

//END---------SINGULAR REMOVE--------------END

//START---------PLURALIS REMOVE--------------START
describe('PLURALIS REMOVE', () => {
    it('remove multiple in middle of assetCollection with normal order', () => {
        const changeDetails = {
            removedObjects: [
                {
                    obj: {
                        id: 'a',
                        collectionIndex: 0
                    }
                }, {
                    obj: {
                        id: 'c',
                        collectionIndex: 2
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'a',
                collectionIndex: 0
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'c',
                collectionIndex: 2
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('0b');
    }); 

    it('remove multiple in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            removedObjects: [
                {
                    obj: {
                        id: 'c',
                        collectionIndex: 2
                    }
                }, {
                    obj: {
                        id: 'a',
                        collectionIndex: 0
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'c',
                collectionIndex: 2
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'a',
                collectionIndex: 0
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('0b');
    });
});
//END---------PLURALIS REMOVE--------------END

//START---------SINGULAR CHANGE--------------START
describe('SINGULAR CHANGE', () => {
    it('change singular in middle of assetCollection with normal order', () => {
        const changeDetails = {
            changedObjects: [
                {
                    obj: {
                        id: 'b-changed',
                        collectionIndex: 1
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'a',
                collectionIndex: 0
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'c',
                collectionIndex: 2
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('0a1b-changed2c');
    });

    it('change singular in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            changedObjects: [
                { 
                    obj: {
                        id: 'a-changed',
                        collectionIndex: 0
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'c',
                collectionIndex: 2
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'a',
                collectionIndex: 0
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('2c1b0a-changed');
    });
});

//END---------SINGULAR CHANGE--------------END

//START---------PLURALIS CHANGE--------------START
describe('PLURALIS CHANGE', () => {
    it('change multiple in middle of assetCollection with normal order', () => {
        const changeDetails = {
            changedObjects: [
                {
                    obj: {
                        id: 'a-changed',
                        collectionIndex: 0
                    }
                }, {
                    obj: {
                        id: 'c-changed',
                        collectionIndex: 2
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'a',
                collectionIndex: 0
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'c',
                collectionIndex: 2
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('0a-changed1b2c-changed');
    }); 

    it('change multiple in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            changedObjects: [
                {
                    obj: {
                        id: 'c-changed',
                        collectionIndex: 2
                    }
                }, {
                    obj: {
                        id: 'a-changed',
                        collectionIndex: 0
                    }
                }
            ]
        };
        const arr = [
            {
                id: 'c',
                collectionIndex: 2
            }, {
                id: 'b',
                collectionIndex: 1
            }, {
                id: 'a',
                collectionIndex: 0
            }
        ];
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        expect(toNumberedCollectionIndex(result)).toBe('2c-changed1b0a-changed');
    });
});
//END---------PLURALIS CHANGE--------------END
