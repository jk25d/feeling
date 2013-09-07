$ ->
  gW =
    w00: { w: '두렵다', c: '#556270' }
    w01: { w: '무섭다', c: '' }
    w02: { w: '우울하다', c: '#7f94b0' }
    w03: { w: '기운이없다', c: '' }
    w04: { w: '무기력하다', c: '' }
    w05: { w: '의욕이없다', c: '' }
    w06: { w: '불안하다', c: '' }
    w07: { w: '외롭다', c: '' }
    w08: { w: '걱정된다', c: '' }
    w09: { w: '허전하다', c: '' }
    w10: { w: '삶이힘들다', c: '' }
    w11: { w: '한심하다', c: '' }
    w12: { w: '짜증난다', c: '' }
    w13: { w: '슬프다', c: '' }
    w14: { w: '절망스럽다', c: '' }
    w15: { w: '화난다', c: '' }
    w16: { w: '쓸쓸하다', c: '' }
    w17: { w: '초조하다', c: '' }
    w18: { w: '마음아프다', c: '' }
    w19: { w: '열등감느낀다', c: '' }
    w20: { w: '사랑스럽다', c: '' }
    w21: { w: '소중하다', c: '' }
    w22: { w: '설레다', c: '' }
    w23: { w: '즐겁다', c: '' }
    w24: { w: '기쁘다', c: '' }
    w25: { w: '뿌듯하다', c: '' }
    w26: { w: '만족스럽다', c: '' }
    w27: { w: '가슴벅차다', c: '' }
    w28: { w: '자신있다', c: '' }
    w29: { w: '기운차다', c: '' }


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
        itemWidth: 226
        fillEmptySpace: true

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
        @layout.header.show new SignupView
        @layout.body.show new EmptyBodyView
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
        live_feelings: @models.live_feelings
        associates: @models.associates
      @layout.body.show new MyFeelingsView(model: @models.my)

      @models.app.fetch()
      @models.app.set {menu: '#menu_my'}

      @models.me.fetch()
      @models.live_feelings.fetch()
      @models.associates.fetch()
      @models.my.fetch_more() if @models.my.length == 0
    received_feelings: ->
      @layout.header.show new NewFeelingView
        me: @models.me
        live_feelings: @models.live_feelings
        associates: @models.associates      
      @layout.body.show new ReceivedFeelingsView(model: @models.received)
      @models.app.fetch()
      @models.app.set {menu: '#menu_received'}

      @models.me.fetch()
      @models.live_feelings.fetch()
      @models.associates.fetch()
      @models.received.fetch_more() if @models.received.length == 0
      

  #--- MODELS ---#

  class App extends Backbone.Model
    defaults:
      user: null
      menu: '#menu_signup'
    url: '../sessions'  
  class Me extends Backbone.Model
    defaults:
      n_available_feelings: 0
    url: '../api/me'
  class LiveFeelings extends Backbone.Model
    url: '../api/live_feelings'
  class Associate extends Backbone.Model
  class Associates extends Backbone.Collection
    url: '../api/associates'

  class Comment extends Backbone.Model
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
          router.models.received.trigger 'concat', model.models

  #--- Layout ---#

  class Layout
    show: (view) ->  
      @current_view.close() if @current_view
      @current_view = view
      @current_view.render()

  class NavLayout extends Layout

  class HeaderLayout extends Layout

  class BodyLayout extends Layout

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
    close: ->
      @detach_all()
      @remove()
      @off()

  class AppView extends FsView
    events:
      'click #login_toggle': 'login'
    template: _.template $('#tpl_navbar').html()
    initialize: ->
      @model.on 'change', @render, @
    render: ->
      super()
      @$el.html @template(@model.toJSON())
      $('#fs_navbar').html @$el
      @login_view = @attach new LoginView
      $('#fs_navbar .fs_menu').removeClass 'active'
      $(@model.get('menu')).addClass 'active'
    login: (e) ->
      @login_view.toggle($(e.target))
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
      $('#login_holder').html @$el
    toggle: (target) ->
      t = target.offset().top + target.outerHeight()
      l = target.offset().left
      $('#login').css('top', t).css('left', l)
      $('#login').toggle()
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
      $('#fs_header').html @$el
    on_submit: ->
      console.log 'signup submit'

  class NewFeelingView extends FsView
    events:
      'click .fs_submit': 'on_submit'
    template: _.template $('#tpl_new_feeling').html()
    me_template: _.template $('#tpl_me').html()
    associates_template: _.template $('#tpl_associates').html()
    initialize: ->
      @me = @options.me
      @live_feelings = @options.live_feelings
      @associates = @options.associates
      @me.on 'sync', @render_me, @
      @live_feelings.on 'sync', @render_live_feelings, @
      @associates.on 'sync', @render_associates, @
    render: ->
      super()
      @$el.html @template()
      $('#fs_header').html @$el
    render_me: ->
      console.log 'render_me'
      $('#fs_header_me').html @me_template(@me.toJSON())
    render_live_feelings: ->
      console.log 'render_live_feelings'
      console.log @live_feelings
      el = $('#fs_header_live_feelings')
      el.empty()
      for word, n of @live_feelings.attributes
        el.append "<li>#{word}</li>"
    render_associates: ->
      el = $('#fs_header_associates')
      el.empty()
      for m in @associates.models
        el.append @associates_template(m.toJSON())
    on_submit: ->
      $.ajax
        url: '../api/my_feelings'
        type: 'POST'
        dataType: 'json'
        context: @
        data:
          word_id: $('#wordselect').find('.active').attr('word-id')
          content: $('#new_feeling_content').val()
        success: (data) ->
          router.navigate 'my_feelings', true
    close: ->
      super()
      @me.off 'sync', @render_me
      @live_feelings.off 'sync', @render_live_feelings
      @associates.off 'sync', @render_associates

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

  class MyFeelingView extends FsView
    tagName: 'li'
    events:
      'click .inner': 'on_expand'
      'click .comments': 'on_expand'
    template: _.template $('#tpl_my_feeling').html()
    initialize: ->
      @model.on 'change', @render, @
    render: ->
      super()
      @set_comments_count()
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template(@model.toJSON())
      if @expand
        console.log 'render comments'
        holder = @$el.find('.comments')
        holder.empty()
        for m in @model.get('comments')
          console.log m
          holder.append @attach(new CommentView(model: new Comment(m))).el
        unless @expanded
          @$el.trigger 'refreshWookmark'
        @expanded = true
    set_comments_count: ->
      n_comments = n_hearts = 0
      for c in @model.get('comments')
        n_hearts++ if c.type == 'heart'
        n_comments++ if c.type == 'comment'
      @model.set {n_comments: n_comments, n_hearts: n_hearts}
    on_expand: (event) ->
      return if @expand
      @expand = true
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
    render: ->
      super()
      @attach new FeelingsHolderView(model: @model)

      for m in @model.models
        @$el.append @attach(new MyFeelingView(model: m)).el
      $('#fs_holder').html @$el
      @wookmark.apply()
    on_concat: (list) ->
      @model.models.concat list
      for m in list
        @$el.append @attach(new MyFeelingView(model: m)).el
      @wookmark.apply()
    close: ->
      super()
      @model.off 'concat', @on_concat

  class FeelingsHolderView extends FsView
    events:
      'click .fs_more': 'on_more'
    template: _.template $('#tpl_feelings').html()
    render: ->
      super()
      @$el.html @template()
      $('#fs_body').html @$el
    on_more: (event) ->
      @model.fetch_more()

  class EmptyBodyView extends FsView
    render: ->
      super()
      $('#fs_body').empty()

  class NewCommentView extends FsView
    className: 'new_comment'
    events:
      'click .fs_submit': 'on_submit'
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
      'click .icon-comment': 'on_comment'
      'click .icon-heart': 'on_like'
      'click .icon-share-alt': 'on_forward'
    template: _.template $('#tpl_received_feeling').html()
    initialize: ->
      @model.on 'change', @render, @
    render: ->
      super()
      @$el.removeClass('rd6').removeClass('_sd0').removeClass('card')
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template(@model.toJSON())

      type = @model.get 'type'
      if type
        @$el.find('.icon-trans').css 'background-color', '#cccccc'
        if type == 'comment'
          @$el.find('.icon-comment').css 'background-color', '#44f9b8'
        if type == 'like'
          @$el.find('.icon-heart').css 'background-color', '#44f9b8'
        if type == 'forward'
          @$el.find('.icon-share-alt').css 'background-color', '#44f9b8'
        @$el.find('.inputarea').html @attach(new NewCommentView).el
        unless @expanded
          @$el.trigger 'refreshWookmark'
        @expanded = true
      @
    on_comment: (event) ->
      @model.set 'type', 'comment'
    on_like: (event) ->
      @model.set 'type', 'like'
    on_forward: (event) ->
      @model.set 'type', 'forward'
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
    render: ->
      super()
      @attach new FeelingsHolderView(model: @model)

      @$el.append @attach(new ArrivedFeelingView).el

      for m in @model.models
        @$el.append @attach(new ReceivedFeelingView(model: m)).el

      $('#fs_holder').html @$el
      @wookmark.apply()
    on_concat: (list) ->
      console.log 'on_concat'
      @model.models.concat list
      for m in list
        @$el.append @attach(new ReceivedFeelingView(model: m)).el
      @wookmark.apply()
    on_prepend: (model) ->
      @model.models.unshift model
      $('#arrived_feeling').after @attach(new ReceivedFeelingView(model: model)).el
      @wookmark.apply()
    on_more: (event) ->
      @model.fetch_more()
    close: ->
      super()
      @model.off 'concat', @on_concat
      @model.off 'prepend', @on_prepend

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
        @$el.html @template(@model.toJSON())
      else
        @$el.addClass('rd6').addClass('card')
        @$el.html @holder_template(router.models.me.toJSON())
      @
    on_receive: (event) ->
      console.log 'on_receive'
      @model.fetch()
    on_flip: (event) ->
      console.log 'on_flip'
      console.log @model
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
