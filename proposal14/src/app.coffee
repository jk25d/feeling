express = require 'express'
app = express()


#### CONFIGURATION ####

valid_session = (user_id) ->
  return false unless user_id
  ss = g_sessions[user_id]
  return false unless ss
  if ss.expired()
    delete g_sessions[user_id]
    return false
  ss.update()
  true

require_auth = (req, res, next) ->
  unless valid_session(req.session.user_id)
    console.log '401'
    res.send 401
  else
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
  unless valid_session req.session.user_id
    res.send 401
  else
    res.json { user_id: req.session.user_id }

app.post '/sessions', (req,res) -> 
  if valid_session req.session.user_id
    res.send 400, "Need to logout"
    return
  user_id = g_emails[req.body.email]
  if user_id
    u = g_users[user_id]  
    if u && u.password == req.body.password
      req.session.user_id = u.id
      g_sessions[u.id] = new Session(u.id)
      res.json {}
      return
  res.send 404, "Invalid email or password"

app.del '/sessions', (req,res) ->
  unless valid_session req.session.user_id
    res.send 401
  else
    delete g_sessions[req.session.user_id]
    res.json {}


#### GLOBAL DATA ####

g_sessions = {}
g_emails = {}
g_users = {}
g_feelings = {}
g_feelings_seq = 1
g_users_seq = 1

class Session
  @EXPIRE_TIME: 60 * 1000
  constructor: (@user_id) ->
    @update()
  update: ->
    @time = now()
  expired: ->
    now() - @time > Session.EXPIRE_TIME

# before access, should be checked perm & sharable
class Feeling
  @SHARE_DUR: 60 * 60 * 1000
  constructor: (me, is_public, @word, @blah) ->
    @user_id = me.id
    @id = g_feelings_seq++
    @status = if is_public then 'public' else 'private'
    @time = now()
    @talks = {}

    me.my_feelings.unshift @id
    g_dispatcher.register_item @ if is_public
  sharable_time: ->
    now() - @time < Feeling.SHARE_DUR
  sharable: ->
    @status == 'public' && @sharable_time()
  has_own_perm: (user_id) ->
    @user_id == user_id
  has_group_perm: (user_id) ->
    @has_own_perm(user_id) || @talks[user_id]
  add_to_group: (user) ->
    @talks[user.id] = []
    user.rcv_feelings.unshift @id
  summary: ->    # can be access with no perm
    {id: @id, user_id: @user_id, time: @time, word: @word}
  extend: (user_id) ->
    x = clone @
    u = g_users[x.user_id]
    x.user = u.summary()
    x.share = @sharable()
    unless @has_own_perm(user_id)
      x.own = false
      x.n_talk_users = 1
      x.n_talk_msgs = @talks[user_id].length
    else
      x.own = true
      x.n_talk_users = Object.keys(x.talks).length
      x.n_talk_msgs = 0
      for tuid, comments of x.talks
        x.n_talk_msgs += @talks[tuid].length
    x
  extend_full: (user_id) ->
    x = @extend(user_id)
    unless @has_own_perm(user_id)
      x.talks[user_id] = @talks[user_id]
    u = g_users[user_id]
    x.talk_user = {}
    x.talk_user[u.id] = {name: u.name, img: u.img}
    for tuid, comments of x.talks
      tu = g_users[tuid]
      x.talk_user[tuid] = {name: tu.name, img: tu.img}
    x
  weight: (user_id) -> 0
  set_public: (is_public) ->
    return if @status == 'removed'
    if @status == 'private' && is_public
      @status = 'public'
      g_dispatcher.register_item @ if @sharable()
    else if @status == 'public' && not is_public
      @status = 'private'
  remove: ->
    @status = 'removed'
    @blah = ''
    @talks = {}

class Dispatcher
  @WAIT_TIME: 5000
  @INTERVAL: 5000
  user_que: []
  item_que: []
  constructor: ->
    for u in g_users
      register u if u.arrived_feelings.length == 0
    @user_que.sort (a,b) -> a.wait_time - b.wait_time
  schedule: ->
    hungry_users = []
    while g_dispatcher.user_que.length > 0
      uid = g_dispatcher.user_que.shift()
      u = g_users[uid]
      continue unless u
      if now() - u.wait_time < Dispatcher.WAIT_TIME
        hungry_users.push uid
        break
      item = g_dispatcher.select_item(uid)
      unless item
        hungry_users.push uid
        continue
      u.arrived_feelings.push item.id
    while hungry_users.length > 0
      g_dispatcher.user_que.unshift hungry_users.pop()
    setTimeout g_dispatcher.schedule, Dispatcher.INTERVAL
    g_dispatcher.log()
  select_item: (uid) ->
    candidates = []
    n_candi = 0
    reusable = []
    while @item_que.length > 0 && n_candi < 30
      fid = @item_que.shift()
      item = g_feelings[fid]
      continue unless item && item.sharable()
      reusable.push fid
      continue if item.has_group_perm(uid)
      for n in [0..item.weight(uid)]
        candidates.push item
      n_candi++
    while reusable.length > 0
      @item_que.push reusable.shift()
    return if candidates.length == 0 then null else \
      candidates[rand(0,candidates.length-1)]
  register_item: (item) ->
    @item_que.push item.id
  register: (user) ->
    @user_que.push user.id
    user.wait_time = now()
  log: ->
    console.log "name, hearts, arrived, my, rcv"
    for uid, u of g_users
      console.log "#{u.name}, #{u.n_hearts}, #{u.arrived_feelings.length}, #{u.my_feelings.length}, #{u.rcv_feelings.length}"
    users = []
    for uid in g_dispatcher.user_que
      users.push JSON.stringify(g_users[uid].name)
    console.log "userQ: #{users.join()}"
    items = []
    for fid in g_dispatcher.item_que
      items.push fid
    console.log "itemQ: #{items.join()}"


class User
  constructor: (@name, @img, @email, @password) ->
    @id = g_users_seq++
    @n_hearts = 0
    @n_availables = 0
    @arrived_feelings = []
    @my_feelings = []
    @rcv_feelings = []
    g_dispatcher.register @
    g_emails[@email] = @id
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
  arrived_to_rcv: (id) ->
    fid = @arrived_feelings.pop()
    @arrived_feelings = []
    g_dispatcher.register @
  my_shared: ->
    r = []
    for fid in @my_feelings
      f = g_feelings[fid]
      continue unless f
      break unless f.sharable_time()
      r.push fid if f.sharable()
    r
  rcv_shared: ->
    r = []
    for fid in @rcv_feelings
      f = g_feelings[fid]
      continue unless f
      break unless f.sharable_time()
      r.push fid if f.sharable()
    r

app.post '/users', (req,res) ->
  name = req.body.name
  email = req.body.email
  password = req.body.password

  if g_emails[email]
    res.send 400, "Duplicated email"
    return
  u = new User(name, 'img/profile.jpg', email, password)
  g_users[u.id] = u
  res.json {}

app.get '/api/me', (req,res) ->
  me = g_users[req.session.user_id]
  res.json me.summary(true)

app.get '/api/feelings', (req,res) ->
  me = g_users[req.session.user_id]
  skip = req.params.skip || 0
  n = req.params.n || 30
  type = req.params.type

  r = []
  if type == 'my'
    for fid in me.my_feelings.slice(max(0,skip),min(my_feelings.length,skip+n))
      f = g_feelings[fid]
      r.push f.extend(me.id) if f
  else if type == 'rcv'
    for fid in me.rcv_feelings.slice(max(0,skip),min(rcv_feelings.length,skip+n))
      f = g_feelings[fid]
      r.push f.extend(me.id) if f
  else
    a = me.my_shared()
    b = me.rcv_shared()
    for fid in me.my_shared()
      f = g_feelings[fid]
      r.push f.extend me.id
    for fid in me.rcv_shared()
      f = g_feelings[fid]
      r.push f.extend me.id
  res.json r

app.post '/api/feelings', (req,res) ->
  me = g_users[req.session.user_id]
  word = req.body.word
  blah = req.body.blah
  is_public = req.body.is_public || true
  unless word && blah && is_public
    res.send 400, "Invalid Parameters"
    return

  f = new Feeling(me, is_public, word, blah)
  g_feelings[f.id] = f
  res.json {}

app.get '/api/feelings/:id', (req,res) ->
  me = g_users[req.session.user_id]
  id = req.params.id

  f = g_feelings[id]
  if not f
    res.send 404, "No such feeling: #{id}"
  else if not f.has_group_perm me.id
    res.json f.summary()
  else
    res.json f.extend_full me.id

app.put '/api/feelings/:id', (req,res) ->
  me = g_users[req.session.user_id]
  id = req.params.id
  is_public = req.body.is_public
  f = g_feelings[id]
  unless f && f.has_own_perm me.id
    res.send 406, "No permission to access this feeling: #{id}"
  else
    f.set_public(is_public)
    res.json {}

app.put '/api/feelings/:id/like', (req,res) ->
  me = g_users[req.session.user_id]
  id = req.params.id
  user_id = req.body.user_id
  f = g_feelings[id]
  unless f && f.has_own_perm me.id
    res.send 406, "No permission to access this feeling: #{id}"
  else
    if f.like
      res.send 406, "Already Done"
    else
      f.like = user_id
      g_users[user_id].n_hearts++
      res.json {}

app.del '/api/feelings/:id', (req,res) ->
  me = g_users[req.session.user_id]
  id = req.params.id
  f = g_feelings[id]
  unless f && f.has_own_perm me.id
    res.send 406, "No permission to access this feeling: #{id}"
  else
    f.remove()
    res.json {}

app.post '/api/feelings/:id/talks/:user_id/comments', (req,res) ->
  me = g_users[req.session.user_id]
  id = req.params.id
  user_id = req.params.user_id
  blah = req.body.blah
  f = g_feelings[id]
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
  me = g_users[req.session.user_id]
  r = []
  for fid in me.arrived_feelings
    f = g_feelings[fid]
    if f && f.sharable()
      r.push f.summary()
  res.json r

app.put '/api/arrived_feelings/:id', (req,res) ->
  me = g_users[req.session.user_id]
  id = req.params.id

  unless me.arrived_to_rcv(id)
    req.send 404, "No such feeling: #{id}"
    return

  f = g_feelings[id]
  unless f.sharable()
    res.send 406, "This feeling is no longer sharable."
    return
  f.add_to_group(me)
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
    af = g_feelings[a[i]]
    bf = g_feelings[b[j]]
    if af.time > bf.time
      r.push af
      i++
    else
      r.push bf
      j++
  r

g_dispatcher = new Dispatcher()
g_dispatcher.schedule()

u0 = new User('sun', 'img/profile.jpg', 'sun@gmail.com', 'sun00')
u1 = new User('moon', 'img/profile.jpg', 'moon@gmail.com', 'moon00')
u2 = new User('asdf', 'img/profile.jpg', 'asdf', 'asdf')
g_users[u0.id] = u0
g_users[u1.id] = u1
g_users[u2.id] = u2

auto_feeling= ->
  console.log '## auto fill started'
  word = rand(0,29)
  a = []
  for n in [0..rand(0,9)]
    a.push 'blah'
  f = new Feeling(u0, true, word, a.join(''))
  g_feelings[f.id] = f  
  setTimeout auto_feeling, 10000
  console.log '## auto fill done'
auto_feeling()

app.listen '3333'
console.log 'listening on 3333'

