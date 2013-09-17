// Generated by CoffeeScript 1.6.3
(function() {
  var Dispatcher, Feeling, Session, User, app, auto_feeling, clone, concat, express, g_dispatcher, g_emails, g_feelings, g_feelings_seq, g_sessions, g_users, g_users_seq, max, merge_feelings, min, now, rand, remove_item, require_auth, u0, u1, u2, valid_session;

  express = require('express');

  app = express();

  valid_session = function(user_id) {
    var ss;
    if (!user_id) {
      return false;
    }
    ss = g_sessions[user_id];
    if (!ss) {
      return false;
    }
    if (ss.expired()) {
      delete g_sessions[user_id];
      return false;
    }
    ss.update();
    return true;
  };

  require_auth = function(req, res, next) {
    if (!valid_session(req.session.user_id)) {
      console.log('401');
      return res.send(401);
    } else {
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
    user_id = g_emails[req.body.email];
    if (user_id) {
      u = g_users[user_id];
      if (u && u.password === req.body.password) {
        req.session.user_id = u.id;
        g_sessions[u.id] = new Session(u.id);
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
      delete g_sessions[req.session.user_id];
      return res.json({});
    }
  });

  g_sessions = {};

  g_emails = {};

  g_users = {};

  g_feelings = {};

  g_feelings_seq = 1;

  g_users_seq = 1;

  Session = (function() {
    Session.EXPIRE_TIME = 60 * 1000;

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
    Feeling.SHARE_DUR = 60 * 60 * 1000;

    function Feeling(me, is_public, word, blah) {
      this.word = word;
      this.blah = blah;
      this.user_id = me.id;
      this.id = g_feelings_seq++;
      this.status = is_public ? 'public' : 'private';
      this.time = now();
      this.talks = {};
      me.my_feelings.unshift(this.id);
      if (is_public) {
        g_dispatcher.register_item(this);
      }
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

    Feeling.prototype.add_to_group = function(user) {
      this.talks[user.id] = [];
      return user.rcv_feelings.unshift(this.id);
    };

    Feeling.prototype.summary = function() {
      return {
        id: this.id,
        user_id: this.user_id,
        time: this.time,
        word: this.word
      };
    };

    Feeling.prototype.extend = function(user_id) {
      var comments, tuid, u, x, _ref;
      x = clone(this);
      u = g_users[x.user_id];
      x.user = u.summary();
      x.share = this.sharable();
      if (!this.has_own_perm(user_id)) {
        x.own = false;
        x.n_talk_users = 1;
        x.n_talk_msgs = this.talks[user_id].length;
      } else {
        x.own = true;
        x.n_talk_users = Object.keys(x.talks).length;
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
      var comments, tu, tuid, u, x, _ref;
      x = this.extend(user_id);
      if (!this.has_own_perm(user_id)) {
        x.talks[user_id] = this.talks[user_id];
      }
      u = g_users[user_id];
      x.talk_user = {};
      x.talk_user[u.id] = {
        name: u.name,
        img: u.img
      };
      _ref = x.talks;
      for (tuid in _ref) {
        comments = _ref[tuid];
        tu = g_users[tuid];
        x.talk_user[tuid] = {
          name: tu.name,
          img: tu.img
        };
      }
      return x;
    };

    Feeling.prototype.weight = function(user_id) {
      return 0;
    };

    Feeling.prototype.set_public = function(is_public) {
      if (this.status === 'removed') {
        return;
      }
      if (this.status === 'private' && is_public) {
        this.status = 'public';
        if (this.sharable()) {
          return g_dispatcher.register_item(this);
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

  Dispatcher = (function() {
    Dispatcher.WAIT_TIME = 5000;

    Dispatcher.INTERVAL = 5000;

    Dispatcher.prototype.user_que = [];

    Dispatcher.prototype.item_que = [];

    function Dispatcher() {
      var u, _i, _len;
      for (_i = 0, _len = g_users.length; _i < _len; _i++) {
        u = g_users[_i];
        if (u.arrived_feelings.length === 0) {
          register(u);
        }
      }
      this.user_que.sort(function(a, b) {
        return a.wait_time - b.wait_time;
      });
    }

    Dispatcher.prototype.schedule = function() {
      var hungry_users, item, u, uid;
      hungry_users = [];
      while (g_dispatcher.user_que.length > 0) {
        uid = g_dispatcher.user_que.shift();
        u = g_users[uid];
        if (!u) {
          continue;
        }
        if (now() - u.wait_time < Dispatcher.WAIT_TIME) {
          hungry_users.push(uid);
          break;
        }
        item = g_dispatcher.select_item(uid);
        if (!item) {
          hungry_users.push(uid);
          continue;
        }
        u.arrived_feelings.push(item.id);
      }
      while (hungry_users.length > 0) {
        g_dispatcher.user_que.unshift(hungry_users.pop());
      }
      setTimeout(g_dispatcher.schedule, Dispatcher.INTERVAL);
      return g_dispatcher.log();
    };

    Dispatcher.prototype.select_item = function(uid) {
      var candidates, fid, item, n, n_candi, reusable, _i, _ref;
      candidates = [];
      n_candi = 0;
      reusable = [];
      while (this.item_que.length > 0 && n_candi < 30) {
        fid = this.item_que.shift();
        item = g_feelings[fid];
        if (!(item && item.sharable())) {
          continue;
        }
        reusable.push(fid);
        if (item.has_group_perm(uid)) {
          continue;
        }
        for (n = _i = 0, _ref = item.weight(uid); 0 <= _ref ? _i <= _ref : _i >= _ref; n = 0 <= _ref ? ++_i : --_i) {
          candidates.push(item);
        }
        n_candi++;
      }
      while (reusable.length > 0) {
        this.item_que.push(reusable.shift());
      }
      if (candidates.length === 0) {
        return null;
      } else {
        return candidates[rand(0, candidates.length - 1)];
      }
    };

    Dispatcher.prototype.register_item = function(item) {
      return this.item_que.push(item.id);
    };

    Dispatcher.prototype.register = function(user) {
      this.user_que.push(user.id);
      return user.wait_time = now();
    };

    Dispatcher.prototype.log = function() {
      var fid, items, u, uid, users, _i, _j, _len, _len1, _ref, _ref1;
      console.log("name, hearts, arrived, my, rcv");
      for (uid in g_users) {
        u = g_users[uid];
        console.log("" + u.name + ", " + u.n_hearts + ", " + u.arrived_feelings.length + ", " + u.my_feelings.length + ", " + u.rcv_feelings.length);
      }
      users = [];
      _ref = g_dispatcher.user_que;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        uid = _ref[_i];
        users.push(JSON.stringify(g_users[uid].name));
      }
      console.log("userQ: " + (users.join()));
      items = [];
      _ref1 = g_dispatcher.item_que;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        fid = _ref1[_j];
        items.push(fid);
      }
      return console.log("itemQ: " + (items.join()));
    };

    return Dispatcher;

  })();

  User = (function() {
    function User(name, img, email, password) {
      this.name = name;
      this.img = img;
      this.email = email;
      this.password = password;
      this.id = g_users_seq++;
      this.n_hearts = 0;
      this.n_availables = 0;
      this.arrived_feelings = [];
      this.my_feelings = [];
      this.rcv_feelings = [];
      g_dispatcher.register(this);
      g_emails[this.email] = this.id;
    }

    User.prototype.summary = function(extend) {
      var u;
      if (extend == null) {
        extend = false;
      }
      u = clone(this);
      delete u.password;
      u.arrived_feelings = this.arrived_feelings.length;
      u.my_feelings = this.my_feelings.length;
      u.rcv_feelings = this.rcv_feelings.length;
      if (extend) {
        u.my_shared = this.my_shared().length;
        u.rcv_shared = this.rcv_shared().length;
      }
      return u;
    };

    User.prototype.arrived_to_rcv = function(id) {
      var fid;
      fid = this.arrived_feelings.pop();
      this.arrived_feelings = [];
      return g_dispatcher.register(this);
    };

    User.prototype.my_shared = function() {
      var f, fid, r, _i, _len, _ref;
      r = [];
      _ref = this.my_feelings;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        fid = _ref[_i];
        f = g_feelings[fid];
        if (!f) {
          continue;
        }
        if (!f.sharable_time()) {
          break;
        }
        if (f.sharable()) {
          r.push(fid);
        }
      }
      return r;
    };

    User.prototype.rcv_shared = function() {
      var f, fid, r, _i, _len, _ref;
      r = [];
      _ref = this.rcv_feelings;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        fid = _ref[_i];
        f = g_feelings[fid];
        if (!f) {
          continue;
        }
        if (!f.sharable_time()) {
          break;
        }
        if (f.sharable()) {
          r.push(fid);
        }
      }
      return r;
    };

    return User;

  })();

  app.post('/users', function(req, res) {
    var email, name, password, u;
    name = req.body.name;
    email = req.body.email;
    password = req.body.password;
    if (g_emails[email]) {
      res.send(400, "Duplicated email");
      return;
    }
    u = new User(name, 'img/profile.jpg', email, password);
    g_users[u.id] = u;
    return res.json({});
  });

  app.get('/api/me', function(req, res) {
    var me;
    me = g_users[req.session.user_id];
    return res.json(me.summary(true));
  });

  app.get('/api/feelings', function(req, res) {
    var a, b, f, fid, me, n, r, skip, type, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2, _ref3;
    me = g_users[req.session.user_id];
    skip = req.params.skip || 0;
    n = req.params.n || 30;
    type = req.params.type;
    r = [];
    if (type === 'my') {
      _ref = me.my_feelings.slice(max(0, skip), min(my_feelings.length, skip + n));
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        fid = _ref[_i];
        f = g_feelings[fid];
        if (f) {
          r.push(f.extend(me.id));
        }
      }
    } else if (type === 'rcv') {
      _ref1 = me.rcv_feelings.slice(max(0, skip), min(rcv_feelings.length, skip + n));
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        fid = _ref1[_j];
        f = g_feelings[fid];
        if (f) {
          r.push(f.extend(me.id));
        }
      }
    } else {
      a = me.my_shared();
      b = me.rcv_shared();
      _ref2 = me.my_shared();
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        fid = _ref2[_k];
        f = g_feelings[fid];
        r.push(f.extend(me.id));
      }
      _ref3 = me.rcv_shared();
      for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
        fid = _ref3[_l];
        f = g_feelings[fid];
        r.push(f.extend(me.id));
      }
    }
    return res.json(r);
  });

  app.post('/api/feelings', function(req, res) {
    var blah, f, is_public, me, word;
    me = g_users[req.session.user_id];
    word = req.body.word;
    blah = req.body.blah;
    is_public = req.body.is_public || true;
    if (!(word && blah && is_public)) {
      res.send(400, "Invalid Parameters");
      return;
    }
    f = new Feeling(me, is_public, word, blah);
    g_feelings[f.id] = f;
    return res.json({});
  });

  app.get('/api/feelings/:id', function(req, res) {
    var f, id, me;
    me = g_users[req.session.user_id];
    id = req.params.id;
    f = g_feelings[id];
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
    me = g_users[req.session.user_id];
    id = req.params.id;
    is_public = req.body.is_public;
    f = g_feelings[id];
    if (!(f && f.has_own_perm(me.id))) {
      return res.send(406, "No permission to access this feeling: " + id);
    } else {
      f.set_public(is_public);
      return res.json({});
    }
  });

  app.put('/api/feelings/:id/like', function(req, res) {
    var f, id, me, user_id;
    me = g_users[req.session.user_id];
    id = req.params.id;
    user_id = req.body.user_id;
    f = g_feelings[id];
    if (!(f && f.has_own_perm(me.id))) {
      return res.send(406, "No permission to access this feeling: " + id);
    } else {
      if (f.like) {
        return res.send(406, "Already Done");
      } else {
        f.like = user_id;
        g_users[user_id].n_hearts++;
        return res.json({});
      }
    }
  });

  app.del('/api/feelings/:id', function(req, res) {
    var f, id, me;
    me = g_users[req.session.user_id];
    id = req.params.id;
    f = g_feelings[id];
    if (!(f && f.has_own_perm(me.id))) {
      return res.send(406, "No permission to access this feeling: " + id);
    } else {
      f.remove();
      return res.json({});
    }
  });

  app.post('/api/feelings/:id/talks/:user_id/comments', function(req, res) {
    var blah, f, id, me, user_id;
    me = g_users[req.session.user_id];
    id = req.params.id;
    user_id = req.params.user_id;
    blah = req.body.blah;
    f = g_feelings[id];
    if (!(f && f.has_group_perm(me.id))) {
      res.send(406, "No permission to access this feeling: " + id);
      return;
    }
    if (!f.sharable()) {
      res.send(406, "This feeling is no longer sharable.");
      return;
    }
    if (f.has_own_perm(me.id)) {
      f.talks[user_id].push({
        user_id: user_id,
        blah: blah,
        time: now()
      });
    } else {
      f.talks[me.id].push({
        user_id: me.id,
        blah: blah,
        time: now()
      });
    }
    return res.json({});
  });

  app.get('/api/arrived_feelings', function(req, res) {
    var f, fid, me, r, _i, _len, _ref;
    me = g_users[req.session.user_id];
    r = [];
    _ref = me.arrived_feelings;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      fid = _ref[_i];
      f = g_feelings[fid];
      if (f && f.sharable()) {
        r.push(f.summary());
      }
    }
    return res.json(r);
  });

  app.put('/api/arrived_feelings/:id', function(req, res) {
    var f, id, me;
    me = g_users[req.session.user_id];
    id = req.params.id;
    if (!me.arrived_to_rcv(id)) {
      req.send(404, "No such feeling: " + id);
      return;
    }
    f = g_feelings[id];
    if (!f.sharable()) {
      res.send(406, "This feeling is no longer sharable.");
      return;
    }
    f.add_to_group(me);
    return res.json(f.extend_full(me.id));
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
      af = g_feelings[a[i]];
      bf = g_feelings[b[j]];
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

  g_dispatcher = new Dispatcher();

  g_dispatcher.schedule();

  u0 = new User('sun', 'img/profile.jpg', 'sun@gmail.com', 'sun00');

  u1 = new User('moon', 'img/profile.jpg', 'moon@gmail.com', 'moon00');

  u2 = new User('asdf', 'img/profile.jpg', 'asdf', 'asdf');

  g_users[u0.id] = u0;

  g_users[u1.id] = u1;

  g_users[u2.id] = u2;

  auto_feeling = function() {
    var a, f, n, word, _i, _ref;
    console.log('## auto fill started');
    word = rand(0, 29);
    a = [];
    for (n = _i = 0, _ref = rand(0, 9); 0 <= _ref ? _i <= _ref : _i >= _ref; n = 0 <= _ref ? ++_i : --_i) {
      a.push('blah');
    }
    f = new Feeling(u0, true, word, a.join(''));
    g_feelings[f.id] = f;
    setTimeout(auto_feeling, 10000);
    return console.log('## auto fill done');
  };

  auto_feeling();

  app.listen('3333');

  console.log('listening on 3333');

}).call(this);