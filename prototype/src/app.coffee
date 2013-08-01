express = require 'express'
app = express()

require_auth = (req, res, next) ->
  res.send 401 unless req.session.userid
  next()

log = (req, res, next) ->
  console.log req.path
  next()

app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.cookieSession(secret: 'deadbeef')
  app.all '/api/*', require_auth
  app.all '*', log
  app.use express.static("#{__dirname}/public")

_users = []
_thoughts = []
_thought_cur = 0

app.get '/', (req,res) ->
  res.sendfile 'public/index3.html'

app.get '/api/thoughts', (req,res) ->
  userid = req.session.userid
  thoughts = _users[userid]?.thoughts || []
  res.json thoughts.map (id) -> _thoughts[id]    

app.get '/api/allthoughts', (req,res) ->
  userid = req.session.userid
  thoughts = _users[userid]?.other_thoughts || []
  res.json thoughts.map (id) -> _thoughts[id]

app.get '/api/allfeelings', (req,res) ->
  res.json _thoughts.map (data) -> data

app.post '/api/thoughts', (req,res) ->
  userid = req.session.userid
  thought_id = _thought_cur++ 
  _thoughts[thought_id] =
    time: new Date()
    word: req.body.word
    feeltxt: req.body.feeltxt
    thought: req.body.thought
    user: userid

  _users[userid] ||= []
  thoughts = _users[userid].thoughts || []
  thoughts.push thought_id
  _users[userid]['thoughts'] = thoughts

  other_thoughts = _users[userid].other_thoughts || []
  for i in [_thoughts.length-1..0]
    if _thoughts[i] && _thoughts[i].user != userid
      other_thoughts.push i
      break
  _users[userid].other_thoughts = other_thoughts
  console.log other_thoughts
  res.json 'ok'
  
app.post '/login', (req,res) ->
  req.session.userid = req.body.userid
  res.json 'ok'

app.get '/api/logout', (req,res) ->
  delete req.session.userid
  res.json 'ok'

app.listen '3333'
console.log 'listening on 3333'
