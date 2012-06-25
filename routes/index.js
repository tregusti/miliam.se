/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index', { title: 'Express' });
};


exports.entry = function(req, res) {
  require('../entry').load(req.params[0], req.params[1], req.params[2], function(entry) {
    res.json(entry);
  })
};