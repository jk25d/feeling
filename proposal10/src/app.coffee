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
  app.all '/auth/*', require_auth
  app.all '*', log
  app.use express.static("#{__dirname}/public")



#### COMMON ROUTES ####

app.get '/', (req,res) ->
  res.sendfile 'public/index.html' 

app.post '/sessions', (req,res) -> 
  req.session.user = req.body.user_id
  res.json ok: true

app.del '/sessions', (req,res) ->
  res.send 401 unless req.session.user
  delete req.session.user
  res.json ok: true

app.post '/users', (req,res) ->
  res.json ok: true


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
_words =
  'w00': {desc: '외롭다', color: '#c6aae2'}
  'w01': {desc: '쓸쓸하다', color: '#ffc6e2'}
  'w02': {desc: '기쁘다', color: '#aaaae2'}
  'w03': {desc: '기운차다', color: '#8daae2'}
  'w04': {desc: '만족스럽다', color: '#ffff8d'}
  'w05': {desc: '삶이힘들다', color: '#336699'}
  'w06': {desc: '두렵다', color: '#ffc6c6'}
  'w07': {desc: '초조하다', color: '#c6ffff'}


#### ROUTES ####

app.get '/auth/info', (req,res) ->
  res.json ok:
    words: _words
    live_words: [ {'w03': 10}, {'w04': 3}, {'w07': 2}, {'w01': 8} ]
    available_feels: 10
    simailar_users: [
      {user_id: 'uuuuu', similarity: 1.7, word_id: 'w02'},
      {user_id: 'ppp', similarity: 2.7, word_id: 'w03'},
      {user_id: 'asdfef', similarity: 3.7, word_id: 'w04'},
      {user_id: 'f73ur', similarity: 2.1, word_id: 'w06'},
      {user_id: 'myidififi', similarity: 4.7, word_id: 'w02'} 
    ]

app.get '/auth/my', (req,res) ->
  user = req.session.user
  mon = req.params.skip || 0
  n = req.params.n || 3
  res.json ok: [
    { id: 0, time: 0, user_id: 'uuuuu', word_id: 'w03',\
      content: 'aefe aefef fa',\
      comments: [
        { type: 'heart', content: '블블블',\ 
          user_id: 'asdf', time: 0, liked: 1},
        { type: 'comment', content: '블블블asdf',\ 
          user_id: 'qwer', time: 0, liked: 0}
      ]
    }
  ]

app.get '/auth/ur', (req,res) ->
  user = req.session.user
  mon = req.params.skip || 0
  n = req.params.n || 3
  res.json ok: [
    { id: 1, time: 0, user_id: 'f23rf', word_id: 'w03',\
      content: '블라블라블라',\
      comments: [
        { id: 0, type: 'heart', content: '블블블',\ 
          user_id: 'asdf', time: 0, liked: 1}
      ]
    }
  ]

app.get '/auth/ur/news', (req,res) ->
  user = req.session.user
  mon = req.params.skip || 0
  n = req.params.n || 3
  res.json ok: [
    { id: 2, time: 0, user_id: 'qwer', word_id: 'w03',\
      content: '블라블라블라',\
      comments: []
    }
  ]

app.post '/auth/feels/:id/comments', (req,res) ->
  id = req.params.id
  user = req.session.user
  type = req.body.type        # TODO: valid check
  content = req.body.content  # TODO: valid check
  req.json ok: true

app.put '/auth/feels/:id/comments/:comment_id', (req,res) ->
  id = req.params.id
  comment_id = req.params.comment_id
  user = req.session.user
  likeit = req.body.likeit
  req.json ok: true



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

app.listen '3333'
console.log 'listening on 3333'

