$ ->

  #### UTIL_FUNC ####

  wookmark = ->
    $('#fs_tiles > li').wookmark
      align: 'left'
      autoResize: true
      container: $('#fs_tiles')
      offset: 16
      itemWidth: 226

  draw_login = ->
    $('#fs_navbar').html new NavBarView(model: new NavBar()).render().el
    $('#fs_header').html new LoginView().render().el
    $('#fs_content').empty()

  draw_header = ->
    $('#fs_header').html new HeaderHolderView().render().el
    $('#fs_header_write').html new NewFeelingView().render().el
    $('#wordselect > li').on 'click', (event) ->
      $('#wordselect').find('.active').removeClass 'active' 
      $(@).addClass 'active'
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

  class LiveFeelings extends Backbone.Model
    url: '../api/live_feelings'

  class Associate extends Backbone.Model

  class Associates extends Backbone.Collection
    model: Associate
    url: '../api/associates'

  class MyFeeling extends Backbone.Model

  class MyFeelings extends Backbone.Collection
    model: MyFeeling
    url: '../api/my_feelings'

  class NewArrivedFeeling extends Backbone.Model

  class NewArrivedFeelings extends Backbone.Collection
    model: NewArrivedFeeling
    url: '../api/new_arrived_feelings'

  class ReceivedFeeling extends Backbone.Model

  class ReceivedFeelings extends Backbone.Collection
    model: ReceivedFeeling
    url: '../api/received_feelings'


  #### VIEWS ####

  class NewArrivedFeelingView extends Backbone.View
    tagName: 'li'
    template: _.template $('#tpl_associates').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class MyFeelingView extends Backbone.View
    tagName: 'li'
    template: _.template $('#tpl_my_feeling').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class MyFeelingsView extends Backbone.View
    tagName: 'ul'
    className: 'contentwrap'
    render: (event) ->
      $('#fs_title').html "MY FEELINGS"
      for feeling in @model.models
        @$el.append new FeelingView(model: feeling).render().el
      @

  class FeelingView extends Backbone.View
    tagName: 'li'
    template: _.template $('#tpl_received_feeling').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class FeelingsView extends Backbone.View
    tagName: 'ul'
    className: 'contentwrap'
    render: (event) ->
      $('#fs_title').html "RECEIVED FEELINGS"
      for feeling in @model.models
        @$el.append new FeelingView(model: feeling).render().el
      @

  class AssociateView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_associates').html()
    render: (event) ->
      @$el.html @template(@model.toJSON())
      @

  class AssociatesView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl_associates').html()
    render: (event) ->
      for asso in @model.models
        @$el.append new AssociateView(model: asso).render().el
      @

  class LiveFeelingsView extends Backbone.View
    tagName: 'ul'
    className: 'wordcloud'
    render: (event) ->
      for word, n of @model.attributes
        @$el.append "<li>#{word}</li>"
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
    events: 
      'click #new_feeling_submit': 'submit'
    render: (event) ->
      @$el.html @template()
      @
    submit: (event) ->
      $.ajax
        url: '../api/my_feelings'
        type: 'POST'
        dataType: 'json'
        data:
          word_id: $('#wordselect').find('.active').attr('word-id')
          content: $('#new_feeling_content').val()
        success: (data) ->
          window.location.replace '#my_feelings'

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
      navbar = new NavBar
      navbar.fetch
        success: (model, res) ->
          model.set 'menu', 'my'
          $('#fs_navbar').html new NavBarView(model: model).render().el
          draw_header()

          feelings = new MyFeelings
          feelings.fetch
            success: (model,res) ->
              $('#fs_content').html new MyFeelingsView(model:model).render().el
              wookmark()

    received_feelings: ->
      navbar = new NavBar
      navbar.fetch
        success: (model, res) ->
          model.set 'menu', 'received'
          $('#fs_navbar').html new NavBarView(model: model).render().el
          draw_header()

          feelings = new ReceivedFeelings
          feelings.fetch
            success: (model,res) ->
              $('#fs_content').html new FeelingsView(model:model).render().el
              wookmark()


          

  new AppRouter
  Backbone.history.start()

  


