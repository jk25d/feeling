// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var App, AppView, ArrivedFeeling, ArrivedFeelingView, ArrivedFeelings, Associate, Associates, Comment, CommentView, FsView, LiveFeelings, LoginView, Me, MyFeeling, MyFeelingView, MyFeelings, MyFeelingsView, NewComment, NewCommentView, NewFeelingView, ReceivedFeeling, ReceivedFeelingView, ReceivedFeelings, ReceivedFeelingsView, Router, SignupView, Wookmark, router, wookmark, _ref, _ref1, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref20, _ref21, _ref22, _ref23, _ref24, _ref25, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
    Wookmark = (function() {
      function Wookmark() {}

      Wookmark.prototype.apply = function(id) {
        var _ref, _ref1;
        if ((_ref = this.handler) != null) {
          if ((_ref1 = _ref.wookmarkInstance) != null) {
            _ref1.clear();
          }
        }
        this.handler = $("#" + id + ">ul>li");
        return this.handler.wookmark({
          align: 'left',
          autoResize: true,
          container: $("#" + id + ">ul"),
          offset: 16,
          itemWidth: 226
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
        'signup': 'signup',
        'my_feelings': 'my_feelings',
        'received_feelings': 'received_feelings'
      };

      Router.prototype.views = {};

      Router.prototype.active_views = [];

      Router.prototype.models = {};

      Router.prototype.initialize = function() {
        this.models.me = new Me;
        this.models.live_feelings = new LiveFeelings;
        this.models.associates = new Associates;
        this.models.my = new MyFeelings;
        this.models.received = new ReceivedFeelings;
        this.models.app = new App;
        this.views.login = new LoginView;
        this.views.signup = new SignupView;
        this.views.new_feeling = new NewFeelingView({
          me: this.models.me,
          live_feelings: this.models.live_feelings,
          associates: this.models.associates
        });
        this.views.my_feelings = new MyFeelingsView({
          model: this.models.my
        });
        this.views.received_feelings = new ReceivedFeelingsView({
          model: this.models.received
        });
        this.app_view = new AppView({
          model: this.models.app
        });
        this.app_view.render();
        return _.bindAll(this, 'unrender', 'index', 'logout', 'signup', 'draw_login', 'my_feelings', 'received_feelings');
      };

      Router.prototype.unrender = function() {
        var _results;
        _results = [];
        while (this.active_views.length > 0) {
          _results.push(this.active_views.pop().unrender());
        }
        return _results;
      };

      Router.prototype.index = function() {
        console.log('#');
        if (this.models.app.get('user')) {
          return this.navigate('received_feelings', {
            trigger: true
          });
        } else {
          return this.draw_login();
        }
      };

      Router.prototype.draw_login = function() {
        this.unrender();
        this.models.app.set({
          user: null,
          menu: '#menu_login'
        });
        this.views.login.render();
        return this.active_views.push(this.views.login);
      };

      Router.prototype.logout = function() {
        return $.ajax({
          url: '../sessions',
          type: 'DELETE',
          dataType: 'json',
          success: function(data) {
            return this.draw_login();
          }
        });
      };

      Router.prototype.signup = function() {
        this.unrender();
        this.views.signup.render();
        this.active_views.push(this.views.signup);
        return this.models.app.set({
          menu: '#menu_signup'
        });
      };

      Router.prototype.my_feelings = function() {
        this.unrender();
        this.views.new_feeling.render();
        this.views.my_feelings.render();
        this.active_views.push(this.views.new_feeling);
        this.active_views.push(this.views.my_feelings);
        this.models.app.fetch();
        this.models.app.set({
          menu: '#menu_my'
        });
        this.models.me.fetch();
        this.models.live_feelings.fetch();
        this.models.associates.fetch();
        return this.models.my.fetch();
      };

      Router.prototype.received_feelings = function() {
        console.log('#received_feelings');
        this.unrender();
        this.views.new_feeling.render();
        this.views.received_feelings.render();
        this.active_views.push(this.views.new_feeling);
        this.active_views.push(this.views.received_feelings);
        this.models.app.fetch();
        this.models.app.set({
          menu: '#menu_received'
        });
        this.models.me.fetch();
        this.models.live_feelings.fetch();
        this.models.associates.fetch();
        return this.models.received.fetch();
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
        user: null,
        menu: '#menu_login'
      };

      App.prototype.url = '../sessions';

      return App;

    })(Backbone.Model);
    Me = (function(_super) {
      __extends(Me, _super);

      function Me() {
        _ref2 = Me.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      Me.prototype.defaults = {
        n_available_feelings: 0
      };

      Me.prototype.url = '../api/me';

      return Me;

    })(Backbone.Model);
    LiveFeelings = (function(_super) {
      __extends(LiveFeelings, _super);

      function LiveFeelings() {
        _ref3 = LiveFeelings.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      LiveFeelings.prototype.url = '../api/live_feelings';

      return LiveFeelings;

    })(Backbone.Model);
    Associate = (function(_super) {
      __extends(Associate, _super);

      function Associate() {
        _ref4 = Associate.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      return Associate;

    })(Backbone.Model);
    Associates = (function(_super) {
      __extends(Associates, _super);

      function Associates() {
        _ref5 = Associates.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      Associates.prototype.url = '../api/associates';

      return Associates;

    })(Backbone.Collection);
    Comment = (function(_super) {
      __extends(Comment, _super);

      function Comment() {
        _ref6 = Comment.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      return Comment;

    })(Backbone.Model);
    MyFeeling = (function(_super) {
      __extends(MyFeeling, _super);

      function MyFeeling() {
        _ref7 = MyFeeling.__super__.constructor.apply(this, arguments);
        return _ref7;
      }

      return MyFeeling;

    })(Backbone.Model);
    MyFeelings = (function(_super) {
      __extends(MyFeelings, _super);

      function MyFeelings() {
        _ref8 = MyFeelings.__super__.constructor.apply(this, arguments);
        return _ref8;
      }

      MyFeelings.prototype.model = MyFeeling;

      MyFeelings.prototype.url = '../api/my_feelings';

      MyFeelings.prototype.fetch = function() {
        var _ref9;
        return {
          data: {
            skip: ((_ref9 = this.models) != null ? _ref9.length : void 0) || 0,
            n: 10
          },
          success: function(model, res) {
            return this.trigger('concat', model.models);
          }
        };
      };

      return MyFeelings;

    })(Backbone.Collection);
    ArrivedFeeling = (function(_super) {
      __extends(ArrivedFeeling, _super);

      function ArrivedFeeling() {
        _ref9 = ArrivedFeeling.__super__.constructor.apply(this, arguments);
        return _ref9;
      }

      return ArrivedFeeling;

    })(Backbone.Model);
    ArrivedFeelings = (function(_super) {
      __extends(ArrivedFeelings, _super);

      function ArrivedFeelings() {
        _ref10 = ArrivedFeelings.__super__.constructor.apply(this, arguments);
        return _ref10;
      }

      ArrivedFeelings.prototype.model = ArrivedFeeling;

      ArrivedFeelings.prototype.url = '../api/new_arrived_feelings';

      return ArrivedFeelings;

    })(Backbone.Collection);
    NewComment = (function(_super) {
      __extends(NewComment, _super);

      function NewComment() {
        _ref11 = NewComment.__super__.constructor.apply(this, arguments);
        return _ref11;
      }

      return NewComment;

    })(Backbone.Model);
    ReceivedFeeling = (function(_super) {
      __extends(ReceivedFeeling, _super);

      function ReceivedFeeling() {
        _ref12 = ReceivedFeeling.__super__.constructor.apply(this, arguments);
        return _ref12;
      }

      return ReceivedFeeling;

    })(Backbone.Model);
    ReceivedFeelings = (function(_super) {
      __extends(ReceivedFeelings, _super);

      function ReceivedFeelings() {
        _ref13 = ReceivedFeelings.__super__.constructor.apply(this, arguments);
        return _ref13;
      }

      ReceivedFeelings.prototype.model = ReceivedFeeling;

      ReceivedFeelings.prototype.url = '../api/received_feelings';

      ReceivedFeelings.prototype.fetch = function() {
        var _ref14;
        return {
          data: {
            skip: ((_ref14 = this.models) != null ? _ref14.length : void 0) || 0,
            n: 10
          },
          success: function(model, res) {
            return this.trigger('concat', model.models);
          }
        };
      };

      return ReceivedFeelings;

    })(Backbone.Collection);
    FsView = (function(_super) {
      __extends(FsView, _super);

      function FsView() {
        _ref14 = FsView.__super__.constructor.apply(this, arguments);
        return _ref14;
      }

      FsView.prototype.views = [];

      FsView.prototype.unrender = function() {
        var _results;
        _results = [];
        while (this.views.length > 0) {
          _results.push(this.views.pop().unrender());
        }
        return _results;
      };

      return FsView;

    })(Backbone.View);
    AppView = (function(_super) {
      __extends(AppView, _super);

      function AppView() {
        _ref15 = AppView.__super__.constructor.apply(this, arguments);
        return _ref15;
      }

      AppView.prototype.template = _.template($('#tpl_navbar').html());

      AppView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      AppView.prototype.render = function() {
        this.$el.html(this.template(this.model.toJSON()));
        $('#fs_navbar').html(this.$el);
        $('#fs_navbar .fs_menu').removeClass('active');
        $(this.model.get('menu')).addClass('active');
        this.model.on('change', this.render, this);
        return this.model.on('sync', this.render, this);
      };

      AppView.prototype.unrender = function() {
        this.model.off('change');
        this.model.off('sync');
        return $('#fs_navbar').empty();
      };

      return AppView;

    })(FsView);
    LoginView = (function(_super) {
      __extends(LoginView, _super);

      function LoginView() {
        _ref16 = LoginView.__super__.constructor.apply(this, arguments);
        return _ref16;
      }

      LoginView.prototype.events = {
        'click #login_btn': 'on_submit'
      };

      LoginView.prototype.template = _.template($('#tpl_login').html());

      LoginView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      LoginView.prototype.render = function() {
        this.$el.html(this.template());
        return $('#fs_header').html(this.$el);
      };

      LoginView.prototype.on_submit = function() {
        console.log('login clicked');
        return $.ajax({
          url: '../sessions',
          type: 'POST',
          dataType: 'json',
          data: {
            user_id: $('#user_id').val(),
            password: $('#password').val()
          },
          success: function(data) {
            router.models.app.set('user', data.user);
            return router.navigate('received_feelings', {
              trigger: true
            });
          }
        });
      };

      LoginView.prototype.unrender = function() {
        return $('#fs_header').empty();
      };

      return LoginView;

    })(Backbone.View);
    SignupView = (function(_super) {
      __extends(SignupView, _super);

      function SignupView() {
        _ref17 = SignupView.__super__.constructor.apply(this, arguments);
        return _ref17;
      }

      SignupView.prototype.events = {
        'click .fs_submit': 'on_submit'
      };

      SignupView.prototype.template = _.template($('#tpl_signup').html());

      SignupView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      SignupView.prototype.render = function() {
        this.$el.html(this.template());
        return $('#fs_header').html(this.$el);
      };

      SignupView.prototype.on_submit = function() {
        return console.log('signup submit');
      };

      SignupView.prototype.unrender = function() {
        return $('#fs_header').empty();
      };

      return SignupView;

    })(FsView);
    NewFeelingView = (function(_super) {
      __extends(NewFeelingView, _super);

      function NewFeelingView() {
        _ref18 = NewFeelingView.__super__.constructor.apply(this, arguments);
        return _ref18;
      }

      NewFeelingView.prototype.events = {
        'click .fs_submit': 'on_submit'
      };

      NewFeelingView.prototype.template = _.template($('#tpl_new_feeling').html());

      NewFeelingView.prototype.me_template = _.template($('#tpl_me').html());

      NewFeelingView.prototype.associates_template = _.template($('#tpl_associates').html());

      NewFeelingView.prototype.initialize = function() {
        this.me = this.options.me;
        this.live_feelings = this.options.live_feelings;
        this.associates = this.options.associates;
        return _.bindAll(this, 'unrender');
      };

      NewFeelingView.prototype.render = function() {
        this.$el.html(this.template());
        $('#fs_header').html(this.$el);
        this.me.on('change', this.render_me, this);
        this.me.on('sync', this.render_me, this);
        this.live_feelings.on('change', this.render_live_feelings, this);
        this.live_feelings.on('sync', this.render_live_feelings, this);
        this.associates.on('change', this.render_associates, this);
        return this.associates.on('sync', this.render_associates, this);
      };

      NewFeelingView.prototype.render_me = function() {
        console.log('render_me');
        return $('#fs_header_me').html(this.me_template(this.me.toJSON()));
      };

      NewFeelingView.prototype.render_live_feelings = function() {
        var el, n, word, _ref19, _results;
        console.log('render_live_feelings');
        console.log(this.live_feelings);
        el = $('#fs_header_live_feelings');
        el.empty();
        _ref19 = this.live_feelings.attributes;
        _results = [];
        for (word in _ref19) {
          n = _ref19[word];
          _results.push(el.append("<li>" + word + "</li>"));
        }
        return _results;
      };

      NewFeelingView.prototype.render_associates = function() {
        var el, m, _i, _len, _ref19, _results;
        el = $('#fs_header_associates');
        el.empty();
        _ref19 = this.associates.models;
        _results = [];
        for (_i = 0, _len = _ref19.length; _i < _len; _i++) {
          m = _ref19[_i];
          _results.push(el.append(this.associates_template(m.toJSON())));
        }
        return _results;
      };

      NewFeelingView.prototype.on_submit = function() {
        return $.ajax({
          url: '../api/my_feelings',
          type: 'POST',
          dataType: 'json',
          data: {
            word_id: $('#wordselect').find('.active').attr('word-id'),
            content: $('#new_feeling_content').val()
          },
          success: function(data) {
            return router.navigate('my_feelings', true);
          }
        });
      };

      NewFeelingView.prototype.unrender = function() {
        this.me.off('change');
        this.live_feelings.off('change');
        this.associates.off('change');
        this.me.off('sync');
        this.live_feelings.off('sync');
        this.associates.off('sync');
        return $('#fs_header').empty();
      };

      return NewFeelingView;

    })(FsView);
    CommentView = (function(_super) {
      __extends(CommentView, _super);

      function CommentView() {
        _ref19 = CommentView.__super__.constructor.apply(this, arguments);
        return _ref19;
      }

      CommentView.prototype.events = {
        'click .icon-remove': 'on_remove',
        'click .icon-heart': 'on_like'
      };

      CommentView.prototype.template = _.template($('#tpl_comment').html());

      CommentView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      CommentView.prototype.render = function() {
        this.$el.html(this.template(this.model.toJSON()));
        this.model.on('change', this.render, this);
        this.model.on('sync', this.render, this);
        return this;
      };

      CommentView.prototype.on_remove = function() {
        return alert('not implemented');
      };

      CommentView.prototype.on_like = function() {
        return alert('not implemented');
      };

      CommentView.prototype.unrender = function() {
        this.model.off('change');
        return this.model.off('sync');
      };

      return CommentView;

    })(FsView);
    MyFeelingView = (function(_super) {
      __extends(MyFeelingView, _super);

      function MyFeelingView() {
        _ref20 = MyFeelingView.__super__.constructor.apply(this, arguments);
        return _ref20;
      }

      MyFeelingView.prototype.tagName = 'li';

      MyFeelingView.prototype.events = {
        'click .card': 'on_expand'
      };

      MyFeelingView.prototype.template = _.template($('#tpl_my_feeling').html());

      MyFeelingView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      MyFeelingView.prototype.render = function() {
        var holder, m, view, _i, _len, _ref21;
        this.set_comments_count();
        this.$el.addClass('rd6').addClass('_sd0').addClass('card');
        this.$el.html(this.template(this.model.toJSON()));
        if (this.model.get('expand')) {
          holder = this.$el.find('.comments');
          holder.empty();
          _ref21 = this.model.get('comments');
          for (_i = 0, _len = _ref21.length; _i < _len; _i++) {
            m = _ref21[_i];
            view = new CommentView({
              model: new Comment(m)
            });
            this.views.push(view);
            holder.append(view.render().el);
          }
        }
        this.model.on('change', this.render, this);
        this.model.on('sync', this.render, this);
        return this;
      };

      MyFeelingView.prototype.set_comments_count = function() {
        var c, n_comments, n_hearts, _i, _len, _ref21;
        n_comments = n_hearts = 0;
        _ref21 = this.model.get('comments');
        for (_i = 0, _len = _ref21.length; _i < _len; _i++) {
          c = _ref21[_i];
          if (c.type === 'heart') {
            n_hearts++;
          }
          if (c.type === 'comment') {
            n_comments++;
          }
        }
        return this.model.set({
          n_comments: n_comments,
          n_hearts: n_hearts
        });
      };

      MyFeelingView.prototype.on_expand = function(event) {
        if (this.model.get('expand')) {
          return;
        }
        return this.model.set('expand', true);
      };

      MyFeelingView.prototype.unrender = function() {
        MyFeelingView.__super__.unrender.call(this);
        this.model.off('change');
        return this.model.off('sync');
      };

      return MyFeelingView;

    })(FsView);
    MyFeelingsView = (function(_super) {
      __extends(MyFeelingsView, _super);

      function MyFeelingsView() {
        _ref21 = MyFeelingsView.__super__.constructor.apply(this, arguments);
        return _ref21;
      }

      MyFeelingsView.prototype.id = 'my_feelings_holder';

      MyFeelingsView.prototype.events = {
        'click .fs_more': 'on_more'
      };

      MyFeelingsView.prototype.template = _.template($('#tpl_feelings').html());

      MyFeelingsView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      MyFeelingsView.prototype.render = function() {
        this.$el.html(this.template());
        $('#fs_body').html(this.$el);
        return this.model.on('concat', this.on_concat, this);
      };

      MyFeelingsView.prototype.on_concat = function(list) {
        var m, view, _i, _len;
        this.model.models.concat(list);
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          m = list[_i];
          view = new MyFeelingView({
            model: m
          });
          this.views.push(view);
          this.$el.append(view.render().el);
        }
        return wookmark.apply(this.id);
      };

      MyFeelingsView.prototype.on_more = function(event) {
        return this.model.fetch();
      };

      MyFeelingsView.prototype.unrender = function() {
        MyFeelingsView.__super__.unrender.call(this);
        this.model.off('concat');
        return $('#fs_body').empty();
      };

      return MyFeelingsView;

    })(FsView);
    NewCommentView = (function(_super) {
      __extends(NewCommentView, _super);

      function NewCommentView() {
        _ref22 = NewCommentView.__super__.constructor.apply(this, arguments);
        return _ref22;
      }

      NewCommentView.prototype.className = 'new_comment';

      NewCommentView.prototype.events = {
        'click .fs_submit': 'on_submit'
      };

      NewCommentView.prototype.template = _.template($('#tpl_new_comment').html());

      NewCommentView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      NewCommentView.prototype.render = function() {
        this.$el.html(this.template());
        this.model.on('change', this.render, this);
        this.model.on('sync', this.render, this);
        return this;
      };

      NewCommentView.prototype.on_submit = function(event) {
        return alert('not implemented');
      };

      NewCommentView.prototype.unrender = function() {
        NewCommentView.__super__.unrender.call(this);
        this.model.off('change');
        return this.model.off('sync');
      };

      return NewCommentView;

    })(FsView);
    ReceivedFeelingView = (function(_super) {
      __extends(ReceivedFeelingView, _super);

      function ReceivedFeelingView() {
        _ref23 = ReceivedFeelingView.__super__.constructor.apply(this, arguments);
        return _ref23;
      }

      ReceivedFeelingView.prototype.tagName = 'li';

      ReceivedFeelingView.prototype.events = {
        'click .icon-comment': 'on_comment',
        'click .icon-heart': 'on_like',
        'click .icon-share-alt': 'on_forward'
      };

      ReceivedFeelingView.prototype.template = _.template($('#tpl_received_feeling').html());

      ReceivedFeelingView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      ReceivedFeelingView.prototype.render = function() {
        var view;
        this.$el.addClass('rd6').addClass('_sd0').addClass('card');
        this.$el.html(this.template(this.model.toJSON()));
        if (this.model.type === 'comment') {
          $('.icon-comment').css('background-color', '#44f9b8');
        }
        if (this.model.type === 'like') {
          $('.icon-heart').css('background-color', '#44f9b8');
        }
        if (this.model.type === 'forward') {
          $('.icon-share-alt').css('background-color', '#44f9b8');
        }
        if (this.model.type) {
          view = new NewCommentView;
          this.views.push(view);
          this.$.find('.inputarea').html(view.render().el);
        }
        this.model.on('change', this.render, this);
        this.model.on('sync', this.render, this);
        return this;
      };

      ReceivedFeelingView.prototype.on_comment = function(event) {
        return this.model.set('type', 'comment');
      };

      ReceivedFeelingView.prototype.on_like = function(event) {
        return this.model.set('type', 'like');
      };

      ReceivedFeelingView.prototype.on_forward = function(event) {
        return this.model.set('type', 'forward');
      };

      ReceivedFeelingView.prototype.unrender = function() {
        ReceivedFeelingView.__super__.unrender.call(this);
        this.model.off('change');
        return this.model.off('sync');
      };

      return ReceivedFeelingView;

    })(FsView);
    ReceivedFeelingsView = (function(_super) {
      __extends(ReceivedFeelingsView, _super);

      function ReceivedFeelingsView() {
        _ref24 = ReceivedFeelingsView.__super__.constructor.apply(this, arguments);
        return _ref24;
      }

      ReceivedFeelingsView.prototype.id = 'received_feelings_holder';

      ReceivedFeelingsView.prototype.events = {
        'click .fs_more': 'on_more'
      };

      ReceivedFeelingsView.prototype.template = _.template($('#tpl_feelings').html());

      ReceivedFeelingsView.prototype.initialize = function() {
        return _.bindAll(this, 'unrender');
      };

      ReceivedFeelingsView.prototype.render = function() {
        var view;
        this.$el.html(this.template());
        view = new ArrivedFeelingView;
        this.views.push(view);
        this.$el.append(view.render().el);
        $('#fs_body').html(this.$el);
        this.model.on('prepend', this.on_prepend, this);
        return this.model.on('concat', this.on_concat, this);
      };

      ReceivedFeelingsView.prototype.on_concat = function(list) {
        var m, view, _i, _len;
        this.model.models.concat(list);
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          m = list[_i];
          view = new ReceivedFeelingView({
            model: m
          });
          this.views.push(view);
          this.$el.append(view.render().el);
        }
        return wookmark.apply(this.id);
      };

      ReceivedFeelingsView.prototype.on_prepend = function(data) {
        var model, view;
        model = new ReceivedFeeling(data);
        this.model.models.unshift(model);
        view = new ReceivedFeelingView({
          model: model
        });
        this.views.push(view);
        $('#arrived_feeling').after(view.render().el);
        return wookmark.apply(this.id);
      };

      ReceivedFeelingsView.prototype.on_more = function(event) {
        return this.model.fetch();
      };

      ReceivedFeelingsView.prototype.unrender = function() {
        ReceivedFeelingsView.__super__.unrender.call(this);
        this.model.off('concat');
        this.model.off('prepend');
        return $('#fs_body').empty();
      };

      return ReceivedFeelingsView;

    })(FsView);
    ArrivedFeelingView = (function(_super) {
      __extends(ArrivedFeelingView, _super);

      function ArrivedFeelingView() {
        _ref25 = ArrivedFeelingView.__super__.constructor.apply(this, arguments);
        return _ref25;
      }

      ArrivedFeelingView.prototype.tagName = 'li';

      ArrivedFeelingView.prototype.id = 'arrived_feeling';

      ArrivedFeelingView.prototype.events = {
        'click #receive_arrived': 'on_receive',
        'click #flipcard': 'on_flip'
      };

      ArrivedFeelingView.prototype.template = _.template($('#tpl_arrived_feeling').html());

      ArrivedFeelingView.prototype.holder_template = _.template($('#tpl_arrived_holder').html());

      ArrivedFeelingView.prototype.initialize = function() {
        this.model = new ArrivedFeelings;
        return _.bindAll(this, 'unrender');
      };

      ArrivedFeelingView.prototype.render = function() {
        if (this.model.length > 0) {
          this.$el.html(this.template(this.model.toJSON()));
        } else {
          this.$el.html(this.holder_template(router.models.me.toJSON()));
        }
        this.model.on('reset', this.render, this);
        router.models.me.on('change', this.render, this);
        router.models.me.on('sync', this.render, this);
        return this;
      };

      ArrivedFeelingView.prototype.on_receive = function(event) {
        return this.model.fetch();
      };

      ArrivedFeelingView.prototype.on_flip = function(event) {
        var model;
        model = this.model.at(0);
        return $.ajax({
          url: "../api/new_arrived_feelings/" + (model.get('id')),
          type: 'PUT',
          dataType: 'json',
          success: function(data) {
            this.model.reset();
            return router.models.received.trigger('prepend', data);
          }
        });
      };

      ArrivedFeelingView.prototype.unrender = function() {
        router.models.me.off('change');
        router.models.me.off('sync');
        return this.model.off('reset');
      };

      return ArrivedFeelingView;

    })(FsView);
    wookmark = new Wookmark;
    router = new Router;
    $.ajaxSetup({
      statusCode: {
        401: function() {
          return router.draw_login();
        },
        403: function() {
          return router.draw_login();
        }
      }
    });
    return Backbone.history.start();
  });

}).call(this);
