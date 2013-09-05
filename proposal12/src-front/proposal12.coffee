$ ->
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

  class Router extends Backbone.Router
    routes:
      '': 'index'
      'login': 'index'
      'logout': 'logout'
      'signup': 'signup'
      'my_feelings': 'my_feelings'
      'received_feelings': 'received_feelings'
    views: {}
    active_views: []
    models: {}
    initialize: ->
      @models.me = new Me
      @models.live_feelings = new LiveFeelings
      @models.associates = new Associates
      @models.my = new MyFeelings
      @models.received = new ReceivedFeelings
      @models.app = new App

      @views.login = new LoginView
      @views.signup = new SignupView
      @views.new_feeling = new NewFeelingView
        me: @models.me
        live_feelings: @models.live_feelings
        associates: @models.associates
      @views.my = new MyFeelingsView(model: @models.my)
      @views.received = new ReceivedFeelingsView(model: @models.received)

      @app_view = new AppView(model: @models.app)
      @app_view.render()

      _.bindAll @, 'unrender', 'index', 'logout', 'signup', 'draw_login', 'my_feelings', 'received_feelings'
    unrender: ->
      while @active_views.length > 0
        @active_views.pop().unrender()
    index: ->
      console.log '#'
      if @models.app.get 'user'
        @navigate 'received_feelings', {trigger: true}
      else
        @draw_login()
    draw_login: ->
      @unrender()
      @models.app.set {user: null, menu: '#menu_login'}
      @views.login.render()
      @active_views.push @views.login
    logout: ->
      $.ajax
        url: '../sessions'
        type: 'DELETE'
        dataType: 'json'
        context: @
        success: (data) -> @draw_login()
    signup: ->
      @unrender()
      @views.signup.render()
      @active_views.push @views.signup

      @models.app.set {menu: '#menu_signup'}
    my_feelings: ->
      @unrender()
      @views.new_feeling.render()
      @views.my.render()
      @active_views.push @views.new_feeling
      @active_views.push @views.my

      @models.app.fetch()
      @models.app.set {menu: '#menu_my'}
      @models.me.fetch()
      @models.live_feelings.fetch()
      @models.associates.fetch()
      @models.my.fetch() if @models.my.length == 0
    received_feelings: ->
      console.log '#received_feelings'
      @unrender()
      @views.new_feeling.render()
      @views.received.render()
      @active_views.push @views.new_feeling
      @active_views.push @views.received

      @models.app.fetch()
      @models.app.set {menu: '#menu_received'}
      @models.me.fetch()
      @models.live_feelings.fetch()
      @models.associates.fetch()
      @models.received.fetch() if @models.received.length == 0


  #--- MODELS ---#

  class App extends Backbone.Model
    defaults:
      user: null
      menu: '#menu_login'
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
    fetch: ->
      super
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
    fetch: ->
      super
        data:
          skip: @models?.length || 0
          n: 10
        success: (model, res) ->
          router.models.received.trigger 'concat', model.models

  #--- VIEWS ---#

  class FsView extends Backbone.View
    unrender: ->
      console.log @
      while @views.length > 0
        @views.pop().unrender()

  class AppView extends FsView
    template: _.template($('#tpl_navbar').html())
    render: ->
      console.log 'appview.render'
      @$el.html @template(@model.toJSON())
      $('#fs_navbar').html @$el
      $('#fs_navbar .fs_menu').removeClass 'active'
      $(@model.get('menu')).addClass 'active'
      @model.once 'change', @render, @
    unrender: ->
      @$el.empty()
      $('#fs_navbar').empty()

  class LoginView extends FsView
    events:
      #'click .fs_submit': 'on_submit'
      'click #login_btn': 'on_submit'
    template: _.template($('#tpl_login').html())
    render: ->
      console.log 'login.render'
      @$el.html @template()
      $('#fs_header').html @$el
    on_submit: ->
      console.log 'login clicked'
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
    unrender: ->
      @$el.empty()
      $('#fs_header').empty()

  class SignupView extends FsView
    events:
      'click .fs_submit': 'on_submit'
    template: _.template($('#tpl_signup').html())
    render: ->
      console.log 'signup.render'
      @$el.html @template()
      $('#fs_header').html @$el
    on_submit: ->
      console.log 'signup submit'
    unrender: ->
      @$el.empty()
      $('#fs_header').empty()

  class NewFeelingView extends FsView
    events:
      'click .fs_submit': 'on_submit'
    template: _.template($('#tpl_new_feeling').html())
    me_template: _.template($('#tpl_me').html())
    associates_template: _.template($('#tpl_associates').html())
    initialize: ->
      @me = @options.me
      @live_feelings = @options.live_feelings
      @associates = @options.associates
    render: ->
      console.log 'newfeeling.render'
      @$el.html @template()
      $('#fs_header').html @$el
      @me.on 'sync', @render_me, @
      @live_feelings.on 'sync', @render_live_feelings, @
      @associates.on 'sync', @render_associates, @
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
    unrender: ->
      @me.off 'sync'
      @live_feelings.off 'sync'
      @associates.off 'sync'
      @$el.empty()
      $('#fs_header').empty()

  class CommentView extends FsView
    events:
      'click .icon-remove': 'on_remove'
      'click .icon-heart': 'on_like'
    template: _.template($('#tpl_comment').html())
    render: ->
      console.log 'comment.render'
      @$el.html @template(@model.toJSON())
      @model.once 'change', @render, @
      @
    on_remove: -> 
      alert 'not implemented'
    on_like: -> 
      alert 'not implemented'
    unrender: ->
      @$el.empty()

  class MyFeelingView extends FsView
    tagName: 'li'
    events:
      'click .card': 'on_expand'
    template: _.template($('#tpl_my_feeling').html())
    render: ->
      console.log 'myfeeling.render'
      @unrender()
      @set_comments_count()
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template(@model.toJSON())
      if @model.get('expand')
        holder = @$el.find('.comments')
        holder.empty()
        for m in @model.get('comments')
          view = new CommentView(model: new Comment(m))
          @views.push view
          holder.append view.render().el
      @model.once 'change', @render, @
      @
    set_comments_count: ->
      n_comments = n_hearts = 0
      for c in @model.get('comments')
        n_hearts++ if c.type == 'heart'
        n_comments++ if c.type == 'comment'
      @model.set {n_comments: n_comments, n_hearts: n_hearts}
    on_expand: (event) ->
      return if @model.get 'expand'
      @model.set 'expand', true
    unrender: ->
      super()
      @$el.empty()

  class MyFeelingsView extends FsView
    tagName: 'ul'
    id: 'my_feelings_holder'
    className: 'fs_tiles'
    initialize: ->
      @wookmark = new Wookmark(@id)
    render: ->
      console.log 'myfeelings.render'
      view = new FeelingsHolderView(model: @model)
      @views.push view
      view.render()

      for m in @model.models
        view = new MyFeelingView(model: m)
        @views.push view
        @$el.append view.render().el
      $('#fs_holder').html @$el
      @wookmark.apply()
      @model.on 'concat', @on_concat, @
    on_concat: (list) ->
      @model.models.concat list
      for m in list
        view = new MyFeelingView(model: m)
        @views.push view
        @$el.append view.render().el
      @wookmark.apply()
    unrender: ->
      super()
      @model.off 'concat'
      @$el.empty()
      $('#fs_holder').empty()

  class FeelingsHolderView extends FsView
    events:
      'click .fs_more': 'on_more'
    template: _.template($('#tpl_feelings').html())
    render: ->
      console.log 'feelingsholder.render'
      @$el.html @template()
      $('#fs_body').html @$el
    on_more: (event) ->
      @model.fetch()
    unrender: ->
      super()
      @$el.empty()
      $('#fs_body').empty()

  class NewCommentView extends FsView
    className: 'new_comment'
    events:
      'click .fs_submit': 'on_submit'
    template: _.template($('#tpl_new_comment').html())
    render: ->
      console.log 'newcomment.render'
      @$el.html @template()
      @
    on_submit: (event) -> 
      alert 'not implemented'
    unrender: ->
      super()
      @$el.empty()

  class ReceivedFeelingView extends FsView
    tagName: 'li'
    events:
      'click .icon-comment': 'on_comment'
      'click .icon-heart': 'on_like'
      'click .icon-share-alt': 'on_forward'
    template: _.template($('#tpl_received_feeling').html())
    initialize: ->
      @coment_view = new NewCommentView
      @views.push @coment_view
    render: ->
      console.log 'received.render'
      @$el.addClass('rd6').addClass('_sd0').addClass('card')
      @$el.html @template(@model.toJSON())

      type = @model.get 'type'
      if type
        $('.icon-trans').css 'background-color', '#cccccc'
        if type == 'comment'
          $('.icon-comment').css 'background-color', '#44f9b8'
        if type == 'like'
          $('.icon-heart').css 'background-color', '#44f9b8'
        if type == 'forward'
          $('.icon-share-alt').css 'background-color', '#44f9b8'
        @$el.find('.inputarea').html @coment_view.render().el 
        unless @expanded
          router.views.received.wookmark.apply()
        @expanded = true

      @model.once 'change', @render, @
      @
    on_comment: (event) ->
      @model.set 'type', 'comment'
    on_like: (event) ->
      @model.set 'type', 'like'
    on_forward: (event) ->
      @model.set 'type', 'forward'
    unrender: ->
      super()
      @$el.empty()

  class ReceivedFeelingsView extends FsView
    tagName: 'ul'
    id: 'received_feelings_holder'
    className: 'fs_tiles'
    events:
      'click .fs_more': 'on_more'
    template: _.template($('#tpl_feelings').html())
    initialize: ->
      @wookmark = new Wookmark(@id)
    render: ->
      console.log 'receiveds.render'
      view = new FeelingsHolderView(model: @model)
      @views.push view
      view.render()

      view = new ArrivedFeelingView
      @views.push view
      @$el.append view.render().el

      for m in @model.models
        view = new ReceivedFeelingView(model: m)
        @views.push view
        @$el.append view.render().el

      $('#fs_holder').html @$el
      @wookmark.apply()
      @model.on 'prepend', @on_prepend, @
      @model.on 'concat', @on_concat, @
    on_concat: (list) ->
      console.log 'on_concat'
      @model.models.concat list
      for m in list
        view = new ReceivedFeelingView(model: m)
        @views.push view
        @$el.append view.render().el
      @wookmark.apply()
    on_prepend: (data) ->
      model = new ReceivedFeeling(data)
      @model.models.unshift model
      view = new ReceivedFeelingView(model: model)
      @views.push view
      $('#arrived_feeling').after view.render().el
      @wookmark.apply()
    on_more: (event) ->
      @model.fetch()
    unrender: ->
      super()
      @model.off 'concat'
      @model.off 'prepend'
      @$el.empty()

  class ArrivedFeelingView extends FsView
    tagName: 'li'
    id: 'arrived_feeling'
    events:
      'click #receive_arrived': 'on_receive'
      'click #flipcard': 'on_flip'
    template: _.template($('#tpl_arrived_feeling').html())
    holder_template: _.template($('#tpl_arrived_holder').html())
    initialize: ->
      @model = new ArrivedFeelings
    render: ->
      console.log 'arrived.render'
      console.log @
      console.log @views
      @unrender()
      if @model.length > 0
        @$el.addClass('rd6').addClass('_sd0').addClass('card')
        @$el.html @template(@model.toJSON())
      else
        @$el.addClass('rd6').addClass('card')
        @$el.html @holder_template(router.models.me.toJSON())
      @model.on 'sync', @render, @
      router.models.me.on 'sync', @render, @
      @
    on_receive: (event) ->
      console.log 'receive'
      @model.fetch()
    on_flip: (event) ->
      console.log 'flip'
      model = @model.at 0
      $.ajax
        url: "../api/new_arrived_feelings/#{model.get('id')}"
        type: 'PUT'
        dataType: 'json'
        context: @
        success: (data) ->
          @model.reset()
          router.models.received.trigger 'prepend', data
    unrender: ->
      #super()
      router.models.me.off 'sync', @render
      @model.off 'sync', @render
      @$el.empty()
    
  router = new Router
  $.ajaxSetup
    statusCode:
      401: -> router.draw_login()
      403: -> router.draw_login()
  Backbone.history.start()
