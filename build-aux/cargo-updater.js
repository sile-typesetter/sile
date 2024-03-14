const TOML = require('@iarna/toml')

module.exports.readVersion = function (contents) {
  const data = TOML.parse(contents)
  return data.package.version
}

module.exports.writeVersion = function (contents, version) {
  const data = TOML.parse(contents)
  data.package.version = version
  return TOML.stringify(data)
}
