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
});

//END---------SINGULAR REMOVE--------------END

//START---------PLURALIS REMOVE--------------START
describe('PLURALIS REMOVE', () => {
    it('remove multiple in middle of assetCollection with normal order', () => {
        const changeDetails = {
            removedObjects: [{
                obj: {
                    id: 'a',
                    collectionIndex: 1
                }
            }, {
                obj: {
                    id: 'c',
                    collectionIndex: 3
                }
            }]
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
            removedObjects: [{
                obj: {
                    id: 'c',
                    collectionIndex: 2
                }
            }, {
                obj: {
                    id: 'a',
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
            expect(toNumberedCollectionIndex(result)).toBe('0b');
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
//END---------EDGES--------------END

//START---------OUTSIDE INDEX MOVE--------------START
describe('OUTSIDE INDEX MOVE', () => {
    it('move asset from outside of index bounds should trigger fetch request', () => {
        //Changes in position always happens like this, in paired atomic steps:
        const changeDetails = {
            moves: [1, 5, 5, 1, 5, 1, 1, 5]
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
        const result = assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        });
        
        let f = jest.fn();

        return assetArrayObserverHandler(changeDetails, arr, (obj) => {
            return obj;
        }, f).then((result) => {
            expect(f).toHaveBeenCalledWith([5], expect.any(Function));
        });

    });

    xit('move singular in middle of assetCollection with reversed order', () => {
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


//END--------------------EDGE CASES AND OUTSIDE INDEX CHANGES--------------------END