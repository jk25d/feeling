$ ->

  WORDMAP =
    w0: '외롭다'
    w1: '마음아프다'
    w2: '쓸쓸하다'
    w3: '기쁘다'
    w4: '기운차다'
    w5: '기운이없다'
    w6: '우울하다'
    w7: '만족스럽다'
    w8: '걱정된다'
    w9: '삶이힘들다'
    w10: '초조하다'
    w11: '허전하다'
    w12: '무섭다'
    w13: '두렵다'
    w14: '열등감느낀다'
    w15: '의욕이없다'
    w16: '사랑스럽다'
    w17: '소중하다'
    w18: '설레다'
    w19: '즐겁다'
    

  # MODELS

  class Thought extends Backbone.Model
    url: '../api/thoughts'

  class Thoughts extends Backbone.Collection
    model: Thought
    url: '../api/thoughts'
  
  class AllThoughts extends Backbone.Collection
    model: Thought
    url: '../api/allthoughts'

  class Word extends Backbone.Model
    url: '../api/words'

  class Feeling extends Backbone.Model
    url: '../api/allfeelings'
  
  class Feelings extends Backbone.Collection
    model: Feeling
    url: '../api/allfeelings'


  # VIEWS

  class ThoughtsView extends Backbone.View
    tagName: 'ul'
    initialize: ->
      @model.bind 'reset', @render, @
    render: (event) ->
      $('.subtitle').html "MY THOUGHTS"
      for thought in @model.models
        @$el.append new ThoughtView(model: thought).render().el
      @

  class ThoughtView extends Backbone.View
    tagName: 'li'
    template: _.template $('#tpl-thought').html()
    render: (event) ->
      @model.set 'word', WORDMAP[@model.get('word')]
      @$el.html @template(@model.toJSON())
      @

  class WordView extends Backbone.View
    tagName: 'button'
    render: (event) ->
      @$el.addClass 'btn'
      @$el.addClass 'word'
      @$el.attr 'id', @model
      @$el.html WORDMAP[@model]
      @

  class WordsView extends Backbone.View
    tagName: 'div'
    id: 'wordcloud'
    render: (event) ->
      @$el.addClass 'btn-group'
      @$el.attr 'data-toggle', 'buttons-radio'
      for word in @model
        @$el.append new WordView(model: word).render().el
      @

  class NewThoughtView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl-newthought').html()
    events:
      'click #save-btn': 'save'
    initialize: ->
      @model.bind 'reset', @render, @
    render: (event) ->
      $('.subtitle').html "NEW THOUGHT"
      @$el.append @template() 
      @
    save: ->
      console.log $('#wordcloud').children()
      console.log $('#wordcloud').children('.active').attr('id')
      @model.set
        word: $('#wordcloud').children('.active').attr('id')
        feeltxt: $('#feeltxt').val()
        thought: $('#thought').val()
      console.log @model
      unless @model.get('word') && @model.get('feeltxt') && @model.get('thought')
        alert 'fill all inputs'
        return
      console.log 'before save'
      @model.save success: (data) -> 
        window.location.replace '#thoughts'

  class AllThoughtsView extends Backbone.View
    tagName: 'ul'
    initialize: ->
      @model.bind 'reset', @render, @
    render: (event) ->
      $('.subtitle').html "RECEIVED THOUGHTS"
      for thought in @model.models
        @$el.append new ThoughtView(model: thought).render().el
      @
  
  class FeelingView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl-feeling').html()
    render: (event) ->
      @model.set 'word', WORDMAP[@model.get('word')]
      @$el.html @template(@model.toJSON())
      @

  class AllFeelingsView extends Backbone.View
    tagName: 'ul'
    initialize: ->
      @model.bind 'reset', @render, @
    render: (event) ->
      $('.subtitle').html "ALL FEELINGS"
      for feeling in @model.models
        @$el.append new FeelingView(model: feeling).render().el
      @

  class LoginView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl-login').html()
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


  # ROUTER

  $.ajaxSetup
    statusCode:
      401: -> window.location.replace '/#login'
      403: -> window.location.replace '/#login'

  class AppRouter extends Backbone.Router
    routes:
      "": "thoughts"
      "login": "login"
      "logout": "login"
      "thoughts": "thoughts"
      "thoughts/new": "newthought"
      "allthoughts": "allthoughts"
      "allfeelings": "allfeelings"

    login: ->
      $('#content').html(new LoginView({}).render().el)

    logout: ->
      $.ajax
        url: '../api/logout'
        dataType: 'json'
        success: (data) ->
          window.location.replace '/#login'

    thoughts: ->
      console.log 'thoughts'
      @thoughts = new Thoughts
      @thoughts.fetch success: (model, res) ->
        $('#content').html(new ThoughtsView(model: model).render().el)

    newthought: ->
      $('#content').html(new WordsView(model: Object.keys(WORDMAP)).render().el)
      @thought = new Thought
      @thought.fetch success: (model, res) ->
        $('#content').append(new NewThoughtView(model: model).render().el)

    allthoughts: ->
      @thoughts = new AllThoughts
      @thoughts.fetch success: (model, res) ->
        $('#content').html(new AllThoughtsView(model: model).render().el)
    
    allfeelings: ->
      @feelings = new Feelings
      @feelings.fetch success: (model, res) ->
        $('#content').html(new AllFeelingsView(model: model).render().el)

  new AppRouter
  Backbone.history.start()
