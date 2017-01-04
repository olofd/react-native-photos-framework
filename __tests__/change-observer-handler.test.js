import {
    assetArrayObserverHandler,
    collectionArrayObserverHandler
} from '../src/change-observer-handler.js';

function toNumberedCollectionIndex(arr) {
    return arr.reduce((str, asset) => {
        if (!asset || asset.collectionIndex === undefined || asset.id === undefined) {
            return 'ERROR';
        }
        return str += asset.collectionIndex.toString() + asset.id.toString();
    }, '');
}

//START--------------------BASIC FUNCTIONALLITY--------------------START

//START---------SINGULAR ADD--------------START
describe('SINGULAR ADD', () => {
    it('insert singular in middle of assetCollection with normal order starting from 0', () => {
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

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1b2c3d');
        });
    });

    it('insert singular before array starts should not insert only increment collectionIndecies', () => {
        const changeDetails = {
            insertedObjects: [{
                obj: {
                    id: 'a',
                    collectionIndex: 0
                }
            }]
        };
        const arr = [{
            id: 'b',
            collectionIndex: 3
        }, {
            id: 'c',
            collectionIndex: 4
        }, {
            id: 'd',
            collectionIndex: 5
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('4b5c6d');
        });
    });

    it('insert singular before array starts should not insert only increment collectionIndecies', () => {
        const changeDetails = {
            insertedObjects: [{
                obj: {
                    id: 'a',
                    collectionIndex: 0
                }
            }]
        };
        const arr = [{
            id: 'd',
            collectionIndex: 8
        }, {
            id: 'c',
            collectionIndex: 7
        }, {
            id: 'b',
            collectionIndex: 6
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('9d8c7b');
        });
    });

    it('insert singular in middle of assetCollection with normal order starting from 3', () => {
        const changeDetails = {
            insertedObjects: [{
                obj: {
                    id: 'b',
                    collectionIndex: 4
                }
            }]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 3
        }, {
            id: 'c',
            collectionIndex: 4
        }, {
            id: 'd',
            collectionIndex: 5
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('3a4b5c6d');
        });
    });

    it('insert singular in middle of assetCollection with reversed order', () => {
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

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('3a2b1c0d');
        });
    });
});
//END---------SINGULAR ADD--------------END

//START---------PLURALIS ADD--------------START
describe('PLURALIS ADD', () => {
    it('insert multiple in middle of assetCollection with normal order', () => {
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

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1b2c3d4e');
        });
    });

    it('insert multiple in middle of assetCollection with reversed order', () => {
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

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('4e3d2c1b0a');
        });
    });

    it('insert multiple in empty collection and expect reversed order', () => {
        const changeDetails = {
            insertedObjects: [{
                obj: {
                    id: 'b',
                    collectionIndex: 0
                }
            }, {
                obj: {
                    id: 'a',
                    collectionIndex: 1
                }
            }]
        };
        const arr = [];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, undefined, 'reversed').then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('1a0b');
        });
    });

});
//END---------PLURALIS ADD--------------END

//START---------SINGULAR REMOVE--------------START
describe('SINGULAR REMOVE', () => {
    it('remove singular in middle of assetCollection with normal order', () => {
        const changeDetails = {
            removedObjects: [{
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
            id: 'b',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1c');
        });
    });

    it('remove singular in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            removedObjects: [{
                obj: {
                    id: 'c',
                    collectionIndex: 2
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

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('1b0a');
        });
    });

    it('remove singular before array starts should not remove only decrement collectionIndecies, normal', () => {
        const changeDetails = {
            removedObjects: [{
                obj: {
                    id: 'a',
                    collectionIndex: 0
                }
            }]
        };
        const arr = [{
            id: 'b',
            collectionIndex: 7
        }, {
            id: 'c',
            collectionIndex: 8
        }, {
            id: 'd',
            collectionIndex: 9
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('6b7c8d');
        });
    });

    it('remove singular before array starts should not remove only decrement collectionIndecies, reversed', () => {
        const changeDetails = {
            removedObjects: [{
                obj: {
                    id: 'a',
                    collectionIndex: 0
                }
            }]
        };
        const arr = [{
            id: 'd',
            collectionIndex: 3
        }, {
            id: 'c',
            collectionIndex: 2
        }, {
            id: 'b',
            collectionIndex: 1
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('2d1c0b');
        });
    });
});

//END---------SINGULAR REMOVE--------------END

//START---------PLURALIS REMOVE--------------START
describe('PLURALIS REMOVE', () => {
    it('remove multiple in middle of assetCollection with normal order', () => {
        const changeDetails = {
            removedObjects: [
                //1b2c
                {
                    obj: {
                        id: 'a',
                        collectionIndex: 1
                    }
                },
                //1b
                {
                    obj: {
                        id: 'c',
                        collectionIndex: 3
                    }
                }
            ]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 1
        }, {
            id: 'b',
            collectionIndex: 2
        }, {
            id: 'c',
            collectionIndex: 3
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('1b');
        });
    });

    it('remove multiple in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            removedObjects: [
                //2b1a
                {
                    obj: {
                        id: 'c',
                        collectionIndex: 3
                    }
                }, {
                    obj: {
                        id: 'a',
                        collectionIndex: 1
                    }
                }
            ]
        };
        const arr = [{
            id: 'c',
            collectionIndex: 3
        }, {
            id: 'b',
            collectionIndex: 2
        }, {
            id: 'a',
            collectionIndex: 1
        }];
        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('1b');
        });
    });
});
//END---------PLURALIS REMOVE--------------END

//START---------SINGULAR CHANGE--------------START
describe('SINGULAR CHANGE', () => {
    it('change singular in middle of assetCollection with normal order', () => {
        const changeDetails = {
            changedObjects: [{
                obj: {
                    id: 'b-changed',
                    collectionIndex: 1
                }
            }]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 0
        }, {
            id: 'b',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1b-changed2c');
        });
    });

    it('change singular in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            changedObjects: [{
                obj: {
                    id: 'a-changed',
                    collectionIndex: 0
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
        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('2c1b0a-changed');
        });
    });
});

//END---------SINGULAR CHANGE--------------END

//START---------PLURALIS CHANGE--------------START
describe('PLURALIS CHANGE', () => {
    it('change multiple in middle of assetCollection with normal order', () => {
        const changeDetails = {
            changedObjects: [{
                obj: {
                    id: 'a-changed',
                    collectionIndex: 0
                }
            }, {
                obj: {
                    id: 'c-changed',
                    collectionIndex: 2
                }
            }]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 0
        }, {
            id: 'b',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }];
        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a-changed1b2c-changed');
        });
    });

    it('change multiple in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            changedObjects: [{
                obj: {
                    id: 'c-changed',
                    collectionIndex: 2
                }
            }, {
                obj: {
                    id: 'a-changed',
                    collectionIndex: 0
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

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('2c-changed1b0a-changed');
        });
    });
});
//END---------PLURALIS CHANGE--------------END

//START---------SINGULAR MOVE--------------START
describe('SINGULAR MOVE', () => {
    it('move singular in middle of assetCollection with normal order', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [1, 2, 2, 1]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 0
        }, {
            id: 'b',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }];
        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1c2b');
        });
    });

    it('move singular in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            moves: [1, 2, 2, 1]
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
        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('2b1c0a');
        });
    });
});

//END---------SINGULAR MOVE--------------END

//START---------PLURALIS MOVE--------------START
describe('PLURALIS MOVE', () => {
    it('move pluralis in middle of assetCollection with normal order', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [0, 2, 2, 0, 3, 1, 1, 3]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 0
        }, {
            id: 'b',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }, {
            id: 'd',
            collectionIndex: 3
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0c1d2a3b');
        });
    });

    it('move pluralis in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            moves: [0, 2, 2, 0, 3, 1, 1, 3]
        };
        const arr = [{
            id: 'd',
            collectionIndex: 3
        }, {
            id: 'c',
            collectionIndex: 2
        }, {
            id: 'b',
            collectionIndex: 1
        }, {
            id: 'a',
            collectionIndex: 0
        }];
        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('3b2a1d0c');
        });
    });
});

//END---------PLURALIS MOVE--------------END
//END--------------------BASIC FUNCTIONALLITY--------------------END


//START--------------------EDGE CASES AND OUTSIDE INDEX CHANGES--------------------START
//START---------EDGES--------------START
describe('ERRONEOUS INPUT', () => {
    it('should throw when input is scrambled', () => {
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
            return assetArrayObserverHandler(changeDetails, arr, (obj) => {});
        }).toThrow();
    });
});

it('should do nothing to input if hasIncrementalChanges is false', () => {
    const changeDetails = {
        hasIncrementalChanges: false,
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

    return assetArrayObserverHandler(changeDetails, arr, (obj) => {
        return obj;
    }).then((result) => {
        expect(toNumberedCollectionIndex(result)).toBe('0a1c2d');
    });
});
//END---------EDGES--------------END

//START---------OUTSIDE INDEX MOVE--------------START
describe('OUTSIDE INDEX MOVE', () => {
    it('move asset from outside of index bounds should trigger fetch request', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [1, 3, 3, 1]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 0
        }, {
            id: 'b',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }];

        let f = jest.fn();

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, (missingIndecies, finnishFunc) => {
            expect(missingIndecies[0]).toBe(1);
            finnishFunc();
        }).then((result) => {});
    });

    it('moves outside of collection should not change collection', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [5, 6, 6, 7]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 1
        }, {
            id: 'b',
            collectionIndex: 2
        }, {
            id: 'c',
            collectionIndex: 3
        }];

        let f = jest.fn();

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, f).then((result) => {
            expect(f).not.toHaveBeenCalled();
            expect(toNumberedCollectionIndex(result)).toBe('1a2b3c');
        });
    });

    it('moves from side to side should not change collection', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [0, 4, 4, 0]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 1
        }, {
            id: 'b',
            collectionIndex: 2
        }, {
            id: 'c',
            collectionIndex: 3
        }];

        let f = jest.fn();

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, f).then((result) => {
            expect(f).not.toHaveBeenCalled();
            expect(toNumberedCollectionIndex(result)).toBe('1a2b3c');
        });
    });

    it('move singular asset from outside of index bounds should trigger fetch request and insert that index', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [1, 5, 5, 1]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 0
        }, {
            id: 'e',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, (arrayOfMissingIndecies, finnishFunc) => {
            return finnishFunc(arrayOfMissingIndecies.map((index) => {
                return {
                    collectionIndex: index,
                    id: 'b'
                }
            }));
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1b2c');
        });
    });

    it('move pluralis assets from outside of index bounds should trigger fetch request and insert at those indecies', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [5, 1, 1, 5, 2, 7, 7, 2]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 0
        }, {
            id: 'e',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, (arrayOfMissingIndecies, finnishFunc) => {
            return finnishFunc(arrayOfMissingIndecies.map((index) => {
                return {
                    collectionIndex: index,
                    id: index === 1 ? 'b' : 'c'
                }
            }));
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1b2c');
        });
    });

    it('move pluralis assets from outside of index bounds, if asset is not returned return non-error-output', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [5, 1, 1, 5, 2, 7, 7, 2]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 0
        }, {
            id: 'e',
            collectionIndex: 1
        }, {
            id: 'c',
            collectionIndex: 2
        }, {
            id: 'd',
            collectionIndex: 3
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, (arrayOfMissingIndecies, finnishFunc) => {
            return finnishFunc([{
                collectionIndex: 1,
                id: 'b'
            }]);
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1b2d');
        });
    });

    it('should be able to handle simple out of index move', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [1, 0, 0, 1]
        };
        const arr = [{
            id: 'c',
            collectionIndex: 2
        }, {
            id: 'a',
            collectionIndex: 1
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, (arrayOfMissingIndecies, finnishFunc) => {
            expect(arrayOfMissingIndecies[0]).toBe(1);
            finnishFunc([{
                collectionIndex: 1,
                id: 'b'
            }]);
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('2c1b');
        });
    });

    it('move singular in middle of assetCollection with reversed order', () => {
        const changeDetails = {
            moves: [1, 2, 2, 1]
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

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('2b1c0a');
        });
    });
});

//END---------OUTSIDE INDEX MOVE--------------END

//START---------MIXED OPAERTAIONS--------------START

describe('MIXED OPERATIONS', () => {
    it('Handle a mixed operation with REMOVE, INSERT, MOVE and CHANGE', () => {
        const changeDetails = {
            removedObjects: [{
                obj: {
                    id: 'c',
                    collectionIndex: 1
                }
            }],
            insertedObjects: [{
                obj: {
                    id: 'x',
                    collectionIndex: 0
                }
            }],
            moves: [0, 1, 1, 0, 9, 7, 7, 9],
            changedObjects: [{
                obj: {
                    id: 'k',
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

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, () => {}, 'normal', (step, arr) => {
            if (step === 'remove') {
                expect(toNumberedCollectionIndex(arr)).toBe('0a1d');
            }
            if (step === 'insert') {
                expect(toNumberedCollectionIndex(arr)).toBe('0x1a2d');
            }
            if (step === 'move') {
                expect(toNumberedCollectionIndex(arr)).toBe('0a1x2d');
            }
            if (step === 'change') {
                expect(toNumberedCollectionIndex(arr)).toBe('0a1k2d');
            }
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('0a1k2d');
        });
    });

    it('Handle a mixed operation with REMOVE, INSERT, MOVE and CHANGE with normal indecies and fetches', () => {
        const changeDetails = {
            insertedObjects: [
                //6g5f4d
                {
                    obj: {
                        id: 'a',
                        collectionIndex: 0
                    }
                }, {
                    obj: {
                        id: 'e',
                        collectionIndex: 4
                    }
                }
            ]
        };
        const arr = [{
            id: 'd',
            collectionIndex: 3
        }, {
            id: 'f',
            collectionIndex: 4
        }, {
            id: 'g',
            collectionIndex: 5
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, () => {}, 'normal', (step, arr) => {
            if (step === 'insert') {
                expect(toNumberedCollectionIndex(arr)).toBe('4e5d6f7g');
            }
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('4e5d6f7g');
        });
    });

    it('Handle a mixed operation with REMOVE, INSERT, MOVE and CHANGE with reverse indecies and fetches', () => {
        const changeDetails = {
            insertedObjects: [
                //6g5f4d
                {
                    obj: {
                        id: 'a',
                        collectionIndex: 0
                    }
                }, {
                    obj: {
                        id: 'e',
                        collectionIndex: 4
                    }
                }
            ]
        };
        const arr = [{
            id: 'g',
            collectionIndex: 5
        }, {
            id: 'f',
            collectionIndex: 4
        }, {
            id: 'd',
            collectionIndex: 3
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, () => {}, 'normal', (step, arr) => {
            if (step === 'insert') {
                expect(toNumberedCollectionIndex(arr)).toBe('7g6f5d4e');
            }
        }).then((result) => {
            expect(toNumberedCollectionIndex(result)).toBe('7g6f5d4e');
        });
    });

    it('Handle a mixed operation with REMOVE, INSERT, MOVE and CHANGE with reverse indecies and fetches', () => {
        const changeDetails = {
            removedObjects: [{
                obj: {
                    id: 'd',
                    collectionIndex: 3
                }
            }],
            insertedObjects: [{
                obj: {
                    id: 'q',
                    collectionIndex: 0
                }
            }, {
                obj: {
                    id: 'x',
                    collectionIndex: 9
                }
            }, {
                obj: {
                    id: 'g',
                    collectionIndex: 6
                }
            }, {
                obj: {
                    id: 'h',
                    collectionIndex: 4
                }
            }],
            moves: [3, 4, 4, 3],
            changedObjects: [{
                obj: {
                    id: 'k',
                    collectionIndex: 5
                }
            }]
        };
        const arr = [{
            id: 'a',
            collectionIndex: 3
        }, {
            id: 'c',
            collectionIndex: 4
        }, {
            id: 'd',
            collectionIndex: 5
        }];

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, (indecies, finnishFunc) => {
            expect(indecies[0]).toBe(4);
            finnishFunc([{
                collectionIndex: 4,
                id: 'q'
            }]);
        }, 'normal', (step, arr) => {
            if (step === 'remove') {
                expect(toNumberedCollectionIndex(arr)).toBe('3c4d');
            }
            if (step === 'insert') {
                expect(toNumberedCollectionIndex(arr)).toBe('4h5c6d7g');
            }
            if (step === 'move') {
                expect(toNumberedCollectionIndex(arr)).toBe('4q5c6d7g');
            }
            if (step === 'change') {
                expect(toNumberedCollectionIndex(arr)).toBe('4q5k6d7g');
            }
        }).then((result) => {
             expect(toNumberedCollectionIndex(result)).toBe('4q5k6d7g');
        });
    });
});

it('should do nothing to input if hasIncrementalChanges is false', () => {
    const changeDetails = {
        hasIncrementalChanges: false,
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

    return assetArrayObserverHandler(changeDetails, arr, (obj) => {
        return obj;
    }).then((result) => {
        expect(toNumberedCollectionIndex(result)).toBe('0a1c2d');
    });
});

//END---------MIXED OPAERTAIONS--------------END


//END--------------------EDGE CASES AND OUTSIDE INDEX CHANGES--------------------END