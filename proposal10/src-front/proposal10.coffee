$ ->

  #### UTIL_FUNC ####

  wookmark = ->
    $('#tiles > li').wookmark
      align: 'left'
      autoResize: true
      container: $('#tiles')
      offset: 10
      itemWidth: 230

  draw_login = ->
    $('#fs_navbar').html new NavBarView(model: new NavBar()).render().el
    $('#fs_header').html new LoginView().render().el

  draw_header = ->
    $('#fs_header').html new HeaderHolderView().render().el
    $('#fs_header_write').html new NewFeelingView().render().el
    me = new Me
    me.fetch
      success: ->
        $('#fs_header_me').html new MeView(model: me).render().el
    feelings = new LiveFeelings
    feelings.fetch
      success: ->
        $('#fs_header_live_feelings').html new LiveFeelingsView(model: feelings).render().el
    associates = new Associates
    associates.fetch
      success: ->
        $('#fs_header_associates').html new AssociatesView(model: associates).render().el


  #### MODELS ####

  ## NavBar ##

  class NavBar extends Backbone.Model
    defaults:
      menu: 'login'
    url: '../sessions'

  ## Header ##

  class Me extends Backbone.Model
    url: '../api/me'

  class LiveFeeling extends Backbone.Model

  class LiveFeelings extends Backbone.Collection
    model: LiveFeeling
    url: '../api/live_feelings'

  class Associate extends Backbone.Model

  class Associates extends Backbone.Collection
    model: Associate
    url: '../api/associates'


  #### VIEWS ####

  class AssociatesView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_associates').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class LiveFeelingsView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_live_feelings').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class MeView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_me').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class NewFeelingView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_new_feeling').html()
    render: (event) ->
      @$el.html @template()
      @

  class HeaderHolderView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_header_holder').html()
    render: (event) ->
      @$el.html @template()
      @

  class NavBarView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_navbar').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class LoginView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_login').html()
    events:
      'click #login_btn': 'login'
    render: (event) ->
      @$el.html @template()
      @
    login: (event) ->
      $.ajax
        url: '../sessions'
        type: 'POST'
        dataType: 'json'
        data:
          user_id: $('#user_id').val()
          password: $('#password').val()
        success: (data) ->
          window.location.replace '/'


  #### ROUTER ####

  $.ajaxSetup
    statusCode:
      401: -> draw_login()
      403: -> draw_login()

  class AppRouter extends Backbone.Router
    routes:
      "": "received_feelings"
      "logout": "logout"
      "signup": "signup"
      "my_feelings": "my_feelings"
      "received_feelings": "received_feelings"
    logout: ->
      $.ajax
        url: '../sessions'
        type: 'DELETE'
        dataType: 'json'
        success: (data) -> draw_login()
    signup: ->
      window.location.replace '/'
    my_feelings: ->
      window.location.replace '/'
    received_feelings: ->
      navbar = new NavBar
      navbar.fetch
        success: (model, res) ->
          model.set 'menu', 'received'
          $('#fs_navbar').html new NavBarView(model: model).render().el
          draw_header()

  new AppRouter
  Backbone.history.start()

  $('#wordselect > li').on 'click', (event) ->
    $('#wordselect').find('.active').removeClass 'active' 
    $(@).toggleClass 'active'


