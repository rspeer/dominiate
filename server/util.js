function clone(obj) { 
  var clone = {};
  clone.prototype = obj.prototype;
  for (property in obj) clone[property] = obj[property];
  return clone;
}
exports.clone = clone;
