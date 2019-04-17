/**
 * For all files that are created and referenced from another `.xcODEproj` -
 * a new PBXItemContainerProxy is created that contains `containerPortal` value
 * which equals to xcODEproj file.uuid from PBXFileReference section.
 */
module.exports = function removeFromPbxItemContainerProxySection(project, file) {
  const section = project.hash.project.objects.PBXContainerItemProxy;

  for (var key of Object.keys(section)) {
    if (section[key].containerPortal === file.uuid) {
      delete section[key];
    }
  }

  return;
};
