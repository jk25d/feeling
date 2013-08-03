$ ->

  WORDS =
    w0:  {w: '외롭다',      c: '#00ccff'}
    w1:  {w: '마음아프다',  c: '#3399ff'}
    w2:  {w: '쓸쓸하다',    c: '#9966ff'}
    w3:  {w: '기쁘다',      c: '#ff00ff'}
    w4:  {w: '기운차다',    c: '#ff3399'}
    w5:  {w: '기운이없다',  c: '#ff0066'}
    w6:  {w: '우울하다',    c: '#ff6600'}
    w7:  {w: '만족스럽다',  c: '#ff9933'}
    w8:  {w: '걱정된다',    c: '#ffcc00'}
    w9:  {w: '삶이힘들다',  c: '#33cc33'}
    w10: {w: '초조하다',    c: '#00cc66'}
    w11: {w: '허전하다',    c: '#009999'}
    w12: {w: '무섭다',      c: '#336699'}
    w13: {w: '두렵다',      c: '#cc00ff'}
    w14: {w: '열등감느낀다',c: '#660033'}
    w15: {w: '의욕이없다',  c: '#993333'}
    w16: {w: '사랑스럽다',  c: '#df0000'}
    w17: {w: '소중하다',    c: '#993300'}
    w18: {w: '설레다',      c: '#996600'}
    w19: {w: '즐겁다',      c: '#666633'}
    

  #### MODELS ####

  class Word extends Backbone.Model
    url: '../api/daily_words'

  class Feeling extends Backbone.Model
    url: '../api/feelings'

  class Comment extends Backbone.Model
    url: '../api/comments'

  class FloatFeeling extends Backbone.Model
    url: '../api/float_feelings'
  
  class FloatFeelingComment extends Backbone.Model
    url: "../api/float_feelings/#{id}/comment"

  class Feelings extends Backbone.Collection
    model: Feeling
    url: ../api/feelings'

  class Comments extends Backbone.Collection
    model: Comment
    url: ../api/comments'

  class FloatFeelings extends Backbone.Collection
    model: FloatFeeling
    url: ../api/float_feelings'



  #### VIEWS ####

  class WordView extends Backbone.View
    tagName: 'button'
    render: (event) ->
      @$el.addClass 'btn'
      @$el.addClass 'word'
      @$el.attr 'id', @model.id
      @$el.css 'color', @model.c
      @$el.html @model.w
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

  class NewFeelingView extends Backbone.View
    tagName: 'div'
    template: _.template $('#tpl-new-feeling').html()
    events:
      'click #save-btn': 'save'
      'click .word': 'toggle'
    initialize: ->
      @model.bind 'reset', @render, @
    render: (event) ->
      $('.subtitle').html "NEW FEELING"
      @words = Object.keys(WORDS).map (k) -> WORDS[k].id = k
      $('.words').html new WordsView.render(model: @words).el
      @$el.append @template() 
      @
    toggle: ->
      t = $('#wordcloud').children('.active').attr('id')
      $('#content').val t
    save: ->
      @model.set
        word_id: $('#wordcloud').children('.active').attr('id')
        content: $('#content').val()
      unless @model.get('word_id') && @model.get('feeltxt')
        alert 'fill all inputs'
        return
      @model.save {}, success: (data) -> 
        window.location.replace '#feelings'

  class FeelingsView extends Backbone.View
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


  #### ROUTER ####

  $.ajaxSetup
    statusCode:
      401: -> window.location.replace '/#login'
      403: -> window.location.replace '/#login'

  class AppRouter extends Backbone.Router
    routes:
      "": "feelings"
      "login": "login"
      "logout": "logout"
      "feelings": "feelings"
      "feelings/new": "new_feelings"
      "feelings/:id": "show_feelings"
      "float_feelings": "float_feelings"

    login: ->
      $('#content').html(new LoginView({}).render().el)

    logout: ->
      $.ajax
        url: '../api/logout'
        dataType: 'json'
        success: (data) ->
          window.location.replace '/#login'

    new_feelings: ->
      $('#content').html new WordsView(model: Object.keys(WORDS)).render().el
      @feeling = new Feeling
      $('#content').html new NewFeelingView(model: @feeling).render().el

    feelings: ->
      @feelings = new Feelings
      @feelings.fetch 
        data: {mon: 8, n: 3}
        success: (model, res) ->
          $('#content').html new FeelingsView(model: model).render().el

    show_feelings: (id) ->
      @feeling = new Feeling
      @feeling.fetch 
        data: {id: id} 
        success: (model, res) ->
          $('#content').html new FeelingDetailView(model: model).render().el
    
    float_feelings: ->
      @float_feelings = new FloatFeelings
      @float_feelings.fetch success: (model, res) ->
        $('#content').html new FloatFeelingsView(model: model).render().el

  new AppRouter
  Backbone.history.start()
