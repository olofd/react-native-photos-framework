const rnpmConfig = require('./local-cli/core/config');
const link = require('./local-cli/link/link.js');
const fs = require('fs');
const xcode = require('xcode');
const path = require('path');
const getPlist = require('./local-cli/link/ios/getPlist');
const getPlistPath = require('./local-cli/link/ios/getPlistPath');
const plistParser = require('plist');

const config = {
    getProjectConfig: rnpmConfig.getProjectConfig,
    getDependencyConfig: rnpmConfig.getDependencyConfig,
};

link.func([], config);

const projectConfig = config.getProjectConfig(path.join(process.cwd(), '../../'));
const project = xcode.project(projectConfig.ios.pbxprojPath).parseSync();
const plist = getPlist(project, projectConfig.ios.sourceDir);
if(!plist.NSPhotoLibraryUsageDescription ) {
    plist.NSPhotoLibraryUsageDescription = 'Using photo library to select pictures';
}

fs.writeFileSync(
    getPlistPath(project, projectConfig.ios.sourceDir),
    plistParser.build(plist)
);

