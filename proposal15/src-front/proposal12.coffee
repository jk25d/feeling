$ ->
  gW =
    w0: { w: '두렵다', c: '#556270' }
    w1: { w: '무섭다', c: '#556270' }
    w2: { w: '우울하다', c: '#7f94b0' }
    w3: { w: '기운이없다', c: '#938172' }
    w4: { w: '무기력하다', c: '#938172' }
    w5: { w: '의욕이없다', c: '#938172' }
    w6: { w: '불안하다', c: '#77cca4' }
    w7: { w: '외롭다', c: '#c3ff68' }
    w8: { w: '걱정된다', c: '#14b0d9' }
    w9: { w: '허전하다', c: '#14d925' }
    w10: { w: '삶이힘들다', c: '#e177b3' }
    w11: { w: '한심하다', c: '#ffc6e2' }
    w12: { w: '짜증난다', c: '#c6aae2' }
    w13: { w: '슬프다', c: '#77cca4' }
    w14: { w: '절망스럽다', c: '#d9cbb8' }
    w15: { w: '화난다', c: '#594944' }
    w16: { w: '쓸쓸하다', c: '#758fe6' }
    w17: { w: '초조하다', c: '#b5242e' }
    w18: { w: '마음아프다', c: '#29a9b3' }
    w19: { w: '열등감느낀다', c: '#e8175d' }
    w20: { w: '사랑스럽다', c: '#14b0d9' }
    w21: { w: '소중하다', c: '#c3ff68' }
    w22: { w: '설레다', c: '#14d925' }
    w23: { w: '즐겁다', c: '#e177b3' }
    w24: { w: '기쁘다', c: '#ffc6e2' }
    w25: { w: '뿌듯하다', c: '#c6aae2' }
    w26: { w: '만족스럽다', c: '#77cca4' }
    w27: { w: '가슴벅차다', c: '#d9cbb8' }
    w28: { w: '자신있다', c: '#f0ba3c' }
    w29: { w: '기운차다', c: '#c47147' }


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
      'received_feelings': 'received_feelings'
    views: {}
    layout: {}
    models: {}
    initialize: ->
      @models.me = new Me
      @models.live_feelings = new LiveFeelings
      @models.associates = new Associates
      @models.my = new MyFeelings
      @models.received = new ReceivedFeelings
      @models.app = new App

      @layout.nav = new NavLayout
      @layout.header = new HeaderLayout
      @layout.body = new BodyLayout

      @layout.nav.show new AppView(model: @models.app)

      _.bindAll @, 'index', 'logout', 'my_feelings', 'received_feelings'
    index: ->
      if @models.app.get 'user'
        @navigate 'received_feelings', {trigger: true}
      else
        @models.app.set {user: null, menu: '#menu_signup'}
        @layout.header.show new LoginView
        @layout.body.show()
    logout: ->
      $.ajax
        url: '../sessions'
        type: 'DELETE'
        dataType: 'json'
        context: @
        success: (data) -> window.location = '/'
    my_feelings: ->
      @layout.header.show new NewFeelingView
        me: @models.me
      @layout.body.show new MyFeelingsView(model: @models.my)

      #@models.app.fetch()
      @models.app.set {menu: '#menu_my'}

      @models.my.fetch_more() if @models.my.length == 0
    received_feelings: ->
      @layout.header.show new LiveFeelingsView
        me: @models.me
        model: @models.live_feelings
      @layout.body.show new ReceivedFeelingsView(model: @models.received)
      #@models.app.fetch()
      @models.app.set {menu: '#menu_received'}

      @models.me.fetch()
      @models.live_feelings.fetch()
      @models.received.fetch_more() if @models.received.length == 0
      
  tpl_json = (model) ->
    obj = model?.toJSON() || {}
    obj['gW'] = gW
    obj

  #--- MODELS ---#

  class App extends Backbone.Model
    defaults:
      user: null
      menu: '#menu_signup'
    url: '../sessions'  
  class Me extends Backbone.Model
    defaults:
      user_id: ''
      n_available_feelings: 0
    url: '../api/me'
  class LiveFeeling extends Backbone.Model
  class LiveFeelings extends Backbone.Collection
    model: LiveFeeling
    url: '../api/live_feelings'
  class Associate extends Backbone.Model
  class Associates extends Backbone.Collection
    url: '../api/associates'

  class Comment extends Backbone.Model
  class Comments extends Backbone.Model
  class MyFeeling extends Backbone.Model
  class MyFeelings extends Backbone.Collection
    model: MyFeeling
    url: '../api/my_feelings'
    fetch_more: ->
      new MyFeelings().fetch
        data:
          skip: @models?.length || 0
          n: 10
        success: (model, res) ->
          len = router.models.my.length
          for m in model.models
            router.models.my.add m
          if router.models.my.length > len
            router.models.my.trigger 'concat', model.models

  class ArrivedFeeling extends Backbone.Model
  class ArrivedFeelings extends Backbone.Collection
    model: ArrivedFeeling
    url: '../api/new_arrived_feelings'
  class NewComment extends Backbone.Model      
  class ReceivedFeeling extends Backbone.Model
  class ReceivedFeelings extends Backbone.Collection
    model: ReceivedFeeling
    url: '../api/received_feelings'
    fetch_more: ->
      new ReceivedFeelings().fetch
        data:
          skip: @models?.length || 0
          n: 10
        success: (model, res) ->
          len = router.models.received.length
          for m in model.models
            router.models.received.add m
          if router.models.received.length > len
            router.models.received.trigger 'concat', model.models

  #--- Layout ---#

  class Layout
    show: (view) ->  
      @current_view.close() if @current_view
      return $("##{@id}").html() unless view
      @current_view = view
      @current_view.render()
      $("##{@id}").html @current_view.el
      @current_view.on_rendered()

  class NavLayout extends Layout
    id: 'fs_navbar'

  class HeaderLayout extends Layout
    id: 'fs_header'

  class BodyLayout extends Layout
    id: 'fs_body'

  #--- VIEWS ---#

  # rerender 시 render했던 모든 view를 destroy하는 컨셉
  class FsView extends Backbone.View
    attach: (view) ->
      @views.push view
      view.render()
      view
    detach_all: ->
      @views ||= []
      while @views.length > 0
        @views.pop().close()
    render: ->
      console.log "#{@constructor.name}.render"
      @detach_all()
      @$el.empty()
    on_rendered: ->
    close: ->
      @detach_all()
      @remove()
      @off()

  class AppView extends FsView
    template: _.template $('#tpl_navbar').html()
    initialize: ->
      @model.on 'change', @render, @
    render: ->
      super()
      @$el.html @template(@model.toJSON())
      @$el.find('.fs_menu').removeClass 'active'
      $(@model.get('menu')).addClass 'active'
    close: ->
      super()
      @model.off 'change', @render

  class LoginView extends FsView
    events:
      'click .fs_submit': 'on_submit'
    template: _.template $('#tpl_login').html()
    render: ->
      super()
      @$el.html @template()
    on_submit: ->
      $.ajax
        url: '../sessions'
        type: 'POST'
        dataType: 'json'
        context: @
        data:
          user_id: $('#user_id').val()
          password: $('#password').val()
        success: (data) ->
          router.models.app.set 'user', data.user
          router.navigate 'received_feelings', {trigger: true}

  class SignupView extends FsView
    events:
      'click .fs_submit': 'on_submit'
    template: _.template $('#tpl_signup').html()
    render: ->
      super()
      @$el.html @template()
    on_submit: ->
      console.log 'signup submit'

  class MeView extends FsView
    template: _.template $('#tpl_me').html()
    initialize: ->
      @model.on 'sync', @render, @
    render: ->
      super()
      @$el.html @template(@model.toJSON())    
    close: ->
      super()
      @model.off 'sync', @render

  class LiveFeelingView extends FsView
    tagName: 'li'
    template: _.template $('#tpl_live_feeling').html()
    render: ->
      super()
      @$el.html @template(tpl_json(@model))

  class LiveFeelingsView extends FsView
    tagName: 'div'
    template: _.template $('#tpl_live_status').html()
    initialize: ->
      @me = @options.me
      @model.on 'sync', @render, @
    render: ->
      super()
      @$el.html @template()
      holder = @$el.find('#live_holder')
      for m in @model.models
        holder.append @attach(new LiveFeelingView(model: m)).el
      @$el.find('.me_holder').html @attach(new MeView(model: @me)).el
    close: ->
      super()
      @model.off 'sync', @render

  class NewFeelingView extends FsView
    events:
      'click .fs_submit': 'on_submit'
      'click #wordselect>li': 'on_select_word'
    template: _.template $('#tpl_new_feeling').html()
    initialize: ->
      @me = @options.me
    render: ->
      super()
      @$el.html @template(tpl_json())
      @$el.find('.me_holder').html @attach(new MeView(model: @me)).el
    on_select_word: (e) ->
      @$el.find('#wordselect').find('.active').removeClass 'active'
      $(e.target).toggleClass 'active'
      unless @expanded
        @$el.find('.content0-input').css('display', 'block')
        @expanded = true
        router.layout.body.current_view.wookmark.apply()
    on_submit: ->
      $.ajax
        url: '../api/my_feelings'
        type: 'POST'
        dataType: 'json'
        context: @
        data:
          word_id: @$el.find('#wordselect').find('.active').attr('word-id')
          content: @$el.find('#new_feeling_content').val()
        success: (data) ->
          router.navigate 'my_feelings', true

  class CommentView extends FsView
    events:
      'click .icon-remove': 'on_remove'
      'click .icon-heart': 'on_like'
    template: _.template $('#tpl_comment').html()
    initialize: ->
      @model.on 'change', @render, @
    render: ->
      super()
      @$el.html @template(@model.toJSON())      
    on_remove: -> 
      alert 'not implemented'
    on_like: -> 
      alert 'not implemented'
    close: ->
      super()
      @model.off 'change', @render

  class CommentsView extends FsView
    template: _.template $('#tpl_comments').html()
    initialize: ->
      @model.on 'change', @render, @
    render: ->
      super()
      @$el.html @template(@model.toJSON())
    close: ->
      super()
      @model.off 'change', @render

  class MyFeelingView extends FsView
    tagName: 'li'
    events:
      'click .inner': 'on_expand'
    template: _.template $('#tpl_my_feeling').html()
    initialize: ->
      @model.on 'change', @render, @
      @expand = false
    render: ->
      super()
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template(tpl_json(@model))
      if @expand
        console.log 'render comments'
        console.log @model
        holder = @$el.find('.talks')
        holder.empty()
        for u,comments of @model.get('talks')
          console.log "#{u}: #{comments}"
          m =
            me: router.models.me.user_id
            shared: true
            user_id: u
            comments: comments
          holder.append @attach(new CommentsView(model: new Comments(m))).el

      if @on_expand_triggered
        @$el.trigger 'refreshWookmark'
      @on_expand_triggered = false
    on_expand: (event) ->
      @on_expand_triggered = true
      @expand = not @expand
      @render()
    close: ->
      super()
      @model.off 'change', @render(), @

  class MyFeelingsView extends FsView
    tagName: 'ul'
    id: 'my_feelings_holder'
    className: 'fs_tiles'
    initialize: ->
      @wookmark = new Wookmark(@id)
      @model.on 'concat', @on_concat, @
      $(window).on 'scroll', @on_scroll
    render: ->
      super()
      for m in @model.models
        @$el.append @attach(new MyFeelingView(model: m)).el
    on_rendered: ->
      console.log 'wook.my'
      @wookmark.apply()
    on_scroll: (e) ->
      router.models.my.fetch_more() if $(window).scrollTop() + $(window).height() >  $(document).height() - 100
    on_concat: (list) ->
      for m in list
        @$el.append @attach(new MyFeelingView(model: m)).el
      @wookmark.apply()
    close: ->
      super()
      @model.off 'concat', @on_concat
      $(window).off 'scroll', @on_scroll

  class NewCommentView extends FsView
    className: 'new_comment'
    events:
      'click .fs_link': 'on_submit'
    template: _.template $('#tpl_new_comment').html()
    render: ->
      super()
      @$el.html @template()
      @
    on_submit: (event) -> 
      alert 'not implemented'

  class ReceivedFeelingView extends FsView
    tagName: 'li'
    events:
      'click .inner': 'on_expand'
    template: _.template $('#tpl_received_feeling').html()
    initialize: ->
      @model.on 'change', @render, @
      @expand = false
    render: ->
      super()
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template(tpl_json(@model))

      if @expand
        console.log 'render comments'
        holder = @$el.find('.talks')
        holder.empty()
        for u,comments of @model.get('talks')
          m =
            me: router.models.me.user_id
            shared: true
            user_id: u
            comments: comments
          holder.append @attach(new CommentsView(model: new Comments(m))).el

      if @on_expand_triggered
        @$el.trigger 'refreshWookmark'
      @on_expand_triggered = false
    on_expand: (event) ->
      @on_expand_triggered = true
      @expand = not @expand
      @render()
    close: ->
      super()
      @model.off 'change', @render

  class ReceivedFeelingsView extends FsView
    tagName: 'ul'
    id: 'received_feelings_holder'
    className: 'fs_tiles'
    events:
      'click .fs_more': 'on_more'
    template: _.template $('#tpl_feelings').html()
    initialize: ->
      @wookmark = new Wookmark(@id)
      @model.on 'prepend', @on_prepend, @
      @model.on 'concat', @on_concat, @
      $(window).on 'scroll', @on_scroll
    render: ->
      super()
      @$el.append @attach(new ArrivedFeelingView).el
      for m in @model.models
        @$el.append @attach(new ReceivedFeelingView(model: m)).el
    on_rendered: ->
      console.log 'wook'
      @wookmark.apply()
    on_scroll: ->
      router.models.received.fetch_more() if $(window).scrollTop() + $(window).height() >  $(document).height() - 100
    on_concat: (list) ->
      console.log 'concat'
      for m in list
        @$el.append @attach(new ReceivedFeelingView(model: m)).el
      @wookmark.apply()
    on_prepend: (model) ->
      @model.models.unshift model
      @$el.find('#arrived_feeling').after @attach(new ReceivedFeelingView(model: model)).el
      @wookmark.apply()
    on_more: (event) ->
      @model.fetch_more()
    close: ->
      super()
      @model.off 'concat', @on_concat
      @model.off 'prepend', @on_prepend
      $(window).off 'scroll', @on_scroll

  class ArrivedFeelingView extends FsView
    tagName: 'li'
    id: 'arrived_feeling'
    events:
      'click #receive_arrived': 'on_receive'
      'click #flipcard': 'on_flip'
    template: _.template $('#tpl_arrived_feeling').html()
    holder_template: _.template $('#tpl_arrived_holder').html()
    initialize: ->
      @model = new ArrivedFeelings
      @model.on 'sync', @render, @
      router.models.me.on 'sync', @render, @
    render: ->
      super()
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      if @model.length > 0
        @$el.addClass('rd6').addClass('_sd0').addClass('card')
        @$el.html @template(tpl_json(@model.at(0)))
      else
        @$el.addClass('rd6').addClass('card')
        @$el.html @holder_template(router.models.me.toJSON())
      @
    on_receive: (event) ->
      console.log 'on_receive'
      @model.fetch()
    on_flip: (event) ->
      console.log 'on_flip'
      model = @model.at 0
      $.ajax
        url: "../api/new_arrived_feelings/#{model.get('id')}"
        type: 'PUT'
        dataType: 'json'
        context: @
        success: (data) ->
          @model.reset()
          @model.trigger 'sync'
          router.models.received.trigger 'prepend', new ReceivedFeeling(data)
    close: ->
      super()
      @model.off 'sync', @render
      router.models.me.off 'sync', @render
    
  router = new Router
  $.ajaxSetup
    statusCode:
      401: -> window.location = '/'
      403: -> window.location = '/'
  Backbone.history.start()
