express = require 'express'
app = express()


#### CONFIGURATION ####

valid_session = (user_id) ->
  return false unless user_id
  ss = gDB.session user_id
  return false unless ss
  if ss.expired()
    gDB.del_session user_id
    return false
  ss.update()
  true

require_auth = (req, res, next) ->
  unless valid_session(req.session.user_id)
    console.log '401'
    res.send 401
  else
    me = gDB.user req.session.user_id
    next()

app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.cookieSession(secret: 'deadbeef')
  app.use express.logger { format: ':method :url' }
  app.use (err, req, res, next) ->
    console.error err.stack
    res.send 500, 'Something broke!'
  app.use app.router
  app.all '/api/*', require_auth
  app.use express.static("#{__dirname}/public")


#### COMMON ROUTES ####

app.get '/', (req,res) ->
  res.sendfile 'public/index.html' 

app.get '/sessions', (req,res) ->
  unless valid_session req.session.user_id
    res.send 401
  else
    res.json { user_id: req.session.user_id }

app.post '/sessions', (req,res) -> 
  if valid_session req.session.user_id
    res.send 400, "Need to logout"
    return
  user_id = gDB.email req.body.email
  if user_id
    u = gDB.user user_id
    if u && u.password == req.body.password
      req.session.user_id = u.id
      Session.create u.id
      res.json {}
      return
  res.send 404, "Invalid email or password"

app.del '/sessions', (req,res) ->
  unless valid_session req.session.user_id
    res.send 401
  else
    gDB.del_session req.session.user_id
    res.json {}


#### GLOBAL DATA ####

class DB
  _sessions: {}
  _emails: {}
  _users: {}
  _feelings: {}
  feelings_seq: 1
  users_seq: 1
  session: (id) -> @_sessions[id]
  put_session: (id, data) -> @_sessions[id] = data
  del_session: (id) -> delete @_sessions[id]
  email: (email) -> @_emails[email]
  put_email: (user) -> @_emails[user.email] = user.id
  del_email: (email) -> delete @_emails[email]
  users: -> @_users
  user: (id) -> @_users[id]
  put_user: (user) -> @_users[user.id] = user
  del_user: (id) -> delete @_users[id]
  feelings: -> @_feelings
  feeling: (id) -> @_feelings[id]
  put_feeling: (feeling) -> @_feelings[feeling.id] = feeling
  del_feeling: (id) -> delete @_feelings[id]


class Session
  @EXPIRE_TIME: 60 * 1000
  @create: (uid) ->
    s = new Session(uid)
    gDB.put_session uid, s
    s
  constructor: (@user_id) ->
    @update()
  update: ->
    @time = now()
  expired: ->
    now() - @time > Session.EXPIRE_TIME

# before access, should be checked perm & sharable
class Feeling
  @SHARE_DUR: 60 * 60 * 1000
  @create: (me, is_public, word, blah) ->
    f = new Feeling(me, is_public, word, blah)
    gDB.put_feeling f
    me.my_feelings.unshift f.id
    gDispatcher.register_item f.id if is_public
    f
  constructor: (me, is_public, @word, @blah) ->
    @user_id = me.id
    @id = gDB.feelings_seq++
    @status = if is_public then 'public' else 'private'
    @time = now()
    @talks = {}
  sharable_time: ->
    now() - @time < Feeling.SHARE_DUR
  sharable: ->
    @status == 'public' && @sharable_time()
  has_own_perm: (user_id) ->
    @user_id == user_id
  has_group_perm: (user_id) ->
    @has_own_perm(user_id) || @talks[user_id]
  grant_group_perm: (uid) ->
    @talks[uid] = []
  summary: ->    # can be access with no perm
    {id: @id, user_id: @user_id, time: @time, word: @word}
  extend: (user_id) ->
    x = clone @
    u = gDB.user x.user_id
    x.user = u.summary()
    x.share = @sharable()
    unless @has_own_perm(user_id)
      x.own = false
      x.n_talk_users = 1
      x.n_talk_msgs = @talks[user_id].length
    else
      x.own = true
      x.n_talk_users = len x.talks
      x.n_talk_msgs = 0
      for tuid, comments of x.talks
        x.n_talk_msgs += @talks[tuid].length
    x
  extend_full: (user_id) ->
    x = @extend(user_id)
    unless @has_own_perm(user_id)
      x.talks[user_id] = @talks[user_id]
    u = gDB.user user_id
    x.talk_user = {}
    x.talk_user[u.id] = {name: u.name, img: u.img}
    for tuid, comments of x.talks
      tu = gDB.user tuid
      x.talk_user[tuid] = {name: tu.name, img: tu.img}
    x
  weight: (wait_time) -> 0
  set_public: (is_public) ->
    return if @status == 'removed'
    if @status == 'private' && is_public
      @status = 'public'
      gDispatcher.register_item @id if @sharable()
    else if @status == 'public' && not is_public
      @status = 'private'
  remove: ->
    @status = 'removed'
    @blah = ''
    @talks = {}
  

class User
  @create: (name, img, email, password) ->
    u = new User(name, img, email, password)
    gDB.put_user u
    gDB.put_email u
    gDispatcher.register_user u.id
    u
  constructor: (@name, @img, @email, @password) ->
    @id = gDB.users_seq++
    @n_hearts = 0
    @n_availables = 0
    @arrived_feelings = []
    @my_feelings = []
    @rcv_feelings = []
  summary: (extend = false)->
    u = clone @
    delete u.password
    u.arrived_feelings = @arrived_feelings.length
    u.my_feelings = @my_feelings.length
    u.rcv_feelings = @rcv_feelings.length
    if extend
      u.my_shared = @my_shared().length
      u.rcv_shared = @rcv_shared().length
    u
  valid_arrived_feeling: (id) ->
    @arrived_feelings.length > 0 && "#{@arrived_feelings[0]}" == id
  pop_arrived_feeling: ->
    fid = @arrived_feelings.pop()
    @arrived_feelings = []
    gDispatcher.register_user @id
  grab_feeling: (fid) ->
    @rcv_feelings.unshift fid
  my_shared: ->
    r = []
    for fid in @my_feelings
      f = gDB.feeling fid
      continue unless f
      break unless f.sharable_time()
      r.push fid if f.sharable()
    r
  rcv_shared: ->
    r = []
    for fid in @rcv_feelings
      f = gDB.feeling fid
      continue unless f
      break unless f.sharable_time()
      r.push fid if f.sharable()
    r


class WaitItem
  constructor: (@id) -> @wait_time = now()

class Dispatcher
  @MIN_USER_WAIT_TIME: 5000
  @INTERVAL: 5000
  user_que: []
  item_que: []
  constructor: ->
    for uid, u of gDB.users()
      register_user uid if u.arrived_feelings.length == 0
    @user_que.sort (a,b) -> a.wait_time - b.wait_time
  run: ->
    hungry_users = []
    while @user_que.length > 0
      wu = @user_que.shift()
      u = gDB.user wu.id
      continue unless u
      if now() - u.wait_time < Dispatcher.MIN_USER_WAIT_TIME
        hungry_users.push wu
        break
      fid = @select_item(wu)
      unless fid
        hungry_users.push wu
        continue
      u.arrived_feelings.push fid
    while hungry_users.length > 0
      @user_que.unshift hungry_users.pop()
  select_item: (wu) ->
    candidates = []
    n_candi = 0
    reusable = []
    while @item_que.length > 0 && n_candi < 30
      wf = @item_que.shift()
      item = gDB.feeling wf.id
      continue unless item && item.sharable()
      reusable.push wf
      continue if item.has_group_perm(wu)
      for n in [0..item.weight(wu.wait_time)]
        candidates.push item.id
      n_candi++
    while reusable.length > 0
      @item_que.push reusable.shift()
    return if candidates.length == 0 then null else \
      candidates[rand(0,candidates.length-1)]
  register_item: (id) ->
    @item_que.push new WaitItem id
  register_user: (uid) ->
    @user_que.push new WaitItem uid
  log: ->
    console.log "name, hearts, arrived, my, rcv"
    for uid, u of gDB.users()
      console.log "#{u.name}, #{u.n_hearts}, #{u.arrived_feelings.length}, #{u.my_feelings.length}, #{u.rcv_feelings.length}"
    users = []
    for wu in @user_que
      users.push JSON.stringify(gDB.user(wu.id).name)
    console.log "userQ: #{users.join()}"
    items = []
    for wf in @item_que
      items.push wf.id
    console.log "itemQ: #{items.join()}"


app.post '/users', (req,res) ->
  name = req.body.name
  email = req.body.email
  password = req.body.password

  if gDB.email email
    res.send 400, "Duplicated email"
    return
  User.create(name, 'img/profile.jpg', email, password)
  res.json {}

app.get '/api/me', (req,res) ->
  me = gDB.user req.session.user_id
  res.json me.summary(true)

app.get '/api/feelings', (req,res) ->
  me = gDB.user req.session.user_id
  skip = req.params.skip || 0
  n = req.params.n || 30
  type = req.params.type

  r = []
  if type == 'my'
    for fid in me.my_feelings.slice(max(0,skip),min(my_feelings.length,skip+n))
      f = gDB.feeling fid
      r.push f.extend(me.id) if f
  else if type == 'rcv'
    for fid in me.rcv_feelings.slice(max(0,skip),min(rcv_feelings.length,skip+n))
      f = gDB.feeling fid
      r.push f.extend(me.id) if f
  else
    a = me.my_shared()
    b = me.rcv_shared()
    for fid in me.my_shared()
      f = gDB.feeling fid
      r.push f.extend me.id
    for fid in me.rcv_shared()
      f = gDB.feeling fid
      r.push f.extend me.id
  res.json r

app.post '/api/feelings', (req,res) ->
  me = gDB.user req.session.user_id
  word = req.body.word
  blah = req.body.blah
  is_public = req.body.is_public || true
  unless word && blah && is_public
    res.send 400, "Invalid Parameters"
    return

  Feeling.create(me, is_public, word, blah)
  res.json {}

app.get '/api/feelings/:id', (req,res) ->
  me = gDB.user req.session.user_id
  id = req.params.id

  f = gDB.feeling id
  if not f
    res.send 404, "No such feeling: #{id}"
  else if not f.has_group_perm me.id
    res.json f.summary()
  else
    res.json f.extend_full me.id

app.put '/api/feelings/:id', (req,res) ->
  me = gDB.user req.session.user_id
  id = req.params.id
  is_public = req.body.is_public
  f = gDB.feeling id
  unless f && f.has_own_perm me.id
    res.send 406, "No permission to access this feeling: #{id}"
  else
    f.set_public(is_public)
    res.json {}

app.put '/api/feelings/:id/like', (req,res) ->
  me = gDB.user req.session.user_id
  id = req.params.id
  user_id = req.body.user_id
  f = gDB.feeling id
  unless f && f.has_own_perm me.id
    res.send 406, "No permission to access this feeling: #{id}"
  else
    if f.like
      res.send 406, "Already Done"
    else
      f.like = user_id
      gDB.user(user_id).n_hearts++
      res.json {}

app.del '/api/feelings/:id', (req,res) ->
  me = gDB.user req.session.user_id
  id = req.params.id
  f = gDB.feeling id
  unless f && f.has_own_perm me.id
    res.send 406, "No permission to access this feeling: #{id}"
  else
    f.remove()
    res.json {}

app.post '/api/feelings/:id/talks/:user_id/comments', (req,res) ->
  me = gDB.user req.session.user_id
  id = req.params.id
  user_id = req.params.user_id
  blah = req.body.blah
  f = gDB.feeling id
  unless f && f.has_group_perm me.id
    res.send 406, "No permission to access this feeling: #{id}"
    return
  unless f.sharable()
    res.send 406, "This feeling is no longer sharable."
    return
  if f.has_own_perm(me.id)
    f.talks[user_id].push 
      user_id: user_id
      blah: blah
      time: now()
  else
    f.talks[me.id].push 
      user_id: me.id
      blah: blah
      time: now()    
  res.json {}

app.get '/api/arrived_feelings', (req,res) ->
  me = gDB.user req.session.user_id
  r = []
  for fid in me.arrived_feelings
    f = gDB.feeling fid
    if f && f.sharable()
      r.push f.summary()
  res.json r

app.put '/api/arrived_feelings/:id', (req,res) ->
  me = gDB.user req.session.user_id
  id = req.params.id

  unless me.valid_arrived_feeling(id)
    res.send 404, "No such feeling: #{id}"
    return
  
  me.pop_arrived_feeling()

  f = gDB.feeling id
  unless f && f.sharable()
    throw "This feeling is no longer sharable."
  f.grant_group_perm me.id

  me.grab_feeling(id)
  res.json f.extend_full me.id


# UTILS
clone = (obj) ->
  return JSON.parse(JSON.stringify(obj))
max = (a,b) ->
  if a>=b then a else b
min = (a,b) ->
  if a<b then a else b
remove_item = (arr, i) ->
  arr.splice(i, 1) if i > -1
now = -> new Date().getTime()
rand = (s,e) ->
  Math.round(Math.random()*e)+s
concat = (a,b) ->
  a.push x for x in b
len = (obj) ->
  Object.keys(obj).length
merge_feelings = (a,b) ->
  r = []
  i = j = 0
  loop
    if a.length == i
      concat r, b.slice(j,b.length)
      return r
    if b.length == j
      concat r, a.slice(i,a.length)
      return r
    af = gDB.feeling a[i]
    bf = gDB.feeling b[j]
    if af.time > bf.time
      r.push af
      i++
    else
      r.push bf
      j++
  r

gDB = new DB()
gDispatcher = new Dispatcher()

schedule = ->
  gDispatcher.run()
  gDispatcher.log()
  setTimeout schedule, Dispatcher.INTERVAL

schedule()

u0 = User.create('sun', 'img/profile.jpg', 'sun@gmail.com', 'sun00')
u1 = User.create('moon', 'img/profile.jpg', 'moon@gmail.com', 'moon00')
u2 = User.create('asdf', 'img/profile.jpg', 'asdf', 'asdf')

auto_feeling= ->
  console.log '## auto fill started'
  word = rand(0,29)
  a = []
  for n in [0..rand(0,9)]
    a.push 'blah'
  Feeling.create(u0, true, word, a.join(''))
  setTimeout auto_feeling, 10000
  console.log '## auto fill done'
auto_feeling()

app.listen '3333'
console.log 'listening on 3333'

