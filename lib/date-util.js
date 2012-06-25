function ISOStringInSweden(datestr) {
  var date = new Date(datestr);
  if (''+date === 'Invalid Date') return null;

  var tz = date.toLocaleString().match(/GMT([+-]\d\d\d\d) /)[1];

  return date.toISOString().substr(0, 19) + tz;
}


exports.ISOStringInSweden = ISOStringInSweden;