const YAML = require('yaml')

module.exports.readVersion = function (contents) {
  const data = YAML.parse(contents)
  return data.runs.image.replace(/^.*:v/, '')
}

module.exports.writeVersion = function (contents, version) {
  const data = YAML.parse(contents)
  data.runs.image = data.runs.image.replace(/\d+\.\d+\.\d+$/, version)
  return YAML.stringify(data)
}
