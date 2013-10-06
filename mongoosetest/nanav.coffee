sync = require 'synchronize'
mgs = require 'mongoose'
mgs.connect 'mongodb://localhost/nanav'

userSchema = new mgs.Schema
  _id: {type: String, unique: true}
  email: {type: String, index: true, unique: true, required: true}
  password: String
  name: String
  img: String
  status_msg: String    # like kakao talk status message
  nread_perms: {type: Number, default: 0}
  last_written: {type: Number, default: 0}
  anony_writes: [Number]
  blocks: [String]
Users = mgs.model 'users', new userSchema

buddySchema = new mgs.Schema
  uids: [String]
  score: {type: Number, default: 0}
buddySchema.index {uids: 1, score: 1}
Buddies = mgs.model 'buddies', new buddySchema

Seq = mgs.model 'seq', new mgs.Schema
  _id: {type: String, unique: true}
  seq: {type: Number, default: 0}

feelingSchema = new mgs.Schema
  _id: {type: String, unique: true}    # no uid:fid pair for privacy
  owner: {type: String, index: true}
  status: String
  time: {type: Number, default: 0}
  face: String
  blah: String
  listeners: {type: [String], index: true, unique: true}
  like_users: [String]
  ncomments: {type: Number, default: 0}
  comments: [commentSchema]
# for my feeling by face or feeling logs with buddy
feelingSchema.index {owner: 1, face: 1, listeners: 1}
feelingSchema.index {_id: 1, like_users: 1}  # to find favorites..
Feelings = mgs.model 'feelings', new feelingSchema

commentSchema = new mgs.Schema
  _id: {type: Number, unique: true}  # index number
  owner: String
  time: {type: Number, default: 0}
  blah: String
  nhearts: {type: Number, default: 0}

activeFeelingSchema = new mgs.Schema
  fid: String
  owner: {type: String, index: true}
  nreads: {type: Number, default: 0}
# http://docs.mongodb.org/manual/core/index-compound/#prefixes
Actives = mgs.model 'actives', new activeFeelingSchema

#rcvFeelingSchema = new mgs.Schema
#  fid: String
#  owner: {type: String, index: true}
#rcvFeelingSchema.index {owner: 1, fid: 1}
#Receives = mgs.model 'actives', new rcvFeelingSchema

Seq.collection.drop()
Users.collection.drop()
Feelings.collection.drop()
Actives.collection.drop()
#Receives.collection.drop()

sync Seq, 'create', 'findByIdAndUpdate'
sync Users, 'create', 'find', 'findOne', 'findById', 'findByIdAndUpdate', 'count'
sync Feelings, 'create', 'find', 'findOne', 'findById', 'findByIdAndUpdate', 'count'
sync Actives, 'create', 'find', 'findOne', 'findById', 'findByIdAndUpdate', 'count'
#sync Receives, 'create', 'find', 'findOne', 'findById', 'findByIdAndUpdate', 'count'


next_seq = (prefix) ->
  Seq.findByIdAndUpdate(prefix, {$inc: {seq: 1}}).seq
user_seq = -> "u#{next_seq 'u'}"
feeling_seq = -> "f#{next_seq 'f'}"

rand = (s,e) -> Math.round(Math.random()*e)+s

activeFeelingSchema.statics.has_new_comments = (uid) ->
  # $regex can only use an index efficiently 
  # when the regular expression has an anchor for the beginning (i.e. ^) of a string 
  # and is a case-sensitive match
  afs = @find {owner: uid}, "fid nreads"
  conds = afs.map (af) -> {fid: af.fid, ncomments: {$gt: af.nreads}}
  Feelings.count {$or: conds} > 0

feelingSchema.statics.actives = (uid, options={}) ->
  afs = Actives.find {owner: uid}, "fid nreads", options

  conds = afs.map (af) -> {fid: af.fid, ncomments: {$gt: af.nreads}}
  fs = @find {fid: afs.map(af) -> fid}, '-comments'

  umap = {}
  uids = fs.map (f) -> f.owner
  us = Users.find {_id: {$in: uids}}, '_id name img'
  for u in us do (u) -> umap[u._id] = u

  afmap = {}
  for af in afs do (af) -> afmap[af.fid] = af

  scores = {}
  candidates = uids.filter (u) -> u != uid
  bs = Buddies.find {uids: uid, uids: {$in: candidates}}
  for b in bs
    continue if b.uids.length != 2
    buddy = if b.uids[0] != uid then b.uids[0] else b.uids[1]
    scores[buddy] = b.score

  for f in fs
    f.new_comments = f.ncomments - afmap[f.fid].nreads
    f.users = {}
    f.users[f.owner] = umap[f.owner]
    f.users[f.owner].score = scores[f.owner] if scores[f.owner]
  fs

feelingSchema.statics.rcvs = (uid, options=[]) ->
  fs = @find {listeners: uid}, '-comments', options

  umap = {}
  uids = fs.map (f) -> f.owner
  us = Users.find {_id: {$in: uids}}, '_id name img'
  for u in us do (u) -> umap[u._id] = u

  scores = {}
  candidates = uids.filter (u) -> u != uid
  bs = Buddies.find {uids: uid, uids: {$in: candidates}}
  for b in bs
    continue if b.uids.length != 2
    buddy = if b.uids[0] != uid then b.uids[0] else b.uids[1]
    scores[buddy] = b.score

  for f in fs
    f.users = {}
    f.users[f.owner] = umap[f.owner]
    f.users[f.owner].score = scores[f.owner] if scores[f.owner]
  fs

feelingSchema.statics.mines = (uid, face, options=[]) ->
  cond = {owner: uid}
  cond.face = face if face
  fs = @find cond, '-comments', options


feelingSchema.methods.with_users = (myid, include_listeners=false) ->
  uids = [@owner]
  if include_listeners
    uids.concat @listeners
  users = @model('users').find {_id: {$in: uids}}, '_id name img'
  ret = {}
  for u in users
    ret.u._id = {name: u.name, img: u.img}
  if myid != @owner
    buddy = @model('buddies').findOne {uids: myid, uids: @owner}
    ret[@owner].buddy_score = buddy.score if buddy
  ret

feelingSchema.statics.connection_logs = (uid0, uid1) ->
  uids = [uid0, uid1]
  @find {owner: {$in: uids}, listeners: {$in: uids}}

buddySchema.statics.favorites = (uid) ->
  @find {uids: uid, score: {$lt: 10} }

buddySchema.statics.buddies = (uid) ->
  @find {uids: uid, score: 10 }





sync.fiber ->
  try
    Seq.create {_id: 'u', seq:0}
    Seq.create {_id: 'f', seq:0}

    Users.create {_id: user_seq(), name: 'asdf', buddies: []}
    Users.create {_id: user_seq(), name: 'qwer', buddies: []}

    # test subdoc push
    buddy = {uid0: 'u1', uid1: 'u2', score: 10}
    Users.findByIdAndUpdate 'u1', {$addToSet: {buddies: buddy}}

    # test subdoc find
    ret = Users.find {_id: 'u1', $or: [{'buddies.uid0': 'u2'}, {'buddies.uid1': 'u2'}] }
    console.log "## Result ##\n#{ret}"

    # test subdoc push all
    buddies = for i in [0..9]
      {uid0: 'u1', uid1: 'u2', score: i*10, conns: []}
    Users.findByIdAndUpdate 'u2', {$pushAll: {buddies: buddies}}    

    # test subdoc pagination
    # use projection. determine which field to return..
    ret = Users.find {_id: 'u2'}, {buddies: {$slice: [2,3]}}

    f = Feelings.create
      _id: "u1:#{feeling_seq()}"
      owner: 'u1'
      listeners: []
      comments: []
    comments = for i in [0..9]
      {_id: "#{f.id}:#{comment_seq(f.id)}", owner: "u#{rand(0,1)}"}
    Feelings.findByIdAndUpdate f.id, {$pushAll: {comments: comments}}

    #! fail to filter subdoc
    #! need to filter on the server
    #! if subdoc can be big and need to filter, use separate collection
    f = Feelings.findById f.id
    f.comments = f.comments.filter (c) -> c.owner != 'u1'
    ret = f

    # sample query to alarm new message

    console.log "## Result ##\n#{ret}"
    console.log "## Users ##\n#{Users.find()}"
    console.log "## Feelings ##\n#{Feelings.find()}"
  catch err
    console.log err.stack

