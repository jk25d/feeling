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
  feelings_seq: 1
  users_seq: 1
  constructor: ->
    @_sessions = {}
    @_emails = {}
    @_users = {}
    @_feelings = {}
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
  put_feeling: (feeling) -> 
    @_feelings[feeling.id] = feeling;
    gFeelingContainer.push feeling.id;
  del_feeling: (id) -> delete @_feelings[id]


class Session
  @EXPIRE_TIME: 30 * 60 * 1000
  @create: (uid) ->
    s = new Session(uid)
    gDB.put_session uid, s
    s
  constructor: (@user_id) -> @update()
  update: -> @time = now()
  expired: -> now() - @time > Session.EXPIRE_TIME

# before access, should be checked perm & sharable
class Feeling
  @SHARE_DUR: 10 * 60 * 1000
  @DETACHABLE_DUR: @SHARE_DUR /2
  @create: (me, is_public, word, blah) ->
    f = new Feeling(me, is_public, word, blah)
    gDB.put_feeling f
    me.feelings.push_mine f.id
    gDispatcher.register_item f.id if is_public
    f
  constructor: (me, is_public, @word, @blah) ->
    @user_id = me.id
    @id = 'f' + gDB.feelings_seq++
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
  anony_content: ->
    u = gDB.user @user_id
    {time: @time, img: u.img, word: @word, blah: @blah}
  extend: (user_id) ->
    x = clone @
    u = gDB.user x.user_id
    x.users = {}
    x.users[u.id] = {name: u.name, img: u.img}
    x.share = @sharable()
    unless @has_own_perm(user_id)
      x.own = false
      x.n_talk_users = 1
      console.log JSON.stringify @
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
    for tuid, comments of x.talks
      tu = gDB.user tuid
      x.users[tuid] = {name: tu.name, img: tu.img}
    x
  weight: (remain_time) -> remain_time / Feeling.SHARE_DUR * 10
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

class UserFeelings
  constructor: (@_uid) ->
    @_actives = [] # new one first
    @_mines = []   # new one first
    @_rcvs = []    # new one first
  push_mine: (id) ->
    @_actives.unshift id
    @_mines.unshift id
  push_rcv: (id) ->
    @_actives.unshift id
    @_rcvs.unshift id
  mines_len: -> @_mines.length
  rcvs_len: -> @_rcvs.length
  total_len: -> @_mines.length + @_rcvs.length
  my_actives: ->
    @actives().filter (f) -> f.has_own_perm(@_uid)
  rcv_actives: ->
    @actives().filter (f) -> not f.has_own_perm(@_uid)
  actives: ->
    @_filter_actives().map((fid) -> gDB.feeling fid).filter((f) -> f)
  _filter_actives: ->
    return @_actives if @_actives.length == 0
    _now = now()
    reusable = []
    while @_actives.length > 0
      fid = @_actives.pop()
      f = gDB.feeling fid
      # if this remains enough time, no need to filter next feelings
      if f && _now - f.time < Feeling.SHARE_DUR + Feeling.DETACHABLE_DUR
        @_actives.push fid
        break
      reusable.push fid if (_now - f.time) < Feeling.SHARE_DUR
    while reusable.length > 0
      @_actives.push reusable.pop()
    @_actives
  mines: (s,e) -> 
    return [] if s == e || e == 0
    @_mines[s..e-1].map((id) -> gDB.feeling id).filter((x)->x)
  rcvs: (s,e) -> 
    return [] if s == e || e == 0
    @_rcvs[s..e-1].map((id) -> gDB.feeling id).filter((x)->x)
  find_mine_idx: (id) ->
    for i in [0..@_mines.length-1]
      return i if @_mines[i] == id
    0
  find_rcv_idx: (id) ->
    for i in [0..@_rcvs.length-1]
      return i if @_rcvs[i] == id
    0
  

class User
  @create: (name, img, email, password) ->
    u = new User(name, img, email, password)
    gDB.put_user u
    gDB.put_email u
    gDispatcher.register_user u.id
    u
  constructor: (@name, @img, @email, @password) ->
    @id = 'u' + gDB.users_seq++
    @n_hearts = 0
    @n_availables = 0
    @arrived_feelings = []
    @feelings = new UserFeelings(@id)
  summary: (extend = false)->
    u = clone @
    delete u.password
    u.arrived_feelings = @arrived_feelings.length
    u.my_feelings = @feelings.mines_len()
    u.rcv_feelings = @feelings.rcvs_len()
    if extend
      u.my_shared = @feelings.my_actives().length
      u.rcv_shared = @feelings.rcv_actives().length
    u
  valid_arrived_feeling: (id) ->
    @arrived_feelings.length > 0 && @arrived_feelings[0] == id
  pop_arrived_feeling: ->
    fid = @arrived_feelings.pop()
    @arrived_feelings = []
    gDispatcher.register_user @id
  grab_feeling: (fid) ->
    @feelings.push_rcv fid


class WaitItem
  constructor: (@id) -> @wait_time = now()

class Dispatcher
  @MIN_USER_WAIT_TIME: 5000
  @INTERVAL: 5000
  constructor: ->
    @_user_que = []     # old one first
    @_item_que = []     # old one first
    for uid, u of gDB.users()
      register_user uid if u.arrived_feelings.length == 0
    @_user_que.sort (a,b) -> a.wait_time - b.wait_time
  run: ->
    hungry_users = []
    _now = now()
    while @_user_que.length > 0
      wu = @_user_que.shift()
      u = gDB.user wu.id
      continue unless u
      if _now - u.wait_time < Dispatcher.MIN_USER_WAIT_TIME
        hungry_users.push wu
        break
      fid = @select_item(wu)
      unless fid
        hungry_users.push wu
        continue
      u.arrived_feelings.push fid
    while hungry_users.length > 0
      @_user_que.unshift hungry_users.pop()
  select_item: (wu) ->
    candidates = []
    n_candi = 0
    reusable = []
    _now = now()
    while @_item_que.length > 0 && n_candi < 30
      wf = @_item_que.shift()
      item = gDB.feeling wf.id
      continue unless item && item.sharable()
      reusable.push wf
      continue if item.has_group_perm(wu.id)
      [0..item.weight(_now - wu.wait_time)].forEach -> candidates.push wf
      n_candi++
    selected = if candidates.length == 0 then null \
      else candidates[rand(0,candidates.length-1)]
    while reusable.length > 0
      f = reusable.pop()
      continue if selected && selected.id == f.id
      @_item_que.unshift f
    @_item_que.push selected if selected
    selected?.id
  register_item: (id) ->
    @_item_que.push new WaitItem id
  register_user: (uid) ->
    @_user_que.push new WaitItem uid
  latest_feelings: (n) ->
    r = []
    for wf in @_item_que by -1
      break if r.length >= n
      r.push wf.id if wf
    r
  log: ->
    console.log "name, hearts, arrived, my, rcv"
    for uid, u of gDB.users()
      console.log "#{u.name}, #{u.n_hearts}, #{u.arrived_feelings.length}, #{u.feelings.mines_len()}, #{u.feelings.rcvs_len()}"
    console.log "userQ: #{@_user_que.map (wu) -> JSON.stringify(gDB.user(wu.id).name)}"
    console.log "itemQ: #{@_item_que.map((wf) -> wf.id).join()}"

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
  skip = req.query.skip && parseInt(req.query.skip) || 0
  n = req.query.n && parseInt(req.query.n) || 30
  type = req.query.type
  from = req.query.from || 0

  res.json if type == 'my'
    from_idx = if from == 0 then 0 else me.feelings.find_mine_idx(from) 
    me.feelings.mines(max(0,from_idx+skip), min(me.feelings.mines_len(),from_idx+skip+n)).map (f) -> f.extend(me.id)
  else if type == 'rcv'
    from_idx = if from == 0 then 0 else me.feelings.find_rcv_idx(from) 
    me.feelings.rcvs(max(0,from_idx+skip), min(me.feelings.rcvs_len(),from_idx+skip+n)).map (f) -> f.extend(me.id)
  else
    me.feelings.actives().map (f) -> f.extend(me.id)

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
  console.log "comment: #{blah}"
  f = gDB.feeling id
  unless f && f.has_group_perm me.id
    res.send 406, "No permission to access this feeling: #{id}"
    return
  unless f.sharable()
    res.send 406, "This feeling is no longer sharable."
    return
  comment = { user_id: me.id, blah: blah, time: now() }
  if f.has_own_perm(me.id)
    f.talks[user_id].push comment
  else
    f.talks[me.id].push comment
  res.json {}

app.get '/api/arrived_feelings', (req,res) ->
  me = gDB.user req.session.user_id
  r = []
  for fid in me.arrived_feelings
    f = gDB.feeling fid
    if f && f.sharable()
      r.push f.summary()         # keep arrived and send its summary
    else
      me.pop_arrived_feeling()   # throw away
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
  else
    f.grant_group_perm me.id
    me.grab_feeling(id)
  res.json f.extend_full me.id

app.get '/api/live_feelings', (req,res) ->
  me = gDB.user req.session.user_id
  n = req.query.n || 20
  res.json gDispatcher.latest_feelings(n).map (fid) ->
    gDB.feeling(fid)?.anony_content()


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
gFeelingContainer = []
gDispatcher = new Dispatcher()

schedule = ->
  gDispatcher.run()
  gDispatcher.log()
  # to prevent memory overflow, remove old ones.
  while gFeelingContainer.length >= 100
    fid = gFeelingContainer.shift()
    gDB.del_feeling fid
  setTimeout schedule, Dispatcher.INTERVAL

schedule()

u0 = User.create('sun', 'img/profile.jpg', 'sun@gmail.com', 'sun00')
u1 = User.create('moon', 'img/profile2.jpg', 'moon@gmail.com', 'moon00')
u2 = User.create('asdf', 'img/profile4.jpg', 'asdf', 'asdf')

auto_feeling= (user) ->
  word = rand(0,29)
  a = []
  [0..rand(0,9)].forEach -> a.push 'blah '
  Feeling.create(user, true, word, a.join(''))
  setTimeout auto_feeling, 15000, user
auto_feeling u0
auto_feeling u1

app.listen '3333'
console.log 'listening on 3333'

