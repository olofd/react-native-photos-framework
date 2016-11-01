import Album from './album';
import commonSort from './common-sort';
import AlbumQueryResultBase from './album-query-result-base';

export default class AlbumQueryResultCollection extends AlbumQueryResultBase {
    constructor(queryFetchResults, fetchParams, eventEmitter) {
        super();
        this.queryFetchResults = queryFetchResults;
        this.onChangeHandlers = this.queryFetchResults.map(qfr => qfr.onChange(this.onQueryResultChange.bind(this)));
    }

    get albums() {
        return this
            .queryFetchResults
            .reduce((arr, qfr) => {
                return arr.concat(qfr.albums);
            }, []);
    }

    onQueryResultChange(changeDetails, queryResult) {
        if(this._changeHandler) {
            this._changeHandler(changeDetails, () => {
              queryResult.applyChangeDetails(changeDetails);
              return this;  
            }, undefined, queryResult);
        }
    }
}
