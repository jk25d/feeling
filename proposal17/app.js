// Generated by CoffeeScript 1.6.3
(function() {
  var DB, Dispatcher, Feeling, Session, User, UserFeelings, WaitItem, app, auto_feeling, clone, concat, express, gDB, gDispatcher, gFeelingContainer, len, max, merge_feelings, min, now, rand, remove_item, require_auth, schedule, u0, u1, u2, valid_session;

  express = require('express');

  app = express();

  valid_session = function(user_id) {
    var ss;
    if (!user_id) {
      return false;
    }
    ss = gDB.session(user_id);
    if (!ss) {
      return false;
    }
    if (ss.expired()) {
      gDB.del_session(user_id);
      return false;
    }
    ss.update();
    return true;
  };

  require_auth = function(req, res, next) {
    var me;
    if (!valid_session(req.session.user_id)) {
      console.log('401');
      return res.send(401);
    } else {
      me = gDB.user(req.session.user_id);
      return next();
    }
  };

  app.configure(function() {
    app.use(express.bodyParser());
    app.use(express.cookieParser());
    app.use(express.cookieSession({
      secret: 'deadbeef'
    }));
    app.use(express.logger({
      format: ':method :url'
    }));
    app.use(function(err, req, res, next) {
      console.error(err.stack);
      return res.send(500, 'Something broke!');
    });
    app.use(app.router);
    app.all('/api/*', require_auth);
    return app.use(express["static"]("" + __dirname + "/public"));
  });

  app.get('/', function(req, res) {
    return res.sendfile('public/index.html');
  });

  app.get('/sessions', function(req, res) {
    if (!valid_session(req.session.user_id)) {
      return res.send(401);
    } else {
      return res.json({
        user_id: req.session.user_id
      });
    }
  });

  app.post('/sessions', function(req, res) {
    var u, user_id;
    if (valid_session(req.session.user_id)) {
      res.send(400, "Need to logout");
      return;
    }
    user_id = gDB.email(req.body.email);
    if (user_id) {
      u = gDB.user(user_id);
      if (u && u.password === req.body.password) {
        req.session.user_id = u.id;
        Session.create(u.id);
        res.json({});
        return;
      }
    }
    return res.send(404, "Invalid email or password");
  });

  app.del('/sessions', function(req, res) {
    if (!valid_session(req.session.user_id)) {
      return res.send(401);
    } else {
      gDB.del_session(req.session.user_id);
      return res.json({});
    }
  });

  DB = (function() {
    DB.prototype.feelings_seq = 1;

    DB.prototype.users_seq = 1;

    function DB() {
      this._sessions = {};
      this._emails = {};
      this._users = {};
      this._feelings = {};
    }

    DB.prototype.session = function(id) {
      return this._sessions[id];
    };

    DB.prototype.put_session = function(id, data) {
      return this._sessions[id] = data;
    };

    DB.prototype.del_session = function(id) {
      return delete this._sessions[id];
    };

    DB.prototype.email = function(email) {
      return this._emails[email];
    };

    DB.prototype.put_email = function(user) {
      return this._emails[user.email] = user.id;
    };

    DB.prototype.del_email = function(email) {
      return delete this._emails[email];
    };

    DB.prototype.users = function() {
      return this._users;
    };

    DB.prototype.user = function(id) {
      return this._users[id];
    };

    DB.prototype.put_user = function(user) {
      return this._users[user.id] = user;
    };

    DB.prototype.del_user = function(id) {
      return delete this._users[id];
    };

    DB.prototype.feelings = function() {
      return this._feelings;
    };

    DB.prototype.feeling = function(id) {
      return this._feelings[id];
    };

    DB.prototype.put_feeling = function(feeling) {
      this._feelings[feeling.id] = feeling;
      return gFeelingContainer.push(feeling.id);
    };

    DB.prototype.del_feeling = function(id) {
      return delete this._feelings[id];
    };

    return DB;

  })();

  Session = (function() {
    Session.EXPIRE_TIME = 30 * 60 * 1000;

    Session.create = function(uid) {
      var s;
      s = new Session(uid);
      gDB.put_session(uid, s);
      return s;
    };

    function Session(user_id) {
      this.user_id = user_id;
      this.update();
    }

    Session.prototype.update = function() {
      return this.time = now();
    };

    Session.prototype.expired = function() {
      return now() - this.time > Session.EXPIRE_TIME;
    };

    return Session;

  })();

  Feeling = (function() {
    Feeling.SHARE_DUR = 10 * 60 * 1000;

    Feeling.DETACHABLE_DUR = Feeling.SHARE_DUR / 2;

    Feeling.create = function(me, is_public, word, blah) {
      var f;
      f = new Feeling(me, is_public, word, blah);
      gDB.put_feeling(f);
      me.feelings.push_mine(f.id);
      if (is_public) {
        gDispatcher.register_item(f.id);
      }
      return f;
    };

    function Feeling(me, is_public, word, blah) {
      this.word = word;
      this.blah = blah;
      this.user_id = me.id;
      this.id = 'f' + gDB.feelings_seq++;
      this.status = is_public ? 'public' : 'private';
      this.time = now();
      this.talks = {};
    }

    Feeling.prototype.sharable_time = function() {
      return now() - this.time < Feeling.SHARE_DUR;
    };

    Feeling.prototype.sharable = function() {
      return this.status === 'public' && this.sharable_time();
    };

    Feeling.prototype.has_own_perm = function(user_id) {
      return this.user_id === user_id;
    };

    Feeling.prototype.has_group_perm = function(user_id) {
      return this.has_own_perm(user_id) || this.talks[user_id];
    };

    Feeling.prototype.grant_group_perm = function(uid) {
      return this.talks[uid] = [];
    };

    Feeling.prototype.summary = function() {
      return {
        id: this.id,
        user_id: this.user_id,
        time: this.time,
        word: this.word
      };
    };

    Feeling.prototype.anony_content = function() {
      var u;
      u = gDB.user(this.user_id);
      return {
        time: this.time,
        img: u.img,
        word: this.word,
        blah: this.blah
      };
    };

    Feeling.prototype.extend = function(user_id) {
      var comments, tuid, u, x, _ref;
      x = clone(this);
      u = gDB.user(x.user_id);
      x.users = {};
      x.users[u.id] = {
        name: u.name,
        img: u.img
      };
      x.share = this.sharable();
      if (!this.has_own_perm(user_id)) {
        x.own = false;
        x.n_talk_users = 1;
        console.log(JSON.stringify(this));
        x.n_talk_msgs = this.talks[user_id].length;
      } else {
        x.own = true;
        x.n_talk_users = len(x.talks);
        x.n_talk_msgs = 0;
        _ref = x.talks;
        for (tuid in _ref) {
          comments = _ref[tuid];
          x.n_talk_msgs += this.talks[tuid].length;
        }
      }
      return x;
    };

    Feeling.prototype.extend_full = function(user_id) {
      var comments, tu, tuid, x, _ref;
      x = this.extend(user_id);
      if (!this.has_own_perm(user_id)) {
        x.talks[user_id] = this.talks[user_id];
      }
      _ref = x.talks;
      for (tuid in _ref) {
        comments = _ref[tuid];
        tu = gDB.user(tuid);
        x.users[tuid] = {
          name: tu.name,
          img: tu.img
        };
      }
      return x;
    };

    Feeling.prototype.weight = function(remain_time) {
      return remain_time / Feeling.SHARE_DUR * 10;
    };

    Feeling.prototype.set_public = function(is_public) {
      if (this.status === 'removed') {
        return;
      }
      if (this.status === 'private' && is_public) {
        this.status = 'public';
        if (this.sharable()) {
          return gDispatcher.register_item(this.id);
        }
      } else if (this.status === 'public' && !is_public) {
        return this.status = 'private';
      }
    };

    Feeling.prototype.remove = function() {
      this.status = 'removed';
      this.blah = '';
      return this.talks = {};
    };

    return Feeling;

  })();

  UserFeelings = (function() {
    function UserFeelings(_uid) {
      this._uid = _uid;
      this._actives = [];
      this._mines = [];
      this._rcvs = [];
    }

    UserFeelings.prototype.push_mine = function(id) {
      this._actives.unshift(id);
      return this._mines.unshift(id);
    };

    UserFeelings.prototype.push_rcv = function(id) {
      this._actives.unshift(id);
      return this._rcvs.unshift(id);
    };

    UserFeelings.prototype.mines_len = function() {
      return this._mines.length;
    };

    UserFeelings.prototype.rcvs_len = function() {
      return this._rcvs.length;
    };

    UserFeelings.prototype.total_len = function() {
      return this._mines.length + this._rcvs.length;
    };

    UserFeelings.prototype.my_actives = function() {
      return this.actives().filter(function(f) {
        return f.has_own_perm(this._uid);
      });
    };

    UserFeelings.prototype.rcv_actives = function() {
      return this.actives().filter(function(f) {
        return !f.has_own_perm(this._uid);
      });
    };

    UserFeelings.prototype.actives = function() {
      return this._filter_actives().map(function(fid) {
        return gDB.feeling(fid);
      }).filter(function(f) {
        return f;
      });
    };

    UserFeelings.prototype._filter_actives = function() {
      var f, fid, reusable, _now;
      if (this._actives.length === 0) {
        return this._actives;
      }
      _now = now();
      reusable = [];
      while (this._actives.length > 0) {
        fid = this._actives.pop();
        f = gDB.feeling(fid);
        if (f && _now - f.time < Feeling.SHARE_DUR + Feeling.DETACHABLE_DUR) {
          this._actives.push(fid);
          break;
        }
        if ((_now - f.time) < Feeling.SHARE_DUR) {
          reusable.push(fid);
        }
      }
      while (reusable.length > 0) {
        this._actives.push(reusable.pop());
      }
      return this._actives;
    };

    UserFeelings.prototype.mines = function(s, e) {
      if (s === e || e === 0) {
        return [];
      }
      return this._mines.slice(s, +(e - 1) + 1 || 9e9).map(function(id) {
        return gDB.feeling(id);
      }).filter(function(x) {
        return x;
      });
    };

    UserFeelings.prototype.rcvs = function(s, e) {
      if (s === e || e === 0) {
        return [];
      }
      return this._rcvs.slice(s, +(e - 1) + 1 || 9e9).map(function(id) {
        return gDB.feeling(id);
      }).filter(function(x) {
        return x;
      });
    };

    UserFeelings.prototype.find_mine_idx = function(id) {
      var i, _i, _ref;
      for (i = _i = 0, _ref = this._mines.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (this._mines[i] === id) {
          return i;
        }
      }
      return 0;
    };

    UserFeelings.prototype.find_rcv_idx = function(id) {
      var i, _i, _ref;
      for (i = _i = 0, _ref = this._rcvs.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (this._rcvs[i] === id) {
          return i;
        }
      }
      return 0;
    };

    return UserFeelings;

  })();

  User = (function() {
    User.create = function(name, img, email, password) {
      var u;
      u = new User(name, img, email, password);
      gDB.put_user(u);
      gDB.put_email(u);
      gDispatcher.register_user(u.id);
      return u;
    };

    function User(name, img, email, password) {
      this.name = name;
      this.img = img;
      this.email = email;
      this.password = password;
      this.id = 'u' + gDB.users_seq++;
      this.n_hearts = 0;
      this.n_availables = 0;
      this.arrived_feelings = [];
      this.feelings = new UserFeelings(this.id);
    }

    User.prototype.summary = function(extend) {
      var u;
      if (extend == null) {
        extend = false;
      }
      u = clone(this);
      delete u.password;
      u.arrived_feelings = this.arrived_feelings.length;
      u.my_feelings = this.feelings.mines_len();
      u.rcv_feelings = this.feelings.rcvs_len();
      if (extend) {
        u.my_shared = this.feelings.my_actives().length;
        u.rcv_shared = this.feelings.rcv_actives().length;
      }
      return u;
    };

    User.prototype.valid_arrived_feeling = function(id) {
      return this.arrived_feelings.length > 0 && this.arrived_feelings[0] === id;
    };

    User.prototype.pop_arrived_feeling = function() {
      var fid;
      fid = this.arrived_feelings.pop();
      this.arrived_feelings = [];
      return gDispatcher.register_user(this.id);
    };

    User.prototype.grab_feeling = function(fid) {
      return this.feelings.push_rcv(fid);
    };

    return User;

  })();

  WaitItem = (function() {
    function WaitItem(id) {
      this.id = id;
      this.wait_time = now();
    }

    return WaitItem;

  })();

  Dispatcher = (function() {
    Dispatcher.MIN_USER_WAIT_TIME = 5000;

    Dispatcher.INTERVAL = 5000;

    function Dispatcher() {
      var u, uid, _ref;
      this._user_que = [];
      this._item_que = [];
      _ref = gDB.users();
      for (uid in _ref) {
        u = _ref[uid];
        if (u.arrived_feelings.length === 0) {
          register_user(uid);
        }
      }
      this._user_que.sort(function(a, b) {
        return a.wait_time - b.wait_time;
      });
    }

    Dispatcher.prototype.run = function() {
      var fid, hungry_users, u, wu, _now, _results;
      hungry_users = [];
      _now = now();
      while (this._user_que.length > 0) {
        wu = this._user_que.shift();
        u = gDB.user(wu.id);
        if (!u) {
          continue;
        }
        if (_now - u.wait_time < Dispatcher.MIN_USER_WAIT_TIME) {
          hungry_users.push(wu);
          break;
        }
        fid = this.select_item(wu);
        if (!fid) {
          hungry_users.push(wu);
          continue;
        }
        u.arrived_feelings.push(fid);
      }
      _results = [];
      while (hungry_users.length > 0) {
        _results.push(this._user_que.unshift(hungry_users.pop()));
      }
      return _results;
    };

    Dispatcher.prototype.select_item = function(wu) {
      var candidates, f, item, n_candi, reusable, selected, wf, _i, _now, _ref, _results;
      candidates = [];
      n_candi = 0;
      reusable = [];
      _now = now();
      while (this._item_que.length > 0 && n_candi < 30) {
        wf = this._item_que.shift();
        item = gDB.feeling(wf.id);
        if (!(item && item.sharable())) {
          continue;
        }
        reusable.push(wf);
        if (item.has_group_perm(wu.id)) {
          continue;
        }
        (function() {
          _results = [];
          for (var _i = 0, _ref = item.weight(_now - wu.wait_time); 0 <= _ref ? _i <= _ref : _i >= _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this).forEach(function() {
          return candidates.push(wf);
        });
        n_candi++;
      }
      selected = candidates.length === 0 ? null : candidates[rand(0, candidates.length - 1)];
      while (reusable.length > 0) {
        f = reusable.pop();
        if (selected && selected.id === f.id) {
          continue;
        }
        this._item_que.unshift(f);
      }
      if (selected) {
        this._item_que.push(selected);
      }
      return selected != null ? selected.id : void 0;
    };

    Dispatcher.prototype.register_item = function(id) {
      return this._item_que.push(new WaitItem(id));
    };

    Dispatcher.prototype.register_user = function(uid) {
      return this._user_que.push(new WaitItem(uid));
    };

    Dispatcher.prototype.latest_feelings = function(n) {
      var r, wf, _i, _ref;
      r = [];
      _ref = this._item_que;
      for (_i = _ref.length - 1; _i >= 0; _i += -1) {
        wf = _ref[_i];
        if (r.length >= n) {
          break;
        }
        if (wf) {
          r.push(wf.id);
        }
      }
      return r;
    };

    Dispatcher.prototype.log = function() {
      var u, uid, _ref;
      console.log("name, hearts, arrived, my, rcv");
      _ref = gDB.users();
      for (uid in _ref) {
        u = _ref[uid];
        console.log("" + u.name + ", " + u.n_hearts + ", " + u.arrived_feelings.length + ", " + (u.feelings.mines_len()) + ", " + (u.feelings.rcvs_len()));
      }
      console.log("userQ: " + (this._user_que.map(function(wu) {
        return JSON.stringify(gDB.user(wu.id).name);
      })));
      return console.log("itemQ: " + (this._item_que.map(function(wf) {
        return wf.id;
      }).join()));
    };

    return Dispatcher;

  })();

  app.post('/users', function(req, res) {
    var email, name, password;
    name = req.body.name;
    email = req.body.email;
    password = req.body.password;
    if (gDB.email(email)) {
      res.send(400, "Duplicated email");
      return;
    }
    User.create(name, 'img/profile.jpg', email, password);
    return res.json({});
  });

  app.get('/api/me', function(req, res) {
    var me;
    me = gDB.user(req.session.user_id);
    return res.json(me.summary(true));
  });

  app.get('/api/feelings', function(req, res) {
    var from, from_idx, me, n, skip, type;
    me = gDB.user(req.session.user_id);
    skip = req.query.skip && parseInt(req.query.skip) || 0;
    n = req.query.n && parseInt(req.query.n) || 30;
    type = req.query.type;
    from = req.query.from || 0;
    return res.json(type === 'my' ? (from_idx = from === 0 ? 0 : me.feelings.find_mine_idx(from), me.feelings.mines(max(0, from_idx + skip), min(me.feelings.mines_len(), from_idx + skip + n)).map(function(f) {
      return f.extend(me.id);
    })) : type === 'rcv' ? (from_idx = from === 0 ? 0 : me.feelings.find_rcv_idx(from), me.feelings.rcvs(max(0, from_idx + skip), min(me.feelings.rcvs_len(), from_idx + skip + n)).map(function(f) {
      return f.extend(me.id);
    })) : me.feelings.actives().map(function(f) {
      return f.extend(me.id);
    }));
  });

  app.post('/api/feelings', function(req, res) {
    var blah, is_public, me, word;
    me = gDB.user(req.session.user_id);
    word = req.body.word;
    blah = req.body.blah;
    is_public = req.body.is_public || true;
    if (!(word && blah && is_public)) {
      res.send(400, "Invalid Parameters");
      return;
    }
    Feeling.create(me, is_public, word, blah);
    return res.json({});
  });

  app.get('/api/feelings/:id', function(req, res) {
    var f, id, me;
    me = gDB.user(req.session.user_id);
    id = req.params.id;
    f = gDB.feeling(id);
    if (!f) {
      return res.send(404, "No such feeling: " + id);
    } else if (!f.has_group_perm(me.id)) {
      return res.json(f.summary());
    } else {
      return res.json(f.extend_full(me.id));
    }
  });

  app.put('/api/feelings/:id', function(req, res) {
    var f, id, is_public, me;
    me = gDB.user(req.session.user_id);
    id = req.params.id;
    is_public = req.body.is_public;
    f = gDB.feeling(id);
    if (!(f && f.has_own_perm(me.id))) {
      return res.send(406, "No permission to access this feeling: " + id);
    } else {
      f.set_public(is_public);
      return res.json({});
    }
  });

  app.put('/api/feelings/:id/like', function(req, res) {
    var f, id, me, user_id;
    me = gDB.user(req.session.user_id);
    id = req.params.id;
    user_id = req.body.user_id;
    f = gDB.feeling(id);
    if (!(f && f.has_own_perm(me.id))) {
      return res.send(406, "No permission to access this feeling: " + id);
    } else {
      if (f.like) {
        return res.send(406, "Already Done");
      } else {
        f.like = user_id;
        gDB.user(user_id).n_hearts++;
        return res.json({});
      }
    }
  });

  app.del('/api/feelings/:id', function(req, res) {
    var f, id, me;
    me = gDB.user(req.session.user_id);
    id = req.params.id;
    f = gDB.feeling(id);
    if (!(f && f.has_own_perm(me.id))) {
      return res.send(406, "No permission to access this feeling: " + id);
    } else {
      f.remove();
      return res.json({});
    }
  });

  app.post('/api/feelings/:id/talks/:user_id/comments', function(req, res) {
    var blah, comment, f, id, me, user_id;
    me = gDB.user(req.session.user_id);
    id = req.params.id;
    user_id = req.params.user_id;
    blah = req.body.blah;
    console.log("comment: " + blah);
    f = gDB.feeling(id);
    if (!(f && f.has_group_perm(me.id))) {
      res.send(406, "No permission to access this feeling: " + id);
      return;
    }
    if (!f.sharable()) {
      res.send(406, "This feeling is no longer sharable.");
      return;
    }
    comment = {
      user_id: me.id,
      blah: blah,
      time: now()
    };
    if (f.has_own_perm(me.id)) {
      f.talks[user_id].push(comment);
    } else {
      f.talks[me.id].push(comment);
    }
    return res.json({});
  });

  app.get('/api/arrived_feelings', function(req, res) {
    var f, fid, me, r, _i, _len, _ref;
    me = gDB.user(req.session.user_id);
    r = [];
    _ref = me.arrived_feelings;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      fid = _ref[_i];
      f = gDB.feeling(fid);
      if (f && f.sharable()) {
        r.push(f.summary());
      } else {
        me.pop_arrived_feeling();
      }
    }
    return res.json(r);
  });

  app.put('/api/arrived_feelings/:id', function(req, res) {
    var f, id, me;
    me = gDB.user(req.session.user_id);
    id = req.params.id;
    if (!me.valid_arrived_feeling(id)) {
      res.send(404, "No such feeling: " + id);
      return;
    }
    me.pop_arrived_feeling();
    f = gDB.feeling(id);
    if (!(f && f.sharable())) {
      throw "This feeling is no longer sharable.";
    } else {
      f.grant_group_perm(me.id);
      me.grab_feeling(id);
    }
    return res.json(f.extend_full(me.id));
  });

  app.get('/api/live_feelings', function(req, res) {
    var me, n;
    me = gDB.user(req.session.user_id);
    n = req.query.n || 20;
    return res.json(gDispatcher.latest_feelings(n).map(function(fid) {
      var _ref;
      return (_ref = gDB.feeling(fid)) != null ? _ref.anony_content() : void 0;
    }));
  });

  clone = function(obj) {
    return JSON.parse(JSON.stringify(obj));
  };

  max = function(a, b) {
    if (a >= b) {
      return a;
    } else {
      return b;
    }
  };

  min = function(a, b) {
    if (a < b) {
      return a;
    } else {
      return b;
    }
  };

  remove_item = function(arr, i) {
    if (i > -1) {
      return arr.splice(i, 1);
    }
  };

  now = function() {
    return new Date().getTime();
  };

  rand = function(s, e) {
    return Math.round(Math.random() * e) + s;
  };

  concat = function(a, b) {
    var x, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = b.length; _i < _len; _i++) {
      x = b[_i];
      _results.push(a.push(x));
    }
    return _results;
  };

  len = function(obj) {
    return Object.keys(obj).length;
  };

  merge_feelings = function(a, b) {
    var af, bf, i, j, r;
    r = [];
    i = j = 0;
    while (true) {
      if (a.length === i) {
        concat(r, b.slice(j, b.length));
        return r;
      }
      if (b.length === j) {
        concat(r, a.slice(i, a.length));
        return r;
      }
      af = gDB.feeling(a[i]);
      bf = gDB.feeling(b[j]);
      if (af.time > bf.time) {
        r.push(af);
        i++;
      } else {
        r.push(bf);
        j++;
      }
    }
    return r;
  };

  gDB = new DB();

  gFeelingContainer = [];

  gDispatcher = new Dispatcher();

  schedule = function() {
    var fid;
    gDispatcher.run();
    gDispatcher.log();
    while (gFeelingContainer.length >= 100) {
      fid = gFeelingContainer.shift();
      gDB.del_feeling(fid);
    }
    return setTimeout(schedule, Dispatcher.INTERVAL);
  };

  schedule();

  u0 = User.create('sun', 'img/profile.jpg', 'sun@gmail.com', 'sun00');

  u1 = User.create('moon', 'img/profile2.jpg', 'moon@gmail.com', 'moon00');

  u2 = User.create('asdf', 'img/profile4.jpg', 'asdf', 'asdf');

  auto_feeling = function(user) {
    var a, word, _i, _ref, _results;
    word = rand(0, 29);
    a = [];
    (function() {
      _results = [];
      for (var _i = 0, _ref = rand(0, 9); 0 <= _ref ? _i <= _ref : _i >= _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this).forEach(function() {
      return a.push('blah ');
    });
    Feeling.create(user, true, word, a.join(''));
    return setTimeout(auto_feeling, 15000, user);
  };

  auto_feeling(u0);

  auto_feeling(u1);

  app.listen('3333');

  console.log('listening on 3333');

}).call(this);
