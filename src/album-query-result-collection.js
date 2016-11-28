import Album from './album';
import AlbumQueryResultBase from './album-query-result-base';

export default class AlbumQueryResultCollection extends AlbumQueryResultBase {
    constructor(queryFetchResults, fetchParams, eventEmitter) {
        super();
        this.queryFetchResults = queryFetchResults;
        this.onChangeHandlers = this.queryFetchResults.map(qfr => qfr.onChange(
            this.onQueryResultChange.bind(this)));
    }

    get albums() {
        return this
            .queryFetchResults
            .reduce((arr, qfr) => {
                return arr.concat(qfr.albums);
            }, []);
    }

    onQueryResultChange(changeDetails, queryResult) {
        this.emit('onChange', changeDetails, () => {
            queryResult.applyChangeDetails(changeDetails);
            return this;
        }, undefined, queryResult);
    }
}
