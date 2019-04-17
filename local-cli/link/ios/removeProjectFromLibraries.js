/**
 * Given an array of xcODEproj libraries and pbxFile,
 * it removes it from that group by comparing basenames
 *
 * Important: That function mutates `libraries` and it's not pure.
 * It's mainly due to limitations of `xcODE` library.
 */
module.exports = function removeProjectFromLibraries(libraries, file) {
  libraries.children = libraries.children.filter(library =>
    library.comment !== file.basename
  );
};
