$ ->
  gW = [
    { w: '&#xe814', c: '#14b0d9' },
    { w: '&#xe811', c: '#f0ba3c' },
    { w: '&#xe809', c: '#aae04c' },
    { w: '&#xe80e', c: '#e177b3' },
    { w: '&#xe813', c: '#758fe6' },
    { w: '&#xe805', c: '#7f94b0' },
    { w: '&#xe80b', c: '#938172' },
    { w: '&#xe808', c: '#c6aae2' },
    { w: '&#xe80f', c: '#d9cbb8' },
    { w: '&#xe804', c: '#556270' },
    { w: '&#xe80d', c: '#79927d' },
    { w: '&#xe807', c: '#e8175d' }
  ]

  gAddons = 
    gW: gW
    datefmt: (time) ->
      ago = new Date().getTime() - time
      ago = if ago > 0 then ago else 0
      s = ago/1000
      m = s/60
      h = m/60
      d = h/24
      M = d/30
      return "#{Math.floor(M)}M" if M > 1
      return "#{Math.floor(d)}d" if d > 1
      return "#{Math.floor(h)}h" if h > 1
      return "#{Math.floor(m)}m" if m > 1
      "#{Math.floor(s)}s"
    datestr: (time) ->
      d = new Date(time)
      d.getDate()
    date2str: (time) ->
      d = new Date(time)
      m = "#{d.getMonth() + 1}"
      "#{if m.length > 1 then m else '0'+m}/#{d.getFullYear()}"
    timestr: (time) ->
      d = new Date(time)
      _h = d.getHours()
      postfix = if _h > 11 then "PM" else "AM"
      m = "#{d.getMinutes() + 1}"
      "#{_h%12}:#{if m.length > 1 then m else '0'+m} #{postfix}"

  class Wookmark
    constructor: () ->
    apply: ->
      @handler?.wookmarkInstance?.clear()
      @handler = $(".fs_tiles > li")
      @handler.wookmark
        align: 'center'
        autoResize: true
        container: $(".fs_tiles")
        offset: 20
        itemWidth: 260

  class Router extends Backbone.Router
    routes:
      '': 'index'
      'login': 'index'
      'logout': 'logout'
      'new_feeling': 'new_feeling'
      'my_feelings': 'my_feelings'
      'shared_feelings': 'shared_feelings'
      'received_feelings': 'received_feelings'
      'users/:uid': 'users'
    layout: {}
    models: {}
    schedules: {}
    initialize: ->
      @models.me = new Me
      @models.live_feelings = new LiveFeelings
      @models.associates = new Associates
      @models.my = new MyFeelings
      @models.received = new ReceivedFeelings
      @models.shared = new SharedFeelings
      @models.app = new App
      @models.profile = new Profile

      @layout.nav = new NavLayout
      @layout.header = new HeaderLayout
      @layout.status = new StatusLayout
      @layout.body = new BodyLayout
      @layout.popup = new PopupLayout

      @layout.nav.show new AppView(model: @models.app)

      _.bindAll @, '_login_view', 'index', 'logout', 'my_feelings', 'received_feelings'
    _login_view: ->
      @models.app.set {menu: '#menu_signup'}
      @layout.header.show new LoginView
      @layout.status.show()
      @layout.body.show()
    refresh_page: ->
      Backbone.history.loadUrl()
      #console.log window.location.hash
      #if window.location.hash.length > 0
      #  Backbone.history.fragment = null;
      #  Backbone.history.navigate(window.location.hash.substring(1), true); 
    index: ->
      $.ajax
        url: '../sessions'
        statusCode:
          401: ->
          403: ->
        context: @
        success: -> @navigate 'my_feelings', {trigger: true}
        error: -> @_login_view()
    logout: ->
      @scrollable_model = null
      $.ajax
        url: '../sessions'
        type: 'DELETE'
        success: (data) -> window.location = '/'
    new_feeling: ->
      @scrollable_model = null
      @models.app.set {menu: null}
      router.layout.status.show new MyStatusView(model: @models.me)
      @models.me.fetch()
      @layout.header.show new NewFeelingView()
      @layout.body.show()
      @layout.popup.show()
    shared_feelings: ->
      @scrollable_model = @models.shared
      @models.app.set {menu: '#menu_share'}
      router.layout.status.show new MyStatusView(model: @models.me)
      @models.me.fetch()
      @models.shared.reset()
      @models.shared.fetch_more()
      @layout.header.show()
      @layout.body.show new SharedFeelingsView(model: @models.shared)
      @layout.popup.show new ProfileView(model: @models.profile)
    my_feelings: ->
      @scrollable_model = @models.my
      @models.app.set {menu: '#menu_my'}
      router.layout.status.show new MyStatusView(model: @models.me)
      @models.me.fetch()
      @models.my.reset()
      @models.my.fetch_more()
      @layout.header.show()
      @layout.body.show new MyFeelingsView(model: @models.my)
      @layout.popup.show new ProfileView(model: @models.profile)
    received_feelings: ->
      @scrollable_model = @models.received
      @models.app.set {menu: '#menu_received'}
      router.layout.status.show new MyStatusView(model: @models.me)
      @models.received.reset()
      @models.received.fetch_more()
      @layout.header.show()
      @layout.body.show new FeelingsView(model: @models.received)
      @layout.popup.show new ProfileView(model: @models.profile)
    users: (uid) ->
      @scrollable_model = null
      @models.app.set {menu: '#menu_received'}
      router.layout.status.show new MyStatusView(model: @models.me)
      @models.received.reset()
      @models.received.uid = uid
      @models.received.fetch_more()
      @layout.header.show()
      @layout.body.show new UserFeelingsView(model: @models.received)
      @layout.popup.show new ProfileView(model: @models.profile)
      

  #--- MODELS ---#

  class App extends Backbone.Model
    defaults:
      menu: '#menu_signup'
  class Me extends Backbone.Model
    defaults:
      id: -1
      name: ''
      email: ''
      img: ''
      n_hearts: 0
      n_active_feelings: 0
      has_available_feeling: false
      n_my_feelings: 0
      n_rcv_feelings: 0
      my_shared: 0
      rcv_shared: 0
    url: '../api/me'
  class LiveFeeling extends Backbone.Model
  class LiveFeelings extends Backbone.Collection
    model: LiveFeeling
    url: '../api/live_feelings'
    fetch: (options={}) ->
      options.data = {n:6}
      options.reset = true
      super options
  class Associate extends Backbone.Model
  class Associates extends Backbone.Collection
    url: '../api/associates'
    fetch: (options={}) ->
      options.reset = true
      super options

  class Profile extends Backbone.Model
    url: '../api/users/:id'

  class Comment extends Backbone.Model
  class Talk extends Backbone.Model
  class Feeling extends Backbone.Model
    urlRoot: '../api/feelings'
  class MyFeelings extends Backbone.Collection
    model: Feeling
    url: '../api/feelings'
    reset: ->
      super()
      @word = null
    fetch_more: ->
      new MyFeelings().fetch
        data:
          type: 'my'
          from: if @models.length == 0 then 0 else @models[0].id
          skip: @models?.length || 0
          n: 10
          word: @models.word
        success: (model, res) ->
          my = router.models.my
          old_len = my.length
          my.add m for m in model.models
          if my.length > old_len
            my.trigger 'concat', my.models.slice(old_len, my.length)
        complete:
          active_scroll = false

  class ReceivedFeelings extends Backbone.Collection
    model: Feeling
    url: '../api/feelings'
    reset: ->
      super()
      @uid = null
    fetch_more: ->
      new ReceivedFeelings().fetch
        data:
          type: 'rcv'
          from: if @models.length == 0 then 0 else @models[0].id
          skip: @models?.length || 0
          n: 10
          uid: @models.uid
        success: (model, res) ->
          rcv = router.models.received
          old_len = rcv.length
          rcv.add m for m in model.models
          if rcv.length > old_len
            rcv.trigger 'concat', rcv.models.slice(old_len, rcv.length)
        complete:
          active_scroll = false

  class NewArrivedFeeling extends Backbone.Model
    url: '../api/feelings/has_new'

  class ArrivedFeeling extends Backbone.Model
    url: '../api/feelings/new'

  class NewComment extends Backbone.Model      
  class SharedFeelings extends Backbone.Collection
    model: Feeling
    url: '../api/feelings'
    fetch_more: ->
      new SharedFeelings().fetch
        data:
          type: 'shared'
          from: if @models.length == 0 then 0 else @models[0].id
          skip: @models?.length || 0
          n: 10
        success: (model, res) ->
          shared = router.models.shared
          old_len = shared.length
          shared.add m for m in model.models
          if shared.length > old_len
            shared.trigger 'concat', shared.models.slice(old_len, shared.length)
        complete:
          active_scroll = false

  class MenuCard extends Backbone.Model
    defaults:
      menu: 'timeline'
  class Timeline extends Backbone.Model
  class Buddies extends Backbone.Model
  class Favorites extends Backbone.Model

  #--- Layout ---#

  class Layout
    show: (view) ->  
      @current_view.close() if @current_view
      @current_view = view
      return $("##{@id}").empty() unless view
      @current_view.show()
      $("##{@id}").html @current_view.el
      @current_view.on_rendered()

  class NavLayout extends Layout
    id: 'fs_navbar'

  class HeaderLayout extends Layout
    id: 'fs_header'

  class StatusLayout extends Layout
    id: 'fs_status'

  class BodyLayout extends Layout
    id: 'fs_body'

  class PopupLayout extends Layout
    id: 'fs_popup'

  #--- VIEWS ---#

  # dont call render directly
  class FsView extends Backbone.View
    _attach: (view) ->
      @_views.push view
      view.show()
      view
    _detach_all: ->
      @_views ||= []
      while @_views.length > 0
        @_views.pop().close()
    show: ->
      console.log "#{@constructor.name}.show"
      @_detach_all()
      @$el.empty()
      @render()
      @_rendered = true
      @on_rendered()
      @
    on_rendered: ->
    close: ->
      @_detach_all()
      @remove()
      @off()

  class Tpl
    @navbar:       _.template $('#tpl_navbar').html()
    @login:        _.template $('#tpl_login').html()
    @signup:       _.template $('#tpl_signup').html()
    @my_status:    _.template $('#tpl_my_status').html()
    @live_feeling: _.template $('#tpl_live_feeling').html()
    @live_feelings: _.template $('#tpl_live_feelings').html()
    @new_feeling:  _.template $('#tpl_new_feeling').html()
    @talk:         _.template $('#tpl_talk').html()
    @my_feeling:   _.template $('#tpl_my_feeling').html()
    @my_feelings:   _.template $('#tpl_my_feelings').html()
    @feeling:      _.template $('#tpl_feeling').html()
    @new_arrived:  _.template $('#tpl_new_arrived').html()
    @arrived_holder: _.template $('#tpl_arrived_holder').html()
    @arrived_feeling: _.template $('#tpl_arrived_feeling').html()
    @menucard:     _.template $('#tpl_menucard').html()
    @timeline:     _.template $('#tpl_timeline').html()
    @favorites:    _.template $('#tpl_favorites').html()
    @buddies:      _.template $('#tpl_buddies').html()
    @profile:      _.template $('#tpl_profile').html()
    @profile_card: _.template $('#tpl_profile_card').html()
    @feeling_cate: _.template $('#tpl_feeling_cate').html()

  class AppView extends FsView
    events:
      'click .fs_nav_dropdown': '_on_toggle_dropdown'
      'click .fs_menu': '_on_click_menu'
    template: Tpl.navbar
    initialize: ->
      @model.on 'change:menu', @show, @
    render: ->
      @$el.css 'overflow', 'visible'
      @$el.html @template(@model.toJSON())
      @$el.find('.fs_menu').removeClass 'active'
      m = @model.get('menu')
      $(m).addClass 'active' if m
    _on_toggle_dropdown: ->
      @$el.find('.fs_menu').toggleClass 'fs_menu_pop'
    _on_click_menu: (e) ->
      event_hash = $(e.currentTarget).parent().attr('href')
      current_hash = window.location.hash
      if event_hash && current_hash && event_hash.charAt(0) == '#' && event_hash == current_hash
        e.preventDefault()
        router.refresh_page()
    close: ->
      super()
      @model.off 'change:menu', @show, @

  class LoginView extends FsView
    events:
      'click #login_btn': '_on_login'
      'click .fs_cancel': '_on_flip'
      'click #signup_btn': '_on_signup'
    login_template: Tpl.login
    signup_template: Tpl.signup
    initialize: -> @_signup_mode = false
    render: ->
      @$el.html if @_signup_mode then @signup_template else @login_template()
    _on_flip: ->
      @_signup_mode = not @_signup_mode
      @show()
    _on_signup: ->
      $.ajax
        url: '../users'
        type: 'POST'
        context: @
        data:
          name: $('#signup_name').val()
          email: $('#signup_email').val()
          password: $('#signup_password').val()
          password_confirm: $('#signup_password_confirm').val()
        success: (data) ->
          window.location = '/'
        fail: ->
          window.location = '/'
    _on_login: ->
      $.ajax
        url: '../sessions'
        type: 'POST'
        context: @
        data:
          email: $('#email').val()
          password: $('#password').val()
        success: (data) ->
          router.models.app.set {'logged_in': true}
          router.navigate 'my_feelings', {trigger: true}
        fail: ->
          window.location = '/'

  class SignupView extends FsView
    events:
      'click .fs_submit': '_on_submit'
    template: Tpl.signup
    render: ->
      @$el.html @template()
    _on_submit: ->
      console.log 'signup submit'

  class ProfileView extends FsView
    events:
      'click .close_btn': '_on_close'
    template: Tpl.profile
    initialize: ->
      @model.on 'change', @show, @
    render: ->
      @$el.html @template @model.toJSON()
    _on_close: ->
      router.models.profile.clear()
    close: ->
      super()
      @model.off 'change', @show, @
      @model.clear()

  class FeelingCateView extends FsView
    tagName: 'ul'
    id: 'feeling_cate'
    template: Tpl.feeling_cate
    events:
      'click .feeling': '_on_feeling'
    render: ->
      @$el.html @template {gW: gW}
    _on_feeling: (e) ->
      wid = $(e.currentTarget).attr('word-id')
      if wid == 'all'
        router.refresh_page()
        return
      router.models.my.reset()
      router.models.my.word = wid
      router.models.my.fetch_more()
      router.scrollable_model = router.models.my
      router.layout.body.show new FeelingsView(model: router.models.my)

  class MyStatusView extends FsView
    template: Tpl.my_status
    initialize: ->
      @model.on 'change', @show, @    
    render: ->
      #router.schedules.me = true
      @$el.html @template(@model.toJSON())    
    close: ->
      super()
      #router.schedules.me = false
      @model.off 'change', @show, @

  class LiveFeelingView extends FsView
    tagName: 'li'
    template: Tpl.live_feeling
    render: ->
      @$el.html @template(_.extend(@model.toJSON(), {gW: gW}))

  class LiveFeelingsView extends FsView
    template: Tpl.live_feelings
    live_template: Tpl.live_feeling
    render: ->
      @$el.html @template()
      ul = @$el.find('#live_feelings')
      for m in @model.models
        ul.append @live_template(_.extend(m.toJSON(), {gW:gW}))

  class NewFeelingView extends FsView
    id: 'new_feeling_holder'
    events:
      'click .fs_submit': '_on_submit'
      'click .fs_cancel': '_on_cancel'
      'click #wordselect .feeling': '_on_select_word'
    template: Tpl.new_feeling
    render: ->
      @$el.html @template({gW: gW})
    _on_select_word: (e) ->
      @$el.find('#wordselect').find('.active').removeClass 'active'
      $(e.currentTarget).addClass 'active'
    _on_cancel: ->
      router.navigate 'my_feelings', {trigger: true}
    _on_submit: ->
      $.ajax
        url: '../api/feelings'
        type: 'POST'
        context: @
        data:
          word: @$el.find('#wordselect').find('.active').attr('word-id')
          blah: @$el.find('#new_feeling_content').val()
          is_public: true
        success: (data) ->
          Backbone.history.fragment = null
          router.navigate 'my_feelings', {trigger: true}

  class TalkView extends FsView
    events:
      'click .talk_submit': '_on_submit'
      'click .likeit': '_on_like'
    template: Tpl.talk
    render: ->
      @$el.html @template(_.extend(@model.toJSON(), gAddons))
    _on_submit: ->
      id = @options.parent.get 'id'
      uid = @model.get 'talk_user_id'
      $.ajax
        url: "../api/feelings/#{id}/talks/#{uid}/comments"
        type: 'POST'
        context: @
        data:
          blah: @$el.find('.talk_blah').val()
        success: (data) ->
          @options.parent.fetch()
    _on_like: ->
      id = @options.parent.get 'id'
      uid = @model.get 'talk_user_id'
      $.ajax
        url: "../api/feelings/#{id}/like"
        type: 'PUT'
        context: @
        data:
          user_id: uid
        success: (data) ->
          @options.parent.fetch()

  class MyFeelingView extends FsView
    tagName: 'li'
    className: 'my_card'
    events:
      'click .my_feeling_summary': '_on_toggle'
    template: Tpl.my_feeling
    initialize: -> @expand = false
    render: ->
      @$el.html @template _.extend(@model.toJSON(), gAddons)
    _on_toggle: (e) ->
      @expand = not @expand
      card_detail = @$el.find('.card_detail')
      if @expand
        card_detail.show()
        card_detail.html @_attach(new FeelingView({model: @model, expand:true})).el
        @model.fetch()
      else
        card_detail.hide()
        @_detach_all()
    close: ->
      super()

  class FeelingView extends FsView
    tagName: 'li'
    events:
      'click .expand_area': '_on_expand'
      'click .card_header': '_on_profile'
    template: Tpl.feeling
    initialize: ->
      @model.on 'sync', @show, @
      @_expand = @options.expand || false
    render: ->
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      like_me = @model.get('like') == router.models.me?.id
      @$el.html @template _.extend(@model.toJSON(), gAddons, {like_me: like_me, expanded: @_expand})

      if @_expand #&& @model.get('n_talk_users') > 0
        holder = @$el.find('.comments_holder')
        holder.empty()
        feeling_user_id = @model.get('user_id')
        for u,talk of @model.get('talks')
          talk_model =
            parent: @model
            model: new Talk
              shared: @model.get('share')
              my_id: if @model.get('own') then feeling_user_id else u
              feeling_user_id: feeling_user_id
              talk_user_id: u
              comments: talk
              users: @model.get('users')
              like: @model.get('like')
              word: @model.get('word')
          holder.append @_attach(new TalkView(talk_model)).el
      @$el.trigger 'refreshWookmark'
    _on_expand: (event) ->
      @_expand = not @_expand
      @model.fetch
        error: -> router.refresh_page()
    _on_profile: (e) ->
      console.log 'on profile'
      router.models.profile.set 'id', 'u1'
    close: ->
      super()
      @model.off 'sync', @show, @

  class MenuCardView extends FsView
    tagName: 'li'
    tpl: Tpl.menucard
    timeline_tpl: Tpl.timeline
    favorites_tpl: Tpl.favorites
    buddies_tpl: Tpl.buddies
    events:
      'click .timeline': '_on_timeline'
      'click .favorites': '_on_favorites'
      'click .buddies': '_on_buddies'
    initialize: ->
      @model.on 'change:menu', @show, @
    render: ->
      @$el.attr 'class', 'rd6 _sd0 card'
      @$el.html @tpl()
      holder = @$el.find('.holder')
      @_activate_menu()
      switch @model.get 'menu'
        when 'favorites'
          holder.html @favorites_tpl()
        when 'buddies'
          holder.html @buddies_tpl()
        else holder.html @timeline_tpl()
      @$el.trigger 'refreshWookmark'
    _activate_menu: ->
      @$el.find('.menu').removeClass 'active'
      @$el.find(".#{@model.get 'menu'}").addClass 'active'
    _on_timeline: -> @model.set 'menu', 'timeline'
    _on_favorites: -> @model.set 'menu', 'favorites'
    _on_buddies: -> @model.set 'menu', 'buddies'
    close: ->
      super()
      @model.off 'change:menu', @show, @

  class ArrivedFeelingView extends FsView
    tagName: 'li'
    id: 'arrived_feeling'
    events:
      'click #new_card_holder': 'on_receive'
      'click #flipcard': 'on_flip'
    template: _.template $('#tpl_arrived_feeling').html()
    holder_template: _.template $('#tpl_arrived_holder').html()
    initialize: ->
      @model.on 'change', @show, @
    render: ->
      if @model.isNew()
        @$el.attr 'class', 'rd6 card'
        @$el.html @holder_template()
      else
        @$el.attr 'class', 'rd6 _sd0 card'
        @$el.html @template _.extend(@model.toJSON(), {gW: gW})
      @
    on_receive: (event) ->
      @model.fetch()
    on_flip: (event) ->
      router.models.shared.trigger 'prepend', new Feeling(@model.toJSON())
      @model.clear()
    close: ->
      super()
      @model.off 'change', @show, @

  class MyFeelingsView extends FsView
    template: Tpl.my_feelings
    initialize: ->
      @model.on 'concat', @_on_concat, @
    render: ->
      @$el.html @template()
      holder = @$el.find('.my_feelings_holder')
      holder.empty() if @model.length > 0
      for m in @model.models
        holder.append @_attach(new MyFeelingView(model: m)).el
    _on_concat: (list) ->
      holder = @$el.find('.my_feelings_holder')
      for m in list
        holder.append @_attach(new MyFeelingView(model: m)).el
    close: ->
      super()
      @model.off 'concat', @_on_concat, @
      @model.reset()
    
  class NewArrivedFeelingView extends FsView
    tagName: 'li'
    events:
      'click #flipcard': '_on_flip'
    template: Tpl.new_arrived
    render: ->
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template()
      @
    on_rendered: ->
      #@$el.trigger 'refreshWookmark'
    _on_flip: (event) ->
      $.ajax
        url: "../api/feelings/new"
        type: 'GET'
        context: @
        success: (data) ->
          router.models.shared.trigger 'prepend', new Feeling(data)
          router.models.me.fetch()
        error: -> @model.fetch()
    close: ->
      super()

  class FeelingsView extends FsView
    tagName: 'ul'
    className: 'fs_tiles'
    initialize: ->
      @_wookmark = new Wookmark()
      @model.on 'concat', @_on_concat, @
    render: ->
      for m in @model.models
        @$el.append @_attach(new FeelingView(model: m)).el
    on_rendered: ->
      @_wookmark.apply()
    _on_concat: (list) ->
      for m in list
        @$el.append @_attach(new FeelingView(model: m)).el
      @_wookmark.apply()
    close: ->
      super()
      @model.off 'concat', @_on_concat, @
      @model.reset()

  class ProfileCardView extends FsView
    tagName: 'li'
    template: Tpl.profile_card
    initialize: ->
      @$el.attr 'class', 'rd6 _sd0 card'
      @model.on 'change', @show, @
    render: ->
      @$el.html @template @model.toJSON()
    close: ->
      super()
      @model.off 'change', @show, @

  class UserFeelingsView extends FsView
    tagName: 'ul'
    className: 'fs_tiles'
    initialize: ->
      @_wookmark = new Wookmark()
      @model.on 'concat', @_on_concat, @
    render: ->
      @$el.append @_attach(new ProfileCardView(model: new Profile)).el
      for m in @model.models
        @$el.append @_attach(new FeelingView(model: m)).el
    on_rendered: ->
      @_wookmark.apply()
    _on_concat: (list) ->
      for m in list
        @$el.append @_attach(new FeelingView(model: m)).el
      @_wookmark.apply()
    close: ->
      super()
      @model.off 'concat', @_on_concat, @
      @model.reset()

  class SharedFeelingsView extends FsView
    tagName: 'ul'
    id: 'shared_feelings_holder'
    className: 'fs_tiles'
    initialize: ->
      @_wookmark = new Wookmark()

      # dont bind with sync
      # it makes this view refreshed when any child is fetched
      @model.on 'concat', @_on_concat, @
      @model.on 'prepend', @_on_prepend, @
    render: ->
      @$el.append @_attach(new MenuCardView(model: new MenuCard)).el
      @$el.append @_attach(new ArrivedFeelingView(model: new ArrivedFeeling)).el
      for m in @model.models
        @$el.append @_attach(new FeelingView(model: m)).el
    on_rendered: ->
      @_wookmark.apply()
    _on_prepend: (model) ->
      @model.unshift model
      arrived_card = @$el.find('#arrived_feeling')
      arrived_card.after @_attach(new FeelingView(model: model)).el
      @_wookmark.apply()
    _on_concat: (list) ->
      for m in list
        @$el.append @_attach(new FeelingView(model: m)).el
      @_wookmark.apply()
    close: ->
      super()
      @model.off 'concat', @_on_concat, @
      @model.off 'prepend', @_on_prepend, @
      @model.reset()

  schedule = ->
    console.log ('schedule...')
    if router.schedules.me
      router.models.me.fetch()
    setTimeout schedule, 10000

  bind_scroll_event = ->
    if not active_scroll && router.scrollable_model && $(window).scrollTop() + $(window).height() >  $(document).height() - 100
      console.log 'on_scroll'
      router.scrollable_model.fetch_more()
      active_scroll = true

  router = new Router
  active_scroll = false
  $(window).on 'scroll', _.throttle(bind_scroll_event, 500, {trailing: false})
  $.ajaxSetup
    dataType: 'json'
    cache: false
    statusCode:
      401: -> window.location = '/'
      403: -> window.location = '/'
  Backbone.history.start()
  schedule()