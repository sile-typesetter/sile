const TOML = require('@iarna/toml')
const { exec } = require('node:child_process')

module.exports.readVersion = function (contents) {
  const data = TOML.parse(contents)
  return data.package.version
}

module.exports.writeVersion = function (contents, version) {
  exec('cargo-set-version set-version ' + version, (err, output) => {
    if (err) {
      console.error("Could not run Cargo subcommand to set version: ", err)
      return
    }
  })
  return contents
}
