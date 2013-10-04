#### CODING RULES ####
# private variable, methods
#   start with _
#   don't use = when define it
#     it makes side effects: can't use class's this memeber
#
#  Router -->* Layout
#         -->* Model
#  Layout --> View  --> Model

$ ->
  gW = [
    { w: '두렵다', c: '#556270' },
    { w: '무섭다', c: '#556270' },
    { w: '우울하다', c: '#7f94b0' },
    { w: '기운이없다', c: '#938172' },
    { w: '무기력하다', c: '#938172' },
    { w: '의욕이없다', c: '#938172' },
    { w: '불안하다', c: '#77cca4' },
    { w: '외롭다', c: '#c3ff68' },
    { w: '걱정된다', c: '#14b0d9' },
    { w: '허전하다', c: '#14d925' },
    { w: '삶이힘들다', c: '#e177b3' },
    { w: '한심하다', c: '#ffc6e2' },
    { w: '짜증난다', c: '#c6aae2' },
    { w: '슬프다', c: '#77cca4' },
    { w: '절망스럽다', c: '#d9cbb8' },
    { w: '화난다', c: '#594944' },
    { w: '쓸쓸하다', c: '#758fe6' },
    { w: '초조하다', c: '#b5242e' },
    { w: '마음아프다', c: '#29a9b3' },
    { w: '열등감느낀다', c: '#e8175d' },
    { w: '사랑스럽다', c: '#14b0d9' },
    { w: '소중하다', c: '#c3ff68' },
    { w: '설레다', c: '#14d925' },
    { w: '즐겁다', c: '#e177b3' },
    { w: '기쁘다', c: '#ffc6e2' },
    { w: '뿌듯하다', c: '#c6aae2' },
    { w: '만족스럽다', c: '#77cca4' },
    { w: '가슴벅차다', c: '#d9cbb8' },
    { w: '자신있다', c: '#f0ba3c' },
    { w: '기운차다', c: '#c47147' }
  ]


  class Wookmark
    constructor: (@id) ->
    apply: ->
      @handler?.wookmarkInstance?.clear()
      @handler = $("##{@id} > li")
      @handler.wookmark
        align: 'left'
        autoResize: true
        container: $("##{@id}")
        offset: 16
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

      _.bindAll @, 'index', 'logout', 'my_feelings', 'received_feelings'
    _login_view: ->
      @models.app.set {menu: '#menu_signup'}
      @layout.header.show new LoginView
      @layout.status.show()
      @layout.body.show()
    index: ->
      $.ajax
        url: '../sessions'
        statusCode:
          401: ->
          403: ->
        context: @
        success: -> @navigate 'shared_feelings', {trigger: true}
        error: -> @_login_view()
    logout: ->
      $.ajax
        url: '../sessions'
        type: 'DELETE'
        dataType: 'json'
        success: (data) -> window.location = '/'
    shared_feelings: ->
      @models.app.set {menu: '#menu_share'}
      @models.me.fetch
        success: (model)->
          router.layout.status.show new MyStatusView(model: model)
      @models.shared.fetch
        success: (model)->
          router.layout.body.show new SharedFeelingsView(model: model)
      @layout.header.show new NewFeelingView
    my_feelings: ->
      @models.app.set {menu: '#menu_my'}
      @models.me.fetch
        success: (model)->
          router.layout.status.show new MyStatusView(model: model)
      @models.my.fetch_more()
      @layout.header.show new NewFeelingView
      @layout.body.show new MyFeelingsView(model: @models.my)
    received_feelings: ->
      @models.app.set {menu: '#menu_received'}
      @models.me.fetch
        success: (model)->
          router.layout.status.show new MyStatusView(model: model)
      @models.live_feelings.fetch()
      @models.received.fetch_more()
      @layout.header.show new LiveFeelingsView
        model: @models.live_feelings
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
  class Associate extends Backbone.Model
  class Associates extends Backbone.Collection
    url: '../api/associates'

  class Comment extends Backbone.Model
  class Talk extends Backbone.Model
  class MyFeeling extends Backbone.Model
  class MyFeelings extends Backbone.Collection
    defaults: { type: 'my' }
    model: MyFeeling
    url: '../api/my_feelings'
    fetch_more: ->
      new MyFeelings().fetch
        data:
          type: @get('type')
          skip: @models?.length || 0
          n: 10
        success: (model, res) ->
          len = router.models.my.length
          for m in model.models
            router.models.my.add m
          if router.models.my.length > len
            router.models.my.trigger 'concat', model.models

  class ReceivedFeeling extends Backbone.Model
  class ReceivedFeelings extends Backbone.Collection
    defaults: { type: 'rcv' }
    model: ReceivedFeeling
    url: '../api/received_feelings'
    fetch_more: ->
      new ReceivedFeelings().fetch
        data:
          type: @get('type')
          skip: @models?.length || 0
          n: 10
        success: (model, res) ->
          len = router.models.received.length
          for m in model.models
            router.models.received.add m
          if router.models.received.length > len
            router.models.received.trigger 'concat', model.models

  class ArrivedFeeling extends Backbone.Model
  class ArrivedFeelings extends Backbone.Collection
    model: ArrivedFeeling
    url: '../api/arrived_feelings'
  class NewComment extends Backbone.Model      
  class Feeling extends Backbone.Model
    url: '../api/feelings'
  class SharedFeelings extends Backbone.Collection
    defaults: { type: 'share' }
    model: Feeling
    url: '../api/feelings'
    fetch: (options={}) ->
      options.data = {type: @get('type')}
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

  # parent에서 child의 render대신 show 호출할것
  # event callback도 동일
  # show: ->
  #   destroy children and self.el.empty
  #   self.render
  #   children.on_rendered
  # render: ->
  #   models.fetch_aync
  #   @_attach views
  #   @$el.append views.el
  class FsView extends Backbone.View
    _attach: (view) ->
      @views.push view
      view.show()
      view
    _detach_all: ->
      @views ||= []
      while @views.length > 0
        @views.pop().close()
    show: ->
      console.log "#{@constructor.name}.show"
      @_detach_all()
      @$el.empty()
      @render()
      for v in @views
        v.on_rendered()
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
    @live_status:  _.template $('#tpl_live_status').html()
    @new_feeling:  _.template $('#tpl_new_feeling').html()
    @talk:         _.template $('#tpl_talk').html()
    @my_feeling:   _.template $('#tpl_my_feeling').html()
    @new_comment:  _.template $('#tpl_new_comment').html()
    @feeling:      _.template $('#tpl_feeling').html()
    @arrived:      _.template $('#tpl_arrived_feeling').html()
    @arrived_holder: _.template $('#tpl_arrived_holder').html()

  class AppView extends FsView
    template: Tpl.navbar
    initialize: ->
      @model.on 'change:menu', @show, @
    render: ->
      @$el.html @template(@model.toJSON())
      @$el.find('.fs_menu').removeClass 'active'
      $(@model.get('menu')).addClass 'active'
    close: ->
      super()
      @model.off 'change:menu', @show

  class LoginView extends FsView
    events:
      'click .fs_submit': '_on_submit'
    template: Tpl.login
    render: ->
      @$el.html @template()
    _on_submit: ->
      $.ajax
        url: '../sessions'
        type: 'POST'
        dataType: 'json'
        context: @
        data:
          email: $('#email').val()
          password: $('#password').val()
        success: (data) ->
          router.models.app.set {'logged_in': true}
          router.navigate 'shared_feelings', {trigger: true}
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
      @model.off 'sync', @show

  class LiveFeelingView extends FsView
    tagName: 'li'
    template: Tpl.live_feeling
    render: ->
      @$el.html @template(_.extend(@model.toJSON(), {gW: gW}))

  class LiveFeelingsView extends FsView
    tagName: 'div'
    template: Tpl.live_status
    initialize: ->
      @model.on 'sync', @show, @
    render: ->
      @$el.html @template()
      holder = @$el.find('#live_holder')
      for m in @model.models
        holder.append @_attach(new LiveFeelingView(model: m)).el
    close: ->
      super()
      @model.off 'sync', @show

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
      unless @expanded
        @$el.find('.content0-input').css('display', 'block')
        @expanded = true
        router.layout.body.current_view.on_rendered()
    _on_submit: ->
      $.ajax
        url: '../api/feelings'
        type: 'POST'
        dataType: 'json'
        context: @
        data:
          word: @$el.find('#wordselect').find('.active').attr('word-id')
          blah: @$el.find('#new_feeling_content').val()
          is_public: true
        success: (data) ->
          #router.navigate 'shared_feelings', {trigger: true}
          router.shared_feelings()

  class TalkView extends FsView
    template: Tpl.talk
    initialize: ->
      @model.on 'change', @show, @
    render: ->
      @$el.html @template(@model.toJSON())
    close: ->
      super()
      @model.off 'change', @show

  class MyFeelingView extends FsView
    tagName: 'li'
    events:
      'click .inner': '_on_expand'
    template: Tpl.my_feeling
    _expand: false
    _on_expand_triggered: false
    initialize: ->
      @model.on 'change', @show, @
    render: ->
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template(_.extend(@model.toJSON(), {gW: gW}))
      if @_expand
        holder = @$el.find('.talks')
        holder.empty()
        for u,talk of @model.get('talks')
          m =
            shared: @model.get('share')
            user_id: u
            comments: talk
          holder.append @_attach(new TalkView(model: new Talk(m))).el

      if @_on_expand_triggered
        @$el.trigger 'refreshWookmark'
      @_on_expand_triggered = false
    _on_expand: (event) ->
      @_on_expand_triggered = true
      @_expand = not @_expand
      @show()
    close: ->
      super()
      @model.off 'change', @show, @

  class MyFeelingsView extends FsView
    tagName: 'ul'
    id: 'my_feelings_holder'
    className: 'fs_tiles'
    initialize: ->
      @_wookmark = new Wookmark(@id)
      @model.on 'concat', @_on_concat, @
      $(window).on 'scroll', @_on_scroll
    render: ->
      for m in @model.models
        @$el.append @_attach(new MyFeelingView(model: m)).el
    on_rendered: ->
      @_wookmark.apply()
    _on_scroll: (e) ->
      router.models.my.fetch_more() if $(window).scrollTop() + $(window).height() >  $(document).height() - 100
    _on_concat: (list) ->
      for m in list
        @$el.append @_attach(new MyFeelingView(model: m)).el
      @_wookmark.apply()
    close: ->
      super()
      @model.off 'concat', @_on_concat
      $(window).off 'scroll', @_on_scroll

  class NewCommentView extends FsView
    className: 'new_comment'
    events:
      'click .fs_link': '_on_submit'
    template: Tpl.new_comment
    render: ->
      @$el.html @template()
      @
    _on_submit: (event) -> 
      alert 'not implemented'

  class FeelingView extends FsView
    tagName: 'li'
    events:
      'click .inner': '_on_expand'
    template: Tpl.feeling
    _expand: false
    _on_expand_triggered: false
    initialize: ->
      @model.on 'sync', @show, @
    render: ->
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template(_.extend(@model.toJSON(), {gW: gW}))

      if @_expand
        holder = @$el.find('.talks')
        holder.empty()
        for u,talk of @model.get('talks')
          m =
            shared: @model.get('share')
            mine: @model.get('own')
            talk_user_id: u
            comments: talk
            user: @model.get('talk_user')
          holder.append @_attach(new TalkView(model: new Talk(m))).el

      if @_on_expand_triggered
        @$el.trigger 'refreshWookmark'
      @_on_expand_triggered = false
    _on_expand: (event) ->
      @_on_expand_triggered = true
      @_expand = not @_expand
      @model.fetch()
    close: ->
      super()
      @model.off 'change', @show

  class ReceivedFeelingsView extends FsView
    tagName: 'ul'
    id: 'received_feelings_holder'
    className: 'fs_tiles'
    initialize: ->
      @_wookmark = new Wookmark(@id)
      @model.on 'prepend', @_on_prepend, @
      @model.on 'concat', @_on_concat, @
      $(window).on 'scroll', @_on_scroll
    render: ->
      @$el.append @_attach(new ArrivedFeelingView).el
      for m in @model.models
        @$el.append @_attach(new FeelingView(model: m)).el
    on_rendered: ->
      @_wookmark.apply()
    _on_scroll: ->
      router.models.received.fetch_more() if $(window).scrollTop() + $(window).height() >  $(document).height() - 100
    _on_concat: (list) ->
      console.log 'concat'
      for m in list
        @$el.append @_attach(new FeelingView(model: m)).el
      @_wookmark.apply()
    _on_prepend: (model) ->
      @model.models.unshift model
      @$el.find('.arrived_feeling').after @_attach(new FeelingView(model: model)).el
      @_wookmark.apply()
    close: ->
      super()
      @model.off 'concat', @_on_concat
      @model.off 'prepend', @_on_prepend
      $(window).off 'scroll', @_on_scroll

  class ArrivedFeelingView extends FsView
    tagName: 'li'
    className: 'arrived_feeling'
    events:
      'click #receive_arrived': '_on_receive'
      'click #flipcard': '_on_flip'
    template: Tpl.arrived
    holder_template: Tpl.arrived_holder
    initialize: ->
      @model = new ArrivedFeelings
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
        dataType: 'json'
        context: @
        success: (data) ->
          @model.reset()
          @model.trigger 'sync'
          router.models.shared.trigger 'prepend', new Feeling(data)
    close: ->
      super()
      @model.off 'sync', @show
      router.models.me.off 'sync', @show
    
  class SharedFeelingsView extends FsView
    tagName: 'ul'
    id: 'shared_feelings_holder'
    className: 'fs_tiles'
    initialize: ->
      @_wookmark = new Wookmark(@id)
      @model.on 'prepend', @_on_prepend, @
    render: ->
      @$el.append @_attach(new ArrivedFeelingView).el
      for m in @model.models
        @$el.append @_attach(new FeelingView(model: m)).el
    on_rendered: ->
      @_wookmark.apply()
    _on_prepend: (model) ->
      @model.models.unshift model
      @$el.find('.arrived_feeling').after @_attach(new FeelingView(model: model)).el
      @_wookmark.apply()
    close: ->
      super()
      @model.off 'prepend', @_on_prepend


  router = new Router
  $.ajaxSetup
    statusCode:
      401: -> window.location = '/'
      403: -> window.location = '/'
  Backbone.history.start()
