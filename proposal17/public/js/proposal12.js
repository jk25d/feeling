// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var App, AppView, ArrivedFeeling, ArrivedFeelingView, ArrivedFeelings, Associate, Associates, BodyLayout, Comment, Feeling, FeelingView, FsView, HeaderLayout, Layout, LiveFeeling, LiveFeelingView, LiveFeelings, LiveFeelingsView, LoginView, Me, MyFeeling, MyFeelingView, MyFeelings, MyFeelingsView, MyStatusView, NavLayout, NewComment, NewCommentView, NewFeelingView, ReceivedFeeling, ReceivedFeelings, ReceivedFeelingsView, Router, SharedFeelings, SharedFeelingsView, SignupView, StatusLayout, Talk, TalkView, Tpl, Wookmark, gW, router, _ref, _ref1, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref20, _ref21, _ref22, _ref23, _ref24, _ref25, _ref26, _ref27, _ref28, _ref29, _ref3, _ref30, _ref31, _ref32, _ref33, _ref34, _ref35, _ref36, _ref37, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
    gW = [
      {
        w: '두렵다',
        c: '#556270'
      }, {
        w: '무섭다',
        c: '#556270'
      }, {
        w: '우울하다',
        c: '#7f94b0'
      }, {
        w: '기운이없다',
        c: '#938172'
      }, {
        w: '무기력하다',
        c: '#938172'
      }, {
        w: '의욕이없다',
        c: '#938172'
      }, {
        w: '불안하다',
        c: '#77cca4'
      }, {
        w: '외롭다',
        c: '#c3ff68'
      }, {
        w: '걱정된다',
        c: '#14b0d9'
      }, {
        w: '허전하다',
        c: '#14d925'
      }, {
        w: '삶이힘들다',
        c: '#e177b3'
      }, {
        w: '한심하다',
        c: '#ffc6e2'
      }, {
        w: '짜증난다',
        c: '#c6aae2'
      }, {
        w: '슬프다',
        c: '#77cca4'
      }, {
        w: '절망스럽다',
        c: '#d9cbb8'
      }, {
        w: '화난다',
        c: '#594944'
      }, {
        w: '쓸쓸하다',
        c: '#758fe6'
      }, {
        w: '초조하다',
        c: '#b5242e'
      }, {
        w: '마음아프다',
        c: '#29a9b3'
      }, {
        w: '열등감느낀다',
        c: '#e8175d'
      }, {
        w: '사랑스럽다',
        c: '#14b0d9'
      }, {
        w: '소중하다',
        c: '#c3ff68'
      }, {
        w: '설레다',
        c: '#14d925'
      }, {
        w: '즐겁다',
        c: '#e177b3'
      }, {
        w: '기쁘다',
        c: '#ffc6e2'
      }, {
        w: '뿌듯하다',
        c: '#c6aae2'
      }, {
        w: '만족스럽다',
        c: '#77cca4'
      }, {
        w: '가슴벅차다',
        c: '#d9cbb8'
      }, {
        w: '자신있다',
        c: '#f0ba3c'
      }, {
        w: '기운차다',
        c: '#c47147'
      }
    ];
    Wookmark = (function() {
      function Wookmark(id) {
        this.id = id;
      }

      Wookmark.prototype.apply = function() {
        var _ref, _ref1;
        if ((_ref = this.handler) != null) {
          if ((_ref1 = _ref.wookmarkInstance) != null) {
            _ref1.clear();
          }
        }
        this.handler = $("#" + this.id + " > li");
        return this.handler.wookmark({
          align: 'left',
          autoResize: true,
          container: $("#" + this.id),
          offset: 16,
          itemWidth: 260
        });
      };

      return Wookmark;

    })();
    Router = (function(_super) {
      __extends(Router, _super);

      function Router() {
        _ref = Router.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Router.prototype.routes = {
        '': 'index',
        'login': 'index',
        'logout': 'logout',
        'my_feelings': 'my_feelings',
        'shared_feelings': 'shared_feelings',
        'received_feelings': 'received_feelings'
      };

      Router.prototype.layout = {};

      Router.prototype.models = {};

      Router.prototype.initialize = function() {
        this.models.me = new Me;
        this.models.live_feelings = new LiveFeelings;
        this.models.associates = new Associates;
        this.models.my = new MyFeelings;
        this.models.received = new ReceivedFeelings;
        this.models.shared = new SharedFeelings;
        this.models.app = new App;
        this.layout.nav = new NavLayout;
        this.layout.header = new HeaderLayout;
        this.layout.status = new StatusLayout;
        this.layout.body = new BodyLayout;
        this.layout.nav.show(new AppView({
          model: this.models.app
        }));
        return _.bindAll(this, 'index', 'logout', 'my_feelings', 'received_feelings');
      };

      Router.prototype._login_view = function() {
        this.models.app.set({
          menu: '#menu_signup'
        });
        this.layout.header.show(new LoginView);
        this.layout.status.show();
        return this.layout.body.show();
      };

      Router.prototype.index = function() {
        return $.ajax({
          url: '../sessions',
          statusCode: {
            401: function() {},
            403: function() {}
          },
          context: this,
          success: function() {
            return this.navigate('shared_feelings', {
              trigger: true
            });
          },
          error: function() {
            return this._login_view();
          }
        });
      };

      Router.prototype.logout = function() {
        return $.ajax({
          url: '../sessions',
          type: 'DELETE',
          dataType: 'json',
          success: function(data) {
            return window.location = '/';
          }
        });
      };

      Router.prototype.shared_feelings = function() {
        this.models.app.set({
          menu: '#menu_share'
        });
        this.models.me.fetch({
          success: function(model, res) {
            return router.layout.status.show(new MyStatusView({
              model: model
            }));
          }
        });
        this.models.shared.fetch({
          success: function(model, res) {
            return router.layout.body.show(new SharedFeelingsView({
              model: model
            }));
          }
        });
        return this.layout.header.show(new NewFeelingView);
      };

      Router.prototype.my_feelings = function() {
        this.models.app.set({
          menu: '#menu_my'
        });
        this.models.me.fetch({
          success: function(model, res) {
            return router.layout.status.show(new MyStatusView({
              model: model
            }));
          }
        });
        this.models.my.fetch_more();
        this.layout.header.show(new NewFeelingView);
        return this.layout.body.show(new MyFeelingsView({
          model: this.models.my
        }));
      };

      Router.prototype.received_feelings = function() {
        this.models.app.set({
          menu: '#menu_received'
        });
        this.models.me.fetch({
          success: function(model, res) {
            return router.status.show(new MyStatusView({
              model: model
            }));
          }
        });
        this.models.live_feelings.fetch();
        this.models.received.fetch_more();
        this.layout.header.show(new LiveFeelingsView({
          model: this.models.live_feelings
        }));
        return this.layout.body.show(new ReceivedFeelingsView({
          model: this.models.received
        }));
      };

      return Router;

    })(Backbone.Router);
    App = (function(_super) {
      __extends(App, _super);

      function App() {
        _ref1 = App.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      App.prototype.defaults = {
        menu: '#menu_signup'
      };

      return App;

    })(Backbone.Model);
    Me = (function(_super) {
      __extends(Me, _super);

      function Me() {
        _ref2 = Me.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      Me.prototype.defaults = {
        id: -1,
        name: '',
        email: '',
        img: '',
        n_hearts: 0,
        n_available_feelings: 0,
        arrived_feelings: 0,
        my_feelings: 0,
        rcv_feelings: 0,
        my_shared: 0,
        rcv_shared: 0
      };

      Me.prototype.url = '../api/me';

      return Me;

    })(Backbone.Model);
    LiveFeeling = (function(_super) {
      __extends(LiveFeeling, _super);

      function LiveFeeling() {
        _ref3 = LiveFeeling.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      return LiveFeeling;

    })(Backbone.Model);
    LiveFeelings = (function(_super) {
      __extends(LiveFeelings, _super);

      function LiveFeelings() {
        _ref4 = LiveFeelings.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      LiveFeelings.prototype.model = LiveFeeling;

      LiveFeelings.prototype.url = '../api/live_feelings';

      return LiveFeelings;

    })(Backbone.Collection);
    Associate = (function(_super) {
      __extends(Associate, _super);

      function Associate() {
        _ref5 = Associate.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      return Associate;

    })(Backbone.Model);
    Associates = (function(_super) {
      __extends(Associates, _super);

      function Associates() {
        _ref6 = Associates.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      Associates.prototype.url = '../api/associates';

      return Associates;

    })(Backbone.Collection);
    Comment = (function(_super) {
      __extends(Comment, _super);

      function Comment() {
        _ref7 = Comment.__super__.constructor.apply(this, arguments);
        return _ref7;
      }

      return Comment;

    })(Backbone.Model);
    Talk = (function(_super) {
      __extends(Talk, _super);

      function Talk() {
        _ref8 = Talk.__super__.constructor.apply(this, arguments);
        return _ref8;
      }

      return Talk;

    })(Backbone.Model);
    MyFeeling = (function(_super) {
      __extends(MyFeeling, _super);

      function MyFeeling() {
        _ref9 = MyFeeling.__super__.constructor.apply(this, arguments);
        return _ref9;
      }

      return MyFeeling;

    })(Backbone.Model);
    MyFeelings = (function(_super) {
      __extends(MyFeelings, _super);

      function MyFeelings() {
        _ref10 = MyFeelings.__super__.constructor.apply(this, arguments);
        return _ref10;
      }

      MyFeelings.prototype.defaults = {
        type: 'my'
      };

      MyFeelings.prototype.model = MyFeeling;

      MyFeelings.prototype.url = '../api/my_feelings';

      MyFeelings.prototype.fetch_more = function() {
        var _ref11;
        return new MyFeelings().fetch({
          data: {
            type: this.get('type'),
            skip: ((_ref11 = this.models) != null ? _ref11.length : void 0) || 0,
            n: 10
          },
          success: function(model, res) {
            var len, m, _i, _len, _ref12;
            len = router.models.my.length;
            _ref12 = model.models;
            for (_i = 0, _len = _ref12.length; _i < _len; _i++) {
              m = _ref12[_i];
              router.models.my.add(m);
            }
            if (router.models.my.length > len) {
              return router.models.my.trigger('concat', model.models);
            }
          }
        });
      };

      return MyFeelings;

    })(Backbone.Collection);
    ReceivedFeeling = (function(_super) {
      __extends(ReceivedFeeling, _super);

      function ReceivedFeeling() {
        _ref11 = ReceivedFeeling.__super__.constructor.apply(this, arguments);
        return _ref11;
      }

      return ReceivedFeeling;

    })(Backbone.Model);
    ReceivedFeelings = (function(_super) {
      __extends(ReceivedFeelings, _super);

      function ReceivedFeelings() {
        _ref12 = ReceivedFeelings.__super__.constructor.apply(this, arguments);
        return _ref12;
      }

      ReceivedFeelings.prototype.defaults = {
        type: 'rcv'
      };

      ReceivedFeelings.prototype.model = ReceivedFeeling;

      ReceivedFeelings.prototype.url = '../api/received_feelings';

      ReceivedFeelings.prototype.fetch_more = function() {
        var _ref13;
        return new ReceivedFeelings().fetch({
          data: {
            type: this.get('type'),
            skip: ((_ref13 = this.models) != null ? _ref13.length : void 0) || 0,
            n: 10
          },
          success: function(model, res) {
            var len, m, _i, _len, _ref14;
            len = router.models.received.length;
            _ref14 = model.models;
            for (_i = 0, _len = _ref14.length; _i < _len; _i++) {
              m = _ref14[_i];
              router.models.received.add(m);
            }
            if (router.models.received.length > len) {
              return router.models.received.trigger('concat', model.models);
            }
          }
        });
      };

      return ReceivedFeelings;

    })(Backbone.Collection);
    ArrivedFeeling = (function(_super) {
      __extends(ArrivedFeeling, _super);

      function ArrivedFeeling() {
        _ref13 = ArrivedFeeling.__super__.constructor.apply(this, arguments);
        return _ref13;
      }

      return ArrivedFeeling;

    })(Backbone.Model);
    ArrivedFeelings = (function(_super) {
      __extends(ArrivedFeelings, _super);

      function ArrivedFeelings() {
        _ref14 = ArrivedFeelings.__super__.constructor.apply(this, arguments);
        return _ref14;
      }

      ArrivedFeelings.prototype.model = ArrivedFeeling;

      ArrivedFeelings.prototype.url = '../api/arrived_feelings';

      return ArrivedFeelings;

    })(Backbone.Collection);
    NewComment = (function(_super) {
      __extends(NewComment, _super);

      function NewComment() {
        _ref15 = NewComment.__super__.constructor.apply(this, arguments);
        return _ref15;
      }

      return NewComment;

    })(Backbone.Model);
    Feeling = (function(_super) {
      __extends(Feeling, _super);

      function Feeling() {
        _ref16 = Feeling.__super__.constructor.apply(this, arguments);
        return _ref16;
      }

      Feeling.prototype.url = '../api/feelings';

      return Feeling;

    })(Backbone.Model);
    SharedFeelings = (function(_super) {
      __extends(SharedFeelings, _super);

      function SharedFeelings() {
        _ref17 = SharedFeelings.__super__.constructor.apply(this, arguments);
        return _ref17;
      }

      SharedFeelings.prototype.defaults = {
        type: 'share'
      };

      SharedFeelings.prototype.model = Feeling;

      SharedFeelings.prototype.url = '../api/feelings';

      SharedFeelings.prototype.fetch = function(options) {
        if (options == null) {
          options = {};
        }
        options.data = {
          type: this.get('type')
        };
        return SharedFeelings.__super__.fetch.call(this, options);
      };

      return SharedFeelings;

    })(Backbone.Collection);
    Layout = (function() {
      function Layout() {}

      Layout.prototype.show = function(view) {
        if (this.current_view) {
          this.current_view.close();
        }
        if (!view) {
          return $("#" + this.id).empty();
        }
        this.current_view = view;
        this.current_view.show();
        $("#" + this.id).html(this.current_view.el);
        return this.current_view.on_rendered();
      };

      return Layout;

    })();
    NavLayout = (function(_super) {
      __extends(NavLayout, _super);

      function NavLayout() {
        _ref18 = NavLayout.__super__.constructor.apply(this, arguments);
        return _ref18;
      }

      NavLayout.prototype.id = 'fs_navbar';

      return NavLayout;

    })(Layout);
    HeaderLayout = (function(_super) {
      __extends(HeaderLayout, _super);

      function HeaderLayout() {
        _ref19 = HeaderLayout.__super__.constructor.apply(this, arguments);
        return _ref19;
      }

      HeaderLayout.prototype.id = 'fs_header';

      return HeaderLayout;

    })(Layout);
    StatusLayout = (function(_super) {
      __extends(StatusLayout, _super);

      function StatusLayout() {
        _ref20 = StatusLayout.__super__.constructor.apply(this, arguments);
        return _ref20;
      }

      StatusLayout.prototype.id = 'fs_status';

      return StatusLayout;

    })(Layout);
    BodyLayout = (function(_super) {
      __extends(BodyLayout, _super);

      function BodyLayout() {
        _ref21 = BodyLayout.__super__.constructor.apply(this, arguments);
        return _ref21;
      }

      BodyLayout.prototype.id = 'fs_body';

      return BodyLayout;

    })(Layout);
    FsView = (function(_super) {
      __extends(FsView, _super);

      function FsView() {
        _ref22 = FsView.__super__.constructor.apply(this, arguments);
        return _ref22;
      }

      FsView.prototype._attach = function(view) {
        this._views.push(view);
        view.show();
        return view;
      };

      FsView.prototype._detach_all = function() {
        var _results;
        this._views || (this._views = []);
        _results = [];
        while (this._views.length > 0) {
          _results.push(this._views.pop().close());
        }
        return _results;
      };

      FsView.prototype.show = function() {
        console.log("" + this.constructor.name + ".show");
        this._detach_all();
        this.$el.empty();
        this.render();
        return this.on_rendered();
      };

      FsView.prototype.on_rendered = function() {};

      FsView.prototype.close = function() {
        this._detach_all();
        this.remove();
        return this.off();
      };

      return FsView;

    })(Backbone.View);
    Tpl = (function() {
      function Tpl() {}

      Tpl.navbar = _.template($('#tpl_navbar').html());

      Tpl.login = _.template($('#tpl_login').html());

      Tpl.signup = _.template($('#tpl_signup').html());

      Tpl.my_status = _.template($('#tpl_my_status').html());

      Tpl.live_feeling = _.template($('#tpl_live_feeling').html());

      Tpl.live_status = _.template($('#tpl_live_status').html());

      Tpl.new_feeling = _.template($('#tpl_new_feeling').html());

      Tpl.talk = _.template($('#tpl_talk').html());

      Tpl.my_feeling = _.template($('#tpl_my_feeling').html());

      Tpl.new_comment = _.template($('#tpl_new_comment').html());

      Tpl.feeling = _.template($('#tpl_feeling').html());

      Tpl.arrived = _.template($('#tpl_arrived_feeling').html());

      Tpl.arrived_holder = _.template($('#tpl_arrived_holder').html());

      return Tpl;

    })();
    AppView = (function(_super) {
      __extends(AppView, _super);

      function AppView() {
        _ref23 = AppView.__super__.constructor.apply(this, arguments);
        return _ref23;
      }

      AppView.prototype.events = {
        'click .fs_menu': '_on_click_menu'
      };

      AppView.prototype.template = Tpl.navbar;

      AppView.prototype.initialize = function() {
        return this.model.on('change:menu', this.show, this);
      };

      AppView.prototype.render = function() {
        this.$el.html(this.template(this.model.toJSON()));
        this.$el.find('.fs_menu').removeClass('active');
        return $(this.model.get('menu')).addClass('active');
      };

      AppView.prototype._on_click_menu = function(e) {
        var current_hash, event_hash;
        event_hash = $(e.currentTarget).find('a').attr('href');
        current_hash = window.location.hash;
        if (event_hash.charAt(0) === '#' && event_hash === current_hash) {
          e.preventDefault();
          Backbone.history.fragment = null;
          return router.navigate(event_hash.substr(1), {
            trigger: true
          });
        }
      };

      AppView.prototype.close = function() {
        AppView.__super__.close.call(this);
        return this.model.off('change:menu', this.show);
      };

      return AppView;

    })(FsView);
    LoginView = (function(_super) {
      __extends(LoginView, _super);

      function LoginView() {
        _ref24 = LoginView.__super__.constructor.apply(this, arguments);
        return _ref24;
      }

      LoginView.prototype.events = {
        'click .fs_submit': '_on_submit'
      };

      LoginView.prototype.template = Tpl.login;

      LoginView.prototype.render = function() {
        return this.$el.html(this.template());
      };

      LoginView.prototype._on_submit = function() {
        return $.ajax({
          url: '../sessions',
          type: 'POST',
          dataType: 'json',
          context: this,
          data: {
            email: $('#email').val(),
            password: $('#password').val()
          },
          success: function(data) {
            router.models.app.set({
              'logged_in': true
            });
            return router.navigate('shared_feelings', {
              trigger: true
            });
          },
          fail: function() {
            return window.location = '/';
          }
        });
      };

      return LoginView;

    })(FsView);
    SignupView = (function(_super) {
      __extends(SignupView, _super);

      function SignupView() {
        _ref25 = SignupView.__super__.constructor.apply(this, arguments);
        return _ref25;
      }

      SignupView.prototype.events = {
        'click .fs_submit': '_on_submit'
      };

      SignupView.prototype.template = Tpl.signup;

      SignupView.prototype.render = function() {
        return this.$el.html(this.template());
      };

      SignupView.prototype._on_submit = function() {
        return console.log('signup submit');
      };

      return SignupView;

    })(FsView);
    MyStatusView = (function(_super) {
      __extends(MyStatusView, _super);

      function MyStatusView() {
        _ref26 = MyStatusView.__super__.constructor.apply(this, arguments);
        return _ref26;
      }

      MyStatusView.prototype.template = Tpl.my_status;

      MyStatusView.prototype.initialize = function() {
        return this.model.on('sync', this.show, this);
      };

      MyStatusView.prototype.render = function() {
        return this.$el.html(this.template(this.model.toJSON()));
      };

      MyStatusView.prototype.close = function() {
        MyStatusView.__super__.close.call(this);
        return this.model.off('sync', this.show);
      };

      return MyStatusView;

    })(FsView);
    LiveFeelingView = (function(_super) {
      __extends(LiveFeelingView, _super);

      function LiveFeelingView() {
        _ref27 = LiveFeelingView.__super__.constructor.apply(this, arguments);
        return _ref27;
      }

      LiveFeelingView.prototype.tagName = 'li';

      LiveFeelingView.prototype.template = Tpl.live_feeling;

      LiveFeelingView.prototype.render = function() {
        return this.$el.html(this.template(_.extend(this.model.toJSON(), {
          gW: gW
        })));
      };

      return LiveFeelingView;

    })(FsView);
    LiveFeelingsView = (function(_super) {
      __extends(LiveFeelingsView, _super);

      function LiveFeelingsView() {
        _ref28 = LiveFeelingsView.__super__.constructor.apply(this, arguments);
        return _ref28;
      }

      LiveFeelingsView.prototype.tagName = 'div';

      LiveFeelingsView.prototype.template = Tpl.live_status;

      LiveFeelingsView.prototype.initialize = function() {
        return this.model.on('sync', this.show, this);
      };

      LiveFeelingsView.prototype.render = function() {
        var holder, m, _i, _len, _ref29, _results;
        this.$el.html(this.template());
        holder = this.$el.find('#live_holder');
        _ref29 = this.model.models;
        _results = [];
        for (_i = 0, _len = _ref29.length; _i < _len; _i++) {
          m = _ref29[_i];
          _results.push(holder.append(this._attach(new LiveFeelingView({
            model: m
          })).el));
        }
        return _results;
      };

      LiveFeelingsView.prototype.close = function() {
        LiveFeelingsView.__super__.close.call(this);
        return this.model.off('sync', this.show);
      };

      return LiveFeelingsView;

    })(FsView);
    NewFeelingView = (function(_super) {
      __extends(NewFeelingView, _super);

      function NewFeelingView() {
        _ref29 = NewFeelingView.__super__.constructor.apply(this, arguments);
        return _ref29;
      }

      NewFeelingView.prototype.events = {
        'click .fs_submit': '_on_submit',
        'click #wordselect .ww': '_on_select_word'
      };

      NewFeelingView.prototype.template = Tpl.new_feeling;

      NewFeelingView.prototype.render = function() {
        return this.$el.html(this.template({
          gW: gW
        }));
      };

      NewFeelingView.prototype._on_select_word = function(e) {
        this.$el.find('#wordselect').find('.active').removeClass('active');
        $(e.currentTarget).addClass('active');
        if (!this._expanded) {
          this.$el.find('.content0-input').css('display', 'block');
          this._expanded = true;
          return router.layout.body.current_view.wookmark.apply();
        }
      };

      NewFeelingView.prototype._on_submit = function() {
        return $.ajax({
          url: '../api/feelings',
          type: 'POST',
          dataType: 'json',
          context: this,
          data: {
            word: this.$el.find('#wordselect').find('.active').attr('word-id'),
            blah: this.$el.find('#new_feeling_content').val(),
            is_public: true
          },
          success: function(data) {
            Backbone.history.fragment = null;
            return router.navigate('shared_feelings', {
              trigger: true
            });
          }
        });
      };

      return NewFeelingView;

    })(FsView);
    TalkView = (function(_super) {
      __extends(TalkView, _super);

      function TalkView() {
        _ref30 = TalkView.__super__.constructor.apply(this, arguments);
        return _ref30;
      }

      TalkView.prototype.template = Tpl.talk;

      TalkView.prototype.initialize = function() {
        return this.model.on('change', this.show, this);
      };

      TalkView.prototype.render = function() {
        return this.$el.html(this.template(this.model.toJSON()));
      };

      TalkView.prototype.close = function() {
        TalkView.__super__.close.call(this);
        return this.model.off('change', this.show);
      };

      return TalkView;

    })(FsView);
    MyFeelingView = (function(_super) {
      __extends(MyFeelingView, _super);

      function MyFeelingView() {
        _ref31 = MyFeelingView.__super__.constructor.apply(this, arguments);
        return _ref31;
      }

      MyFeelingView.prototype.tagName = 'li';

      MyFeelingView.prototype.events = {
        'click .inner': '_on_expand'
      };

      MyFeelingView.prototype.template = Tpl.my_feeling;

      MyFeelingView.prototype.initialize = function() {
        return this.model.on('change', this.show, this);
      };

      MyFeelingView.prototype.render = function() {
        var holder, m, talk, u, _ref32;
        this.$el.removeClass('rd6').removeClass('_sd0').removeClass('card');
        this.$el.addClass('rd6').addClass('_sd0').addClass('card');
        this.$el.html(this.template(_.extend(this.model.toJSON(), {
          gW: gW
        })));
        if (this._expand) {
          holder = this.$el.find('.talks');
          holder.empty();
          _ref32 = this.model.get('talks');
          for (u in _ref32) {
            talk = _ref32[u];
            m = {
              shared: this.model.get('share'),
              user_id: u,
              comments: talk
            };
            holder.append(this._attach(new TalkView({
              model: new Talk(m)
            })).el);
          }
        }
        if (this._on_expand_triggered) {
          this.$el.trigger('refreshWookmark');
        }
        return this._on_expand_triggered = false;
      };

      MyFeelingView.prototype._on_expand = function(event) {
        this._on_expand_triggered = true;
        this._expand = !this._expand;
        return this.show();
      };

      MyFeelingView.prototype.close = function() {
        MyFeelingView.__super__.close.call(this);
        return this.model.off('change', this.show, this);
      };

      return MyFeelingView;

    })(FsView);
    MyFeelingsView = (function(_super) {
      __extends(MyFeelingsView, _super);

      function MyFeelingsView() {
        _ref32 = MyFeelingsView.__super__.constructor.apply(this, arguments);
        return _ref32;
      }

      MyFeelingsView.prototype.tagName = 'ul';

      MyFeelingsView.prototype.id = 'my_feelings_holder';

      MyFeelingsView.prototype.className = 'fs_tiles';

      MyFeelingsView.prototype.initialize = function() {
        this._wookmark = new Wookmark(this.id);
        this.model.on('concat', this._on_concat, this);
        return $(window).on('scroll', this._on_scroll);
      };

      MyFeelingsView.prototype.render = function() {
        var m, _i, _len, _ref33, _results;
        _ref33 = this.model.models;
        _results = [];
        for (_i = 0, _len = _ref33.length; _i < _len; _i++) {
          m = _ref33[_i];
          _results.push(this.$el.append(this._attach(new MyFeelingView({
            model: m
          })).el));
        }
        return _results;
      };

      MyFeelingsView.prototype.on_rendered = function() {
        return this._wookmark.apply();
      };

      MyFeelingsView.prototype._on_scroll = function(e) {
        if ($(window).scrollTop() + $(window).height() > $(document).height() - 100) {
          return router.models.my.fetch_more();
        }
      };

      MyFeelingsView.prototype._on_concat = function(list) {
        var m, _i, _len;
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          m = list[_i];
          this.$el.append(this._attach(new MyFeelingView({
            model: m
          })).el);
        }
        return this._wookmark.apply();
      };

      MyFeelingsView.prototype.close = function() {
        MyFeelingsView.__super__.close.call(this);
        this.model.off('concat', this._on_concat);
        return $(window).off('scroll', this._on_scroll);
      };

      return MyFeelingsView;

    })(FsView);
    NewCommentView = (function(_super) {
      __extends(NewCommentView, _super);

      function NewCommentView() {
        _ref33 = NewCommentView.__super__.constructor.apply(this, arguments);
        return _ref33;
      }

      NewCommentView.prototype.className = 'new_comment';

      NewCommentView.prototype.events = {
        'click .fs_link': '_on_submit'
      };

      NewCommentView.prototype.template = Tpl.new_comment;

      NewCommentView.prototype.render = function() {
        this.$el.html(this.template());
        return this;
      };

      NewCommentView.prototype._on_submit = function(event) {
        return alert('not implemented');
      };

      return NewCommentView;

    })(FsView);
    FeelingView = (function(_super) {
      __extends(FeelingView, _super);

      function FeelingView() {
        _ref34 = FeelingView.__super__.constructor.apply(this, arguments);
        return _ref34;
      }

      FeelingView.prototype.tagName = 'li';

      FeelingView.prototype.events = {
        'click .inner': '_on_expand'
      };

      FeelingView.prototype.template = Tpl.feeling;

      FeelingView.prototype.initialize = function() {
        return this.model.on('sync', this.show, this);
      };

      FeelingView.prototype.render = function() {
        var holder, m, talk, u, _ref35;
        this.$el.removeClass('rd6').removeClass('_sd0').removeClass('card');
        this.$el.addClass('rd6').addClass('_sd0').addClass('card');
        this.$el.html(this.template(_.extend(this.model.toJSON(), {
          gW: gW
        })));
        if (this._expand) {
          holder = this.$el.find('.talks');
          holder.empty();
          _ref35 = this.model.get('talks');
          for (u in _ref35) {
            talk = _ref35[u];
            m = {
              shared: this.model.get('share'),
              mine: this.model.get('own'),
              talk_user_id: u,
              comments: talk,
              user: this.model.get('talk_user')
            };
            holder.append(this._attach(new TalkView({
              model: new Talk(m)
            })).el);
          }
        }
        if (this._on_expand_triggered) {
          this.$el.trigger('refreshWookmark');
        }
        return this._on_expand_triggered = false;
      };

      FeelingView.prototype._on_expand = function(event) {
        this._on_expand_triggered = true;
        this._expand = !this._expand;
        return this.model.fetch();
      };

      FeelingView.prototype.close = function() {
        FeelingView.__super__.close.call(this);
        return this.model.off('change', this.show);
      };

      return FeelingView;

    })(FsView);
    ReceivedFeelingsView = (function(_super) {
      __extends(ReceivedFeelingsView, _super);

      function ReceivedFeelingsView() {
        _ref35 = ReceivedFeelingsView.__super__.constructor.apply(this, arguments);
        return _ref35;
      }

      ReceivedFeelingsView.prototype.tagName = 'ul';

      ReceivedFeelingsView.prototype.id = 'received_feelings_holder';

      ReceivedFeelingsView.prototype.className = 'fs_tiles';

      ReceivedFeelingsView.prototype.initialize = function() {
        this._wookmark = new Wookmark(this.id);
        this.model.on('prepend', this._on_prepend, this);
        this.model.on('concat', this._on_concat, this);
        return $(window).on('scroll', this._on_scroll);
      };

      ReceivedFeelingsView.prototype.render = function() {
        var m, _i, _len, _ref36, _results;
        this.$el.append(this._attach(new ArrivedFeelingView).el);
        _ref36 = this.model.models;
        _results = [];
        for (_i = 0, _len = _ref36.length; _i < _len; _i++) {
          m = _ref36[_i];
          _results.push(this.$el.append(this._attach(new FeelingView({
            model: m
          })).el));
        }
        return _results;
      };

      ReceivedFeelingsView.prototype.on_rendered = function() {
        return this._wookmark.apply();
      };

      ReceivedFeelingsView.prototype._on_scroll = function() {
        if ($(window).scrollTop() + $(window).height() > $(document).height() - 100) {
          return router.models.received.fetch_more();
        }
      };

      ReceivedFeelingsView.prototype._on_concat = function(list) {
        var m, _i, _len;
        console.log('concat');
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          m = list[_i];
          this.$el.append(this._attach(new FeelingView({
            model: m
          })).el);
        }
        return this._wookmark.apply();
      };

      ReceivedFeelingsView.prototype._on_prepend = function(model) {
        this.model.models.unshift(model);
        this.$el.find('.arrived_feeling').after(this._attach(new FeelingView({
          model: model
        })).el);
        return this._wookmark.apply();
      };

      ReceivedFeelingsView.prototype.close = function() {
        ReceivedFeelingsView.__super__.close.call(this);
        this.model.off('concat', this._on_concat);
        this.model.off('prepend', this._on_prepend);
        return $(window).off('scroll', this._on_scroll);
      };

      return ReceivedFeelingsView;

    })(FsView);
    ArrivedFeelingView = (function(_super) {
      __extends(ArrivedFeelingView, _super);

      function ArrivedFeelingView() {
        _ref36 = ArrivedFeelingView.__super__.constructor.apply(this, arguments);
        return _ref36;
      }

      ArrivedFeelingView.prototype.tagName = 'li';

      ArrivedFeelingView.prototype.className = 'arrived_feeling';

      ArrivedFeelingView.prototype.events = {
        'click #receive_arrived': '_on_receive',
        'click #flipcard': '_on_flip'
      };

      ArrivedFeelingView.prototype.template = Tpl.arrived;

      ArrivedFeelingView.prototype.holder_template = Tpl.arrived_holder;

      ArrivedFeelingView.prototype.initialize = function() {
        this.model = new ArrivedFeelings;
        this.model.on('sync', this.show, this);
        return router.models.me.on('sync', this.show, this);
      };

      ArrivedFeelingView.prototype.render = function() {
        this.$el.removeClass('rd6').removeClass('_sd0').removeClass('card');
        if (this.model.length > 0) {
          this.$el.addClass('rd6').addClass('_sd0').addClass('card');
          this.$el.html(this.template(_.extend(this.model.at(0).toJSON(), {
            gW: gW
          })));
        } else {
          this.$el.addClass('rd6').addClass('card');
          this.$el.html(this.holder_template(router.models.me.toJSON()));
        }
        return this;
      };

      ArrivedFeelingView.prototype._on_receive = function(event) {
        return this.model.fetch();
      };

      ArrivedFeelingView.prototype._on_flip = function(event) {
        var model;
        model = this.model.at(0);
        return $.ajax({
          url: "../api/arrived_feelings/" + (model.get('id')),
          type: 'PUT',
          dataType: 'json',
          context: this,
          success: function(data) {
            this.model.reset();
            this.model.trigger('sync');
            return router.models.shared.trigger('prepend', new Feeling(data));
          }
        });
      };

      ArrivedFeelingView.prototype.close = function() {
        ArrivedFeelingView.__super__.close.call(this);
        this.model.off('sync', this.show);
        return router.models.me.off('sync', this.show);
      };

      return ArrivedFeelingView;

    })(FsView);
    SharedFeelingsView = (function(_super) {
      __extends(SharedFeelingsView, _super);

      function SharedFeelingsView() {
        _ref37 = SharedFeelingsView.__super__.constructor.apply(this, arguments);
        return _ref37;
      }

      SharedFeelingsView.prototype.tagName = 'ul';

      SharedFeelingsView.prototype.id = 'shared_feelings_holder';

      SharedFeelingsView.prototype.className = 'fs_tiles';

      SharedFeelingsView.prototype.initialize = function() {
        this._wookmark = new Wookmark(this.id);
        return this.model.on('prepend', this._on_prepend, this);
      };

      SharedFeelingsView.prototype.render = function() {
        var m, _i, _len, _ref38, _results;
        this.$el.append(this._attach(new ArrivedFeelingView).el);
        _ref38 = this.model.models;
        _results = [];
        for (_i = 0, _len = _ref38.length; _i < _len; _i++) {
          m = _ref38[_i];
          _results.push(this.$el.append(this._attach(new FeelingView({
            model: m
          })).el));
        }
        return _results;
      };

      SharedFeelingsView.prototype.on_rendered = function() {
        return this._wookmark.apply();
      };

      SharedFeelingsView.prototype._on_prepend = function(model) {
        this.model.models.unshift(model);
        this.$el.find('.arrived_feeling').after(this._attach(new FeelingView({
          model: model
        })).el);
        return this._wookmark.apply();
      };

      SharedFeelingsView.prototype.close = function() {
        SharedFeelingsView.__super__.close.call(this);
        return this.model.off('prepend', this._on_prepend);
      };

      return SharedFeelingsView;

    })(FsView);
    router = new Router;
    $.ajaxSetup({
      statusCode: {
        401: function() {
          return window.location = '/';
        },
        403: function() {
          return window.location = '/';
        }
      }
    });
    return Backbone.history.start();
  });

}).call(this);
