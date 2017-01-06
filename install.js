const fs = require('fs');
const path = require('path');
const configPath = path.join(process.cwd(), '../../package.json');
if (fs.existsSync(configPath)) {
    const rnpmConfig = require('./local-cli/core/config');
    const link = require('./local-cli/link/link.js');
    const xcode = require('xcode');
    const getPlist = require('./local-cli/link/ios/getPlist');
    const getPlistPath = require('./local-cli/link/ios/getPlistPath');
    const plistParser = require('plist');

    const config = {
        getProjectConfig: rnpmConfig.getProjectConfig,
        getDependencyConfig: rnpmConfig.getDependencyConfig,
    };

    const projectConfig = config.getProjectConfig(path.join(process.cwd(), '../../'));
    const project = xcode.project(projectConfig.ios.pbxprojPath).parseSync();
    const plist = getPlist(project, projectConfig.ios.sourceDir);
    if (!plist.NSPhotoLibraryUsageDescription) {
        plist.NSPhotoLibraryUsageDescription = 'Using photo library to select pictures';
        console.log('Added NSPhotoLibraryUsageDescription to Info.plist');
    }

    fs.writeFileSync(
        getPlistPath(project, projectConfig.ios.sourceDir),
        plistParser.build(plist)
    );
}