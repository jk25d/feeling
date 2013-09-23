$ ->
  gW = [
    { w: '멍해요', c: '#f0ba3c' },
    { w: '그냥그래', c: '#7f94b0' },
    { w: '짱좋아요', c: '#14b0d9' },
    { w: '잼나요', c: '#c6aae2' },
    { w: '신나요', c: '#aae04c' },
    { w: '설레요', c: '#e177b3' },
    { w: '행복해요', c: '#e8175d' },
    { w: '외로워요', c: '#29a9b3' },
    { w: '한심해요', c: '#938172' },
    { w: '우울해요', c: '#556270' },
    { w: '힘들어요', c: '#77cca4' },
    { w: '슬퍼요', c: '#d9cbb8' },
    { w: '무기력해요', c: '#758fe6' },
    { w: '초조해요', c: '#ffc6e2' },
    { w: '멘붕', c: '#f0ba3c' },
    { w: '짜증나요', c: '#c47147' }
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

  class Wookmark
    constructor: (@id) ->
    apply: ->
      @handler?.wookmarkInstance?.clear()
      @handler = $("##{@id} > li")
      @handler.wookmark
        align: 'left'
        autoResize: true
        container: $("##{@id}")
        offset: 20
        itemWidth: 260

  class Router extends Backbone.Router
    routes:
      '': 'index'
      'login': 'index'
      'logout': 'logout'
      'my_feelings': 'my_feelings'
      'shared_feelings': 'shared_feelings'
      'received_feelings': 'received_feelings'
    layout: {}
    models: {}
    initialize: ->
      @models.me = new Me
      @models.live_feelings = new LiveFeelings
      @models.associates = new Associates
      @models.my = new MyFeelings
      @models.received = new ReceivedFeelings
      @models.shared = new SharedFeelings
      @models.app = new App

      @layout.nav = new NavLayout
      @layout.header = new HeaderLayout
      @layout.status = new StatusLayout
      @layout.body = new BodyLayout

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
    shared_feelings: ->
      @scrollable_model = null
      @models.app.set {menu: '#menu_share'}
      @models.me.fetch
        success: (model, res) ->
          router.layout.status.show new MyStatusView(model: router.models.me)
      @models.shared.fetch()
      @models.live_feelings.fetch
        success: (model, res) ->
          router.layout.header.show new LiveFeelingsView(model: router.models.live_feelings)
      @layout.body.show new SharedFeelingsView(model: router.models.shared)
    my_feelings: ->
      @scrollable_model = @models.my
      @models.app.set {menu: '#menu_my'}
      @models.me.fetch
        success: (model, res) ->
          router.layout.status.show new MyStatusView(model: model)
      @models.my.fetch_more()
      @layout.header.show new NewFeelingView()
      @layout.body.show new MyFeelingsView(model: @models.my)
    received_feelings: ->
      @scrollable_model = @models.received
      @models.app.set {menu: '#menu_received'}
      @models.me.fetch
        success: (model, res) ->
          router.layout.status.show new MyStatusView(model: model)
      @models.received.fetch_more()
      @layout.header.show()
      @layout.body.show new ReceivedFeelingsView(model: @models.received)
      

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
      n_available_feelings: 0
      arrived_feelings: 0
      my_feelings: 0
      rcv_feelings: 0
      my_shared: 0
      rcv_shared: 0
    url: '../api/me'
  class LiveFeeling extends Backbone.Model
  class LiveFeelings extends Backbone.Collection
    model: LiveFeeling
    url: '../api/live_feelings'
    fetch: (options={}) ->
      options.data = {n:12}
      options.reset = true
      super options
  class Associate extends Backbone.Model
  class Associates extends Backbone.Collection
    url: '../api/associates'
    fetch: (options={}) ->
      options.reset = true
      super options

  class Comment extends Backbone.Model
  class Talk extends Backbone.Model
  class MyFeeling extends Backbone.Model
  class MyFeelings extends Backbone.Collection
    model: MyFeeling
    url: '../api/feelings'
    fetch_more: ->
      new MyFeelings().fetch
        data:
          type: 'my'
          from: if @models.length == 0 then 0 else @models[0].id
          skip: @models?.length || 0
          n: 10
        success: (model, res) ->
          my = router.models.my
          old_len = my.length
          my.add m for m in model.models
          if my.length > old_len
            my.trigger 'concat', my.models.slice(old_len, my.length)
        complete:
          active_scroll = false

  class ReceivedFeeling extends Backbone.Model
  class ReceivedFeelings extends Backbone.Collection
    model: ReceivedFeeling
    url: '../api/feelings'
    fetch_more: ->
      new ReceivedFeelings().fetch
        data:
          type: 'rcv'
          from: if @models.length == 0 then 0 else @models[0].id
          skip: @models?.length || 0
          n: 10
        success: (model, res) ->
          rcv = router.models.received
          old_len = rcv.length
          rcv.add m for m in model.models
          if rcv.length > old_len
            rcv.trigger 'concat', rcv.models.slice(old_len, rcv.length)
        complete:
          active_scroll = false

  class ArrivedFeeling extends Backbone.Model
  class ArrivedFeelings extends Backbone.Collection
    model: ArrivedFeeling
    url: '../api/arrived_feelings'

  class NewComment extends Backbone.Model      
  class Feeling extends Backbone.Model
    urlRoot: '../api/feelings'
  class SharedFeelings extends Backbone.Collection
    model: Feeling
    url: '../api/feelings'
    fetch: (options={}) ->
      options.reset = true
      options.data = {type: 'share'}
      options.success = (model) -> console.log model;router.models.shared.trigger 'refresh'
      super options


  #--- Layout ---#

  class Layout
    show: (view) ->  
      @current_view.close() if @current_view
      return $("##{@id}").empty() unless view
      @current_view = view
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
      @on_rendered()
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
    @feeling:      _.template $('#tpl_feeling').html()
    @arrived:      _.template $('#tpl_arrived_feeling').html()
    @arrived_holder: _.template $('#tpl_arrived_holder').html()

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
      $(@model.get('menu')).addClass 'active'
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

  class MyStatusView extends FsView
    template: Tpl.my_status
    initialize: ->
      @model.on 'sync', @show, @
    render: ->
      @$el.html @template(@model.toJSON())    
    close: ->
      super()
      @model.off 'sync', @show, @

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
    events:
      'click .fs_submit': '_on_submit'
      'click #wordselect .ww': '_on_select_word'
    template: Tpl.new_feeling
    render: ->
      @$el.html @template({gW: gW})
    _on_select_word: (e) ->
      @$el.find('#wordselect').find('.active').removeClass 'active'
      $(e.currentTarget).addClass 'active'
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
      'click .my_card': '_on_detail'
    template: Tpl.my_feeling
    initialize: ->
      @model.on 'sync', @show, @
    render: ->
      @$el.html @template _.extend(@model.toJSON(), gAddons)
    _on_detail: (event) ->
      @model.fetch
        error: -> router.refresh_page()
    close: ->
      super()
      @model.off 'sync', @show, @

  class FeelingView extends FsView
    tagName: 'li'
    events:
      'click .expand_area': '_on_expand'
    template: Tpl.feeling
    initialize: ->
      @model.on 'sync', @show, @
      @_expand = false
    render: ->
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      like_me = @model.get('like') == router.models.me?.id
      @$el.html @template _.extend(@model.toJSON(), gAddons, {like_me: like_me, expanded: @_expand})

      if @_expand
        if @model.get('n_talk_users') == 0
          @_expand = false
        else
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
    close: ->
      super()
      @model.off 'sync', @show, @

  class MyFeelingsView extends FsView
    tagName: 'ul'
    className: 'my_feelings_holder'
    initialize: ->
      @model.on 'concat', @_on_concat, @
    render: ->
      for m in @model.models
        @$el.append @_attach(new MyFeelingView(model: m)).el
    _on_concat: (list) ->
      for m in list
        @$el.append @_attach(new MyFeelingView(model: m)).el
    close: ->
      super()
      @model.off 'concat', @_on_concat, @
      @model.reset()

  class ReceivedFeelingsView extends FsView
    tagName: 'ul'
    id: 'received_feelings_holder'
    className: 'fs_tiles'
    initialize: ->
      @$el.addClass 'fs_container' unless @$el.hasClass 'fs_container'
      @_wookmark = new Wookmark(@id)
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

  class ArrivedFeelingView extends FsView
    tagName: 'li'
    className: 'arrived_feeling'
    events:
      #'click #receive_arrived': '_on_receive'
      'click #flipcard': '_on_flip'
    template: Tpl.arrived
    holder_template: Tpl.arrived_holder
    initialize: ->
      @model = new ArrivedFeelings
      @model.fetch()
      @model.on 'sync', @show, @
      router.models.me.on 'sync', @show, @
    render: ->
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      if @model.length > 0
        @$el.addClass('rd6').addClass('_sd0').addClass('card')
        @$el.html @template(_.extend(@model.at(0).toJSON(), {gW: gW}))
      else
        @$el.addClass('rd6').addClass('card')
        @$el.html @holder_template(router.models.me.toJSON())
      @
    _on_receive: (event) ->
      @model.fetch()
    _on_flip: (event) ->
      model = @model.at 0
      $.ajax
        url: "../api/arrived_feelings/#{model.get('id')}"
        type: 'PUT'
        context: @
        success: (data) ->
          router.models.shared.trigger 'prepend', new Feeling(data)
          router.models.me.fetch()
          @model.reset()
          @model.trigger 'sync'
        error: -> @model.fetch()
    close: ->
      super()
      @model.off 'sync', @show, @
      router.models.me.off 'sync', @show, @
    
  class SharedFeelingsView extends FsView
    tagName: 'ul'
    id: 'shared_feelings_holder'
    className: 'fs_tiles'
    initialize: ->
      @_wookmark = new Wookmark(@id)
      @$el.addClass 'fs_container' unless @$el.hasClass 'fs_container'

      # dont bind with sync
      # it makes this view refreshed when any child is fetched
      @model.on 'refresh', @show, @
      @model.on 'prepend', @_on_prepend, @
    render: ->
      @$el.append @_attach(new ArrivedFeelingView).el
      for m in @model.models
        @$el.append @_attach(new FeelingView(model: m)).el
    on_rendered: ->
      @_wookmark.apply()
    _on_prepend: (model) ->
      @model.unshift model
      @$el.find('.arrived_feeling').after @_attach(new FeelingView(model: model)).el
      @_wookmark.apply()
    close: ->
      super()
      @model.off 'refresh', @show, @
      @model.off 'prepend', @_on_prepend, @
      @model.reset()

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
