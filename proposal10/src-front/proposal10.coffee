wookmark = ->
  $('#tiles > li').wookmark
    align: 'left'
    autoResize: true
    container: $('#tiles')
    offset: 10
    itemWidth: 230

$ ->

  #### MODELS ####

  class Header extends Backbone.Model
    default:
      loggedin: false
      menu: 'login'

  class Info extends Backbone.Model
    url: '../auth/info'

  class UrFeel extends Backbone.Model

  class UrFeels extends Backbone.Collection
    model: UrFeel
    url: '../auth/ur'

  #### VIEWS ####

  class UrFeelCardView extends Backbone.View
    tagName: 'li'
    template: _.template $('#tpl_ur_feel_card').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class CardHolderView extends Backbone.View
    tagName: 'ul'
    template: _.template $('#tpl_card_holder').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class HeaderView extends Backbone.View
    tagName: 'div'
    className: 'container'
    template: _.template $('#tpl_header').html()
    render: (event) ->
      console.log @model
      console.log @model.toJSON()
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
          window.location.replace '#'


  #### ROUTER ####

  $.ajaxSetup
    statusCode:
      401: -> window.location.replace '/#login'
      403: -> window.location.replace '/#login'

  class AppRouter extends Backbone.Router
    routes:
      "": "ur"
      "login": "login"
      "logout": "logout"
      "signup": "signup"
      "my": "my"
      "ur": "ur"
    login: ->
      $.ajax
        url: '../sessions'
        dataType: 'json'
        success: (data) ->
          if data.user
            window.location.replace '/'
          else
            h = new Header
            h.set {loggedin: false, menu: 'login'}
            $('#_header').html new HeaderView(model: h).render().el
            $('#_content').html new LoginView(model: data).render().el            

    logout: ->
      $.ajax
        url: '../sessions'
        type: 'DELETE'
        dataType: 'json'
        success: (data) ->
          window.location.replace '/#login'
    signup: ->
      window.location.replace '/#login'
    my: ->
      window.location.replace '/#login'
    ur: ->
      info = new Info
      info.fetch
        success: (model, res) ->
          feels = new UrFeels
          feels.fetch
            data: {skip:0, n:3}
            success: (model, res) ->
              for feel in model.models
                console.log feel
                $('#tiles').append new UrFeelCardView(model: feel).render().el
              wookmark()
          h = new Header
          h.set {loggedin: true, menu: 'ur'}
          $('#_header').html new HeaderView(model: h).render().el
          $('#_content').html new CardHolderView(model: model).render().el


  new AppRouter
  Backbone.history.start()

  $('#wordselect > li').on 'click', (event) ->
    $('#wordselect').find('.active').removeClass 'active' 
    $(@).toggleClass 'active'


