express = require 'express'
app = express()



#### CONFIGURATION ####

require_auth = (req, res, next) ->
  console.log "auth: #{req.session.user}"
  res.send 401 unless req.session.user
  next()

app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.cookieSession(secret: 'deadbeef')
  app.use express.logger { format: ':method :url' }
  app.use app.router
  app.all '/api/*', require_auth
  app.use express.static("#{__dirname}/public")


#### COMMON ROUTES ####

app.get '/', (req,res) ->
  res.sendfile 'public/index.html' 

app.get '/sessions', (req,res) ->
  if req.session.user
    res.json { user_id: (req.session.user || false) }
  else
    res.send 401

app.post '/sessions', (req,res) -> 
  req.session.user = req.body.user_id
  password = req.body.password
  res.json {user: req.session.user}

app.del '/sessions', (req,res) ->
  if req.session.user
    delete req.session.user
    res.json {}
  else
    res.send 401

app.post '/users', (req,res) ->
  res.json {}


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

_my_time=0
_my_id=0
_rcv_id=0


#### ROUTES ####

app.get '/api/me', (req,res) ->
  res.json
    user_id: req.session.user
    n_available_feelings: 3

app.get '/api/live_feelings', (req,res) ->
  res.json \
    [ {user_id: 'uuuuu', similarity: 1.7, word_id: rw()},
      {user_id: 'ppp', similarity: 2.7, word_id: rw()},
      {user_id: 'myidififi', similarity: 4.7, word_id: rw()},
      {user_id: 'myidififi', similarity: 0, word_id: rw()},
      {user_id: 'myidififi', similarity: 0, word_id: rw()},
      {user_id: 'myidififi', similarity: 0, word_id: rw()},
      {user_id: 'asdfef', similarity: 3.7, word_id: rw()},
      {user_id: 'f73ur', similarity: 2.1, word_id: rw()},
      {user_id: 'myidififi', similarity: 0, word_id: rw()},
      {user_id: 'myidififi', similarity: 0, word_id: rw()},
      {user_id: 'myidififi', similarity: 0, word_id: rw()},
      {user_id: 'myidififi', similarity: 0, word_id: rw()},
      {user_id: 'myidififi', similarity: 0, word_id: rw()}
    ]

app.get '/api/associates', (req,res) ->
  res.json \
    [ {user_id: 'uuuuu', similarity: 1.7, word_id: rw()},
      {user_id: 'ppp', similarity: 2.7, word_id: rw()},
      {user_id: 'asdfef', similarity: 3.7, word_id: rw()},
      {user_id: 'f73ur', similarity: 2.1, word_id: rw()},
      {user_id: 'myidififi', similarity: 4.7, word_id: rw()}
    ]

app.get '/api/my_feelings', (req,res) ->
  user = req.session.user
  mon = req.params.skip || 0
  n = req.params.n || 3
  res.json \
    [ { id: _my_id++, time: _my_time++, user_id: 'uuuuu', word_id: rw(),\
        content: 'aefe aefef fa',\
        comments: [
          { type: 'heart', content: '블블블',\ 
            user_id: 'asdf', time: 0, like: true},
          { type: 'comment', content: '블블블asdf',\ 
            user_id: 'qwer', time: 0, like: false}
        ]
      },
      { id: _my_id++, time: _my_time++, user_id: 'uuuuu', word_id: rw(),\
        content: 'aefe aefef fa',\
        comments: [
          { type: 'heart', content: '블블블',\ 
            user_id: 'asdf', time: 0, like: true},
          { type: 'comment', content: '블블블asdf',\ 
            user_id: 'qwer', time: 0, like: false}
        ]
      },
      { id: _my_id++, time: _my_time++, user_id: 'uuuuu', word_id: rw(),\
        content: 'aefe aefef fa',\
        comments: [
          { type: 'heart', content: '블블블',\ 
            user_id: 'asdf', time: 0, like: true},
          { type: 'comment', content: '블블블asdf',\ 
            user_id: 'qwer', time: 0, like: false}
        ]
      }
    ]

app.get '/api/my_feelings/:id', (req,res) ->
  id = req.params.id
  user = req.session.user
  mon = req.params.skip || 0
  n = req.params.n || 3
  res.json \
    { id: _my_id++, time: 0, user_id: 'uuuuu', word_id: rw(),\
      content: 'aefe aefef fa',\
      comments: [
        { type: 'heart', content: '블블블',\ 
          user_id: 'asdf', time: 0, like: true},
        { type: 'comment', content: '블블블asdf',\ 
          user_id: 'qwer', time: 0, like: false}
      ]
    }

app.get '/api/received_feelings', (req,res) ->
  user = req.session.user
  mon = req.params.skip || 0
  n = req.params.n || 3
  res.json \
    [ { id: _rcv_id++, time: 0, user_id: 'f23rf', word_id: rw(),\
        content: '블라블라블라',\
        comment: { id: 0, type: 'heart', content: '블블블',\ 
            user_id: 'asdf', time: 0, liked: 1}\
      },
      { id: _rcv_id++, time: 0, user_id: 'f23rf', word_id: rw(),\
        content: '블라블라블라',\
        comment: { id: 0, type: 'heart', content: '블블블',\ 
            user_id: 'asdf', time: 0, liked: 1}\
      },
      { id: _rcv_id++, time: 0, user_id: 'f23rf', word_id: rw(),\
        content: '블라블라블라',\
        comment: { id: 0, type: 'heart', content: '블블블',\ 
            user_id: 'asdf', time: 0, liked: 1}\
      }\
    ]

app.get '/api/received_feelings/:id', (req,res) ->
  id = req.params.id
  user = req.session.user
  mon = req.params.skip || 0
  n = req.params.n || 3
  res.json \
    { id: _rcv_id++, time: 0, user_id: 'f23rf', word_id: rw(),\
      content: '블라블라블라',\
      comment: { id: 0, type: 'heart', content: '블블블',\ 
          user_id: 'asdf', time: 0, liked: 1}
    }

app.get '/api/new_arrived_feelings', (req,res) ->
  id = req.params.id
  user = req.session.user
  mon = req.params.skip || 0
  n = req.params.n || 3
  res.json \
    [ { id: 1, time: 0, user_id: 'f23rf', word_id: rw(),\
        content: '블라블라블라'
      }\
    ]

app.put '/api/new_arrived_feelings/:id', (req,res) ->
  id = req.params.id
  user = req.session.user
  res.json \
    { id: 1, time: 0, user_id: 'f23rf', word_id: rw(),\
      content: '블라블라블라',\
      comment: { id: 0, type: 'heart', content: '블블블',\ 
          user_id: 'asdf', time: 0, liked: 1}\
    }

app.post '/api/my_feelings', (req,res) ->
  user = req.session.user
  word_id = req.body.word_id
  content = req.body.content
  console.log "word_id: #{word_id}, content: #{content}"
  res.json {}

app.post '/api/received_feelings/:id/comments', (req,res) ->
  id = req.params.id
  user = req.session.user
  type = req.body.type        # like, comment, forward
  content = req.body.content
  console.log "id: #{id}, type: #{type}, content: #{content}"
  res.json {}

app.put '/api/my_feelings/:id/comments/:comment_id', (req,res) ->
  id = req.params.id
  comment_id = req.params.comment_id
  user = req.session.user
  like = req.body.like
  console.log "id: #{id}, comment_id: #{comment_id}, like: #{like}"
  res.json {}



#### UTILS ####
rw = -> "w#{Math.floor(Math.random()*29)}"

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

