wookmark = ->
  $('#tiles > li').wookmark
    align: 'left'
    autoResize: true
    container: $('#tiles')
    offset: 10
    itemWidth: 230

$ ->

  #### VIEWS ####

  class HeaderView extends Backbone.View
    tagName: 'div'
    class: 'container'
    template: _.template $('#tpl_header').html()
    render: (event) ->
      @$el.html @template()
      @

  class LoginView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_login').html()
    events:
      'click #login-btn': 'login'
    render: (event) ->
      @$el.html @template()
      @
    login: (event) ->
      $.ajax
        url: '../login'
        type: 'POST'
        dataType: 'json'
        data:
          userid: $('#userid').val()
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
      $('#_header').html new HeaderView(user:false).render().el
      $('#_content').html new LoginView({}).render().el
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
      alert 'ur'

  new AppRouter
  Backbone.history.start()
  #wookmark() 

  $('#wordselect > li').on 'click', (event) ->
    $('#wordselect').find('.active').removeClass 'active' 
    $(@).toggleClass 'active'


