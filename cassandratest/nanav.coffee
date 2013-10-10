sync = require 'synchronize'
helenus = require 'helenus'

db = new helenus.ConnectionPool
  hosts: ['localhost:9160']
  timeout: 3000
  
db.on 'error', (err) ->
  console.log err.stack
  
r2o = (rows) ->
  res = []
  for row in rows
    o = {}
    res.push o
    row.forEach (name, val, ts, ttl) ->
      o[name] = val
  res
sync db, 'connect', 'cql', 'use'
  
sync.fiber ->
  try
    db.connect()
    db.cql "drop keyspace if exists test"
    db.cql """
      create keyspace test with replication = 
      {'class': 'SimpleStrategy', 'replication_factor': 1}
    """
    db.use "test"
    
    db.cql """
      create table comments (fid text, uid text, time int, 
      primary key ((fid,uid),time));
    """
    db.cql """
      insert into comments (fid,uid,time) values ('0','0',1);
    """
    ret = db.cql """
      select fid,uid,time from comments;
    """
    ret = r2o ret
    ret.forEach (row) ->
      console.log row.fid, row.uid, row.time
  catch err
    console.log err.stack
  db.close()
  