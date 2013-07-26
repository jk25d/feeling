var application_root = __dirname,
    express = require("express"),
    path = require("path"),
    mongoose = require('mongoose');


var app = express.createServer();
mongoose.connect('mongodb://localhost/test');

var Schema = mongoose.Schema;  

var Feeling = new Schema({  
    feelId: { type: String, required: true },  
    userId: { type: String, required: true },  
    feelName: { type: String},  
    feelColor: { type: String},  
    comment: { type: String},  
    isPublic: { type: String},  
    favorite: { type: Number, default:0},  
    timestamp: { type: Date, default: Date.now }
});

var FeelingModel = mongoose.model('Feeling', Feeling);  



var config = require('./config').Config
//var feeling = require('./app/feeling.js').Feeling
//feeling.init("jerry");

app.configure(function () {
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.static(path.join(application_root, "public")));
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});



app.get('/api', function (req, res) {
  res.send('Ecomm API is running');
});

app.get('/api/feelings', function (req, res){
  return FeelingModel.find(function (err, feelings) {
    if (!err) {
      console.log(feelings);
      return res.send(feelings);
    } else {
      return console.log(err);
    }
  });
});


app.get('/api/myfeelings/:id', function (req, res){
  return FeelingModel.find({userId:req.params.id},function (err, feelings) {
    if (!err) {
      console.log(feelings);
      return res.send(feelings);
    } else {
      return console.log(err);
    }
  });
});

app.get('/api/favorites',function(req, res){
  var o = {};
  o.map = function () { emit(this.feelName ,1) }
  o.reduce = function (k, vals) { return k,vals.length }

  return FeelingModel.mapReduce(o, function (err, feelings) {
    if (!err) {
      console.log(feelings);
      return res.send(feelings);
    } else {
      return console.log(err);
    }
  });
});

app.post('/api/feelings', function (req, res){
  var feeling;
  console.log("POST: ");
  console.log(req.body);
  feeling = new FeelingModel({
    feelId: req.body.feelId,
    userId: req.body.userId,
    feelName: req.body.feelName,
    feelColor: req.body.feelColor,
    comment: req.body.comment,
    isPublic: req.body.isPublic,
  });
  feeling.save(function (err) {
    if (!err) {
      return console.log("created");
    } else {
      return console.log(err);
    }
  });
  return res.send(feeling);
});

app.get('/api/feelings/:id', function (req, res){
  return FeelingModel.findById(req.params.id, function (err, feeling) {
    if (!err) {
      console.log(feeling);
      return res.send(feeling);
    } else {
      return console.log(err);
    }
  });
});

app.put('/api/feelings/:id', function (req, res){
  return FeelingModel.findById(req.params.id, function (err, feeling) {
    feeling.comment = req.body.comment;
    feeling.isPublic = req.body.isPublic;
    return feeling.save(function (err) {
      if (!err) {
        console.log("updated");
      } else {
        console.log(err);
      }
      return res.send(feeling);
    });
  });
});

app.delete('/api/feelings/:id', function (req, res){
  return FeelingModel.findById(req.params.id, function (err, feeling) {
    return feeling.remove(function (err) {
      if (!err) {
        console.log("removed");
        return res.send('');
      } else {
        console.log(err);
      }
    });
  });
});





app.listen(6123)
