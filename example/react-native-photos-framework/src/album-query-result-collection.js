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

    onQueryResultChange(changeDetails, updateFunc, queryResult) {
        this.emit('onChange', changeDetails, (callback) => {
            updateFunc();
            callback && callback(this);
        }, queryResult);
    }

    stopTracking() {
      return Promise.all(this.queryFetchResults.map(qfr => qfr.stopTracking()));
    }
}
