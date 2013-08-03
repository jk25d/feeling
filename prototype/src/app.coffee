express = require 'express'
app = express()



#### CONFIGURATION ####

require_auth = (req, res, next) ->
  res.send 401 unless req.session.user
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



#### COMMON ROUTES ####

app.get '/', (req,res) ->
  res.sendfile 'public/index3.html'

app.post '/login', (req,res) ->
  req.session.user = req.body.user_id
  res.json ok

app.get '/api/logout', (req,res) ->
  delete req.session.user
  res.json ok



#### GLOBAL DATA ####

_users = {}
_feelings = {}
_feeling_cur = 0
_comments = {}
_comment_cur = 0
_daily_words = {}
_float_feelings = {}
_float_feeling_cur = 0
_float_feeling_queue = []



#### ROUTES ####

app.get '/api/daily_words', (req,res) ->
  res.json ok: _daily_words

app.get '/api/feelings', (req,res) ->
  user = req.session.user
  mon = req.params.mon || new Date().getMonth() + 1
  n = req.params.n || 3

  res = _users[user].my_feelings.filter (id) ->
    between _feelings[id].time.getMonth(), month(mon, -n+1), mon
  req.json ok: res.map (id) -> _feelings.id

app.post '/api/feelings', (req,res) ->
  user = req.session.user
  word_id = req.body.word_id || ''
  content = req.body.content || ''
  return req.json fail: 'Invalid arguments' 
      unless word_id.length > 0 && content.length > 0

  _feelings[_feeling_cur] =
    user: user
    time: new Date()
    word_id: word_id
    content: content
    comment_id: []
  _users[user].feelings.push _feeling_cur
  _users[user].float_feelings.concat pop3_feelings
  _float_feelings[_float_feeling_cur] =
    feeling_id: _feeling_cur
    nforwards: 0
    remains: 3
  _float_feelings_queue.push _float_feeling_cur for [0..2]
  _daily_words[word_id]++
  _feeling_cur++
  _float_feeling_cur++
  req.json ok: true

app.get '/api/feelings/:id', (req,res) ->
  id = req.params.id
  feeling = _feelings[id]
  return req.json fail: "No such feeling: #{id}" 
      unless feeling
  req.json ok:
    id: id
    time: feeling.time
    word_id: feeling.word_id
    content: feeling.content
    comments: feeling.comments.map (id) -> _comments[id]

app.put '/api/comments/:id', (req,res) ->
  id = req.params.id
  return req.json fail: "No such comment #{id}" 
      unless _comments[id]
  _comments[id].keep = true
  req.json ok: true

app.get '/api/comments', (req,res) ->
  skip = req.params.skip || 0
  n = req.params.n || 10
  req.json ok: _comments[skip..skip+n-1]

app.get '/api/float_feelings', (req,res) ->
  user = req.session.user
  req.json ok: _users[user].float_feelings.map (id) ->
    id: id
    nforwards: _float_feelings[id].nforwards
    user: _feelings[_float_feelings[id].feeling_id].user
    time: _feelings[_float_feelings[id].feeling_id].time
    word_id: _feelings[_float_feelings[id].feeling_id].word_id
    content: _feelings[_float_feelings[id].feeling_id].content

app.put '/api/float_feelings/:id', (req,res) ->
  user = req.session.user
  _users[user].float_feelings = remove _users[user].float_feelings, id
  _float_feeling_queue.unshift id
  req.json ok: true

app.post '/api/float_feelings/:id/comments', (req,res) ->
  user = req.session.user
  feeling_id = req.params.id
  commentor_feeling = _users[user].feelings.pop
  _comments[_comment_cur] =
    user: user
    time: new Date()
    word_id: commentor_feeling ? _feelings[commentor_feeling].word_id : ''
    feeling_id: _float_feelings[id].feeling_id
  _users[user].float_feelings = remove _users[user].float_feelings, id
  _float_feelings[id].remains--
  delete _float_feelings.id if _float_feelings[id].remains <= 0
  _comment_cur++


#### UTILS ####

remove = (arr, x) -> arr.filter (a) -> a != x
between = (x, min, max) -> x >= min && x <= max
includes = (arr, x) ->
  for a in arr
    return true if a == x
  false
month = (mon, gap) -> ((mon-1) + 12 + gap) % 12 + 1
pop3_feelings = ->
  res = []
  for id in _float_feeling_queue
    break if res.length == 3
    res.push id unless includes res, id
  res

### OLD ROUTES ###


app.get '/api/thoughts', (req,res) ->
  userid = req.session.user
  thoughts = _users[userid]?.thoughts || []
  res.json thoughts.map (id) -> _thoughts[id]    

app.get '/api/allthoughts', (req,res) ->
  userid = req.session.user
  thoughts = _users[userid]?.other_thoughts || []
  res.json thoughts.map (id) -> _thoughts[id]

app.get '/api/allfeelings', (req,res) ->
  res.json _thoughts.map (data) -> data

app.post '/api/thoughts', (req,res) ->
  userid = req.session.user
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
  res.json ok
  


app.listen '3333'
console.log 'listening on 3333'
