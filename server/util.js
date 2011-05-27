function clone(obj) { 
  var clone = {};
  for (property in obj) clone[property] = obj[property];
  return clone;
}
exports.clone = clone;
