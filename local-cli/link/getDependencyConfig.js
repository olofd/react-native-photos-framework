/**
 * Given an array of dependencies - it returns their RNPM config
 * if they were valid.
 */
module.exports = function getDependencyConfig(config, deps, root) {
  return deps.reduce((acc, name) => {
    try {
      return acc.concat({
        config: config.getDependencyConfig(name, root),
        name,
      });
    } catch (err) {
      console.log(err);
      return acc;
    }
  }, []);
};
