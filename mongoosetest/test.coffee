sync = require 'synchronize'
mgs = require 'mongoose'
mgs.connect 'mongodb://localhost/test'

Users = mgs.model 'users', new mgs.Schema
  _id: {type: String, unique: true}
  name: String
  buddies: [buddySchema]

buddySchema = new mgs.Schema
  uid0: {type: String, index: 'hashed'}
  uid1: {type: String, index: 'hashed'}
  score: {type: Number, default: 0}
  conns: [String]
buddySchema.index {uid0: 1, uid1: 1}, {unique: true}

Seq = mgs.model 'seq', new mgs.Schema
  _id: {type: String, unique: true}
  seq: {type: Number, default: 0}

Feelings = mgs.model 'feelings', new mgs.Schema
  _id: {type: String, unique: true}
  owner: {type: String, index: 'hashed'}
  listeners: [String]
  comments: [commentSchema]
  comment_seq: {type: Number, default: 0}

commentSchema = new mgs.Schema
  _id: {type: String, unique: true}
  owner: {type: String, index: 'hashed'}
  n_hearts: {type: Number, default: 0}

Seq.collection.drop()
Users.collection.drop()
Feelings.collection.drop()

sync Seq, 'create', 'findByIdAndUpdate'
sync Users, 'create', 'find', 'findById', 'findByIdAndUpdate', 'mapReduce'
sync Feelings, 'create', 'find', 'findById', 'findByIdAndUpdate', 'mapReduce'

next_seq = (prefix) ->
  Seq.findByIdAndUpdate(prefix, {$inc: {seq: 1}}).seq
user_seq = -> "u#{next_seq 'u'}"
feeling_seq = -> "f#{next_seq 'f'}"
comment_seq = (fid) ->
  f = Feelings.findByIdAndUpdate(fid, {$inc: {comment_seq: 1}})
  "c#{f.comment_seq}"

rand = (s,e) -> Math.round(Math.random()*e)+s

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
    ops = 
      map: ->
        ret = @
        ret.users ={}
        ret.users[@owner] = mgs.users.find {_id: @owner}, {name: 1}
        @listners.forEach (uid) -> 
          ret.users[uid] = mgs.users.find {_id: uid}, {name: 1}
        emit @_id, ret
      reduce: (k, vs) -> vs
      query: {_id: f.id}
      out: {inline:1}
    Feelings.mapReduce ops

    console.log "## Result ##\n#{ret}"
    console.log "## Users ##\n#{Users.find()}"
    console.log "## Feelings ##\n#{Feelings.find()}"
  catch err
    console.log err.stack

