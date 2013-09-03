data
----


rest api
--------

/
login
/api/logout
/api/daily_words GET
  {w1:1, w2:10, ...}
/api/feelings GET        [mon=8],[n=10]
  [{id:x, time:x, word_id:x, content:x, comments: [id,id,id]}, ...]
/api/feelings POST       {word_id:x, content:x}
/api/feelings/:id GET
  feeling: {id:x, time:x, word_id:x, content:x, comments: [
    {id: {user:x, time:x, word_id:x, keep:x}, ... ]
/api/comments/:id PUT 간직하기
/api/comments GET     [skip=x, n=10]
  comments: [{id, user, time, word_id, keep, feeling: {user,time, word_id,content} }, ...]
/api/float_feelings GET
  float_feelings: [ {id, nforward, user, time, word_id, content} ]
/api/float_feelings/:id PUT   //forward
/api/float_feelings/:id/comments POST



## express.js before filter

myAuthMiddleware = (req, res, next) ->
  if not req.session.user?
    res.redirect "/"
  else
    next()

app.use(myAuthMiddleware, func) for func in [editPhoto, deletePhoto]


## backbone.js authentication

http://clintberry.com/2012/backbone-js-apps-authentication-tutorial/

$.ajaxSetup({
    statusCode: {
        401: function(){
            // Redirec the to the login page.
            window.location.replace('/#login');
         
        },
        403: function() {
            // 403 -- Access denied
            window.location.replace('/#denied');
        }
    }
});


tile layout
--------

http://www.wookmark.com/jquery-plugin         # MIT, 1.4.2, 15k(6k)
https://github.com/xlune/jQuery-vGrid-Plugin	# MIT, 0.1.11, 9.7k, has delay if reduce size
http://yconst.com/web/freetile/		            # MIT, 0.3.1, 30k(12k)
https://github.com/thinkpixellab/tilesjs      # MIT, , 21k
http://masonry.desandro.com/		              # MIT, 3.1.1, 70k(24k)

http://www.inwebson.com/demo/blocksit-js/  # no responsive?
http://isotope.metafizzy.co/		# commercial license
http://jsonenglish.com/projects/flex/         # no dynamic alignment


css structure
-------------

fonts
  h1: 28px/34px, What is your ..
  h2: 16px, 실시간 느낌, myidid(strong)
  h3: ..
  h4: sz12 -- default
  h5: sz11
  h6: color: grey, size:11

box main
  header0
  content0-header
  content0-content
  content0-input
  header1
  content1
  content2
  content3-header
  content3-content

box feel
  inner
    header
    content
  comments
    content0
    content1

routes
------

my
ur
login
signup


rest
----
/info
  words: [ { 'id': { desc: '', color: ''} } ]
  live_words: [ {'id': 'n'} ]
  available_feels: 'n'
  similar_users: [ {user_id: '', similarity: '', word_id: ''} ]

/my
  [ {time: '', user_id: '', content: '', comments: [
    {type: '', content: '', user_id: '', time: '', liked: ''} ] ]

/ur
  [ {time: '', user_id: '', content: '', comments: [
    {type: '', content: '', user_id: '', time: ''} ] ]

view
-----

header
  - default, my, ur, logout
  - default, signup

MainCardView
  - WordsView
    - WordView
MyFeelCardsView
  - MyFeelCardView
    - CommentsView
      - CommentView
UrFeelCardsView
  - UrFeelCardView
    - ReplyView


flow
-----

--> * --> loggedin? --> next()
      --> not loggin --> 401 --> index.html#login

#login --> LoginView, HeaderView(false) --> post /sessions  --> #
#signup --> SignupView, HeaderView(false)  --> post /users  --> #login

# --> #ur
#ur --> HeaderView
        info.fetch.InfoCardView --> post /feels --> #my
        ur_feels.fetch.UrFeelCardsView --> post /feels/:id/comments
#my --> HeaderView, 
        info.fetch.InfoCardView
        my_feels.fetch.MyFeelCardsView --> put /feels/:id/comments/:id


post /sessions, user_id, password
del /sessions
post /users, user_id, password

get /
  401 or redirect to /ur
get /auth/info
  words: { 'id': { desc: '', color: ''} }
  live_words: [ {'id': 'n'} ]
  available_feels: 'n'
  similar_users: [ {user_id: '', similarity: '', word_id: ''} ]
get /auth/my, skip=?, n=?
  [ {id: '', time: '', user_id: '', word_id: '', content: '', comments: [
    {id: '', type: '', content: '', user_id: '', time: '', liked: ''} ] ]
get /auth/ur, skip=?, n=?
  [ {id: '', time: '', user_id: '', word_id: '', content: '', comment: [
    {id: '', type: '', content: '', user_id: '', time: ''} ] ]
get /auth/ur/news, 
  [ {id: '', time: '', user_id: '', word_id: '', content: '', comments: [
    {type: '', content: '', user_id: '', time: ''} ] ]
post /auth/feels/:id/comments, type(heart/comment/forward), content
put /auth/feels/:id/comments/:comment_id, likeit(t/f)


0901
====


layout
-----

<div> <!-- header background -->
  <div>... 
    <div id='fs_navbar' class='container'></div> 
  ...</div>
  <div class='container'>
    <div id='fs_header' class='row'></div>
  </div>
</div>

<div class='fs_container'>
  <div id='fs_title'></div>
  <ul id='fs_tiles'></ul>
</div>


flow
-----

draw_login = ->
  $('#fs_navbar').html new NavBarView(model: null).render().el
  $('#fs_header').html new LoginView().render().el

draw_header = ->
  $('#fs_header').html new HeaderHolderView().render().el
  $('#fs_header_write').html new HeaderHolderView().render().el
  get /api/me ->
    $('#fs_header_me').html new MeView().render().el
  get /api/live_feelings -->
    $('#fs_header_live_feelings').html new LiveFeelingsView().render().el
  get /api/associates -->
    $('#fs_header_associates').html new AssociatesView().render().el

401, 403 --> draw_login()

/api/* --> 401 --> draw_login()
# --> #received_feelings
#logout --> delete /sessions --> draw_login()
#received_feelings 
  --> get /sessions -> 
    $('#fs_navbar').html new NavBarView(model: model).render().el
    draw_header()
    get /api/new_arrived_feeling ->
      $('#tiles').prepend new NewFeelingView(model:model).render().el
      get /api/received_feelings -> 
        $('#tiles').html new FeelingsView(model:model).render().el
        wookmark()
#my_feelings
  --> get /sessions -> 
    $('#fs_navbar').html new NavBarView(model: model).render().el
    draw_header()
    get /api/my_feelings -> 
      $('#tiles').html new MyFeelingsView(model:model).render().el
      wookmark()
#event: new_feeling
  --> post /api/my_feelings ->
    window.location.replace '/#my_feelings'
#event: new_comment
  --> post /api/received_feelings/:id/comments ->
    get /api/received_feelings/:id ->
      model.set 'expand', true
      $("#feeling_#{id}").html new FeelingView(model:model).render().el
#event: update_my_feeling_comment
  --> put /api/my_feelings/:id/comments ->
    get /api/my_feelings/:id ->
      model.set 'expand', true
      $("#feeling_#{id}").html new MyFeelingView(model:model).render().el
#event: new_session
  --> post /sessions --> #
    

api
---

get /sessions
post /sessions
del /sessions
post /users

get /api/live_feelings
get /api/associates
get /api/me

get /api/received_feelings, skip=?, n=?
  [ {..., comment: [] } ]
get /api/my_feelings, skip=?, n=?
  [ {..., comments: [] } ]
get /api/received_feelings/:id
get /api/my_feelings/:id
get /api/new_arrived_feelings
  {...}
put /api/new_arrived_feelings/:id

post /api/my_feelings
post /api/received_feelings/:id/comments
put /api/my_feelings/:id/comments



design
------

<div class='header_wrap'>
  <div id='navbar'></div>
  <div id='header'></div>
</div>
<div id='body'></div>

------------- tpl_navbar
<ul>
  <li class='menu public'><a href='#login'>LOGIN</a></li>
  <li class='menu public'><a href='#signup'>SIGNUP</a></li>
  <li class='menu private'><a href='#my_feelings'></a>MY</li>
  <li class='menu private'><a href='#received_feelings'>RECEIVED</a></li>
  <li class='dropdown'>
    <ul><li class='private'><a href='#logout'></a></li></ul>
  </li>
</ul>

-----------------------------------------

class Wookmark
  apply:
    @handler?.wookmarkInstance?.clear()
    @handler = $('#tiles>li')
    @handler.wookmark
      align: 'left'
      autoResize: true
      container: $('#fs_tiles')
      offset: 16
      itemWidth: 226   
  
wookmark = new Wookmark
router = new Router
Backbone.history.start({pushState: true})
$.ajaxSetup
  statusCode:
    401: -> router.draw_login()
    403: -> router.draw_login()


class Router
  routes:
    '': 'received_feelings'
    'logout': 'logout'
    'signup': 'signup'
    'my_feelings': 'my_feelings'
    'received_feelings': 'received_feelings'
  views: {}
  active_views: {}
  initialize: ->
    _.bindAll @, unrender, logout, signup, login, my_feelings, received_feelings

    @views.login = new LoginView()
    @views.signup = new SignupView()
    @views.new_feeling = new NewFeelingView()
    @views.my_feelings = new MyFeelingsView()
    @views.received_feelings = new ReceivedFeelingsView()

    @app_view = new AppView

    router.navigate '#received_feelings', true
  unrender:
    while @active_views.length > 0
      @active_views.pop().unrender()
  draw_login:
    @unrender()
    @app_view.app.set {user: null, menu: '#login'}
    @views.login.render()
    @active_views.push @views.login
  logout:
    $.ajax
      url: '../sessions'
      type: 'DELETE'
      dataType: 'json'
      success: (data) -> @draw_login()
  signup:
    @unrender()
    @app_view.fetch('signup')
    @views.signup.render()
    @active_views.push @views.signup
  my_feelings:  
    @unrender()
    @app_view.fetch('my_feelings')
    @views.new_feeling.fetch()
    @views.my_feelings.fetch()
    @active_views.push @views.new_feeling
    @active_views.push @views.my_feelings
  received_feelings:
    @unrender()
    @app_view.fetch('received_feelings')
    @views.new_feeling.fetch()
    @views.received_feelings.fetch()
    @active_views.push @views.new_feeling
    @active_views.push @views.received_feelings

class FsView extends Backbone.View
  unrender: ->
  fetch: -> @render()

class App extends Backbone.Model
  defaults:
    user: null
    menu: '#login'
  url: '../sessions'

class AppView extends FsView
  template: _.template($('#tpl_navbar').html())
  initialize: ->
    _.bindAll @, 'update', 'fetch'
    @app = new App
    @app.on 'change', @update, @
    $('#navbar').html @template(@app.toJSON())
  update: ->
    $('#navbar .menu').removeClass 'active'
    $(@app.get('menu')).addClass 'active'
    $('.public').hide() if user
    $('.private').show() if user
    $('.private').hide() unless user
    $('.public').hide() unless user
  fetch: (menu) ->
    @app.off 'change'
    @app.set 'menu': menu || '#login'
    @app.on 'change', @update, @
    @app.fetch ->
      success: (model, res) ->
        @app.set user: model.get('user')
      error: ->
        @app.unset 'user'

class LoginView extends FsView
  events:
    'click #tpl_login .submit': 'login'
  template: _.template($('#tpl_login').html())
  render: ->
    $('#header').html @template()
  login: ->
    $.ajax
      url: '../sessions'
      type: 'POST'
      dataType: 'json'
      data:
        user_id: $('#user_id').val()
        password: $('#password').val()
      success: (data) ->
        router.navigate '', true

class SignupView extends FsView



class NewFeelingView extends FsView
  events:
    'click #header .submit': 'new_feeling'
  template: _.template($('#tpl_new_feeling').html())
  me_template: _.template($('#tpl_me').html())
  live_feeling_template: _.template($('#tpl_live_feeling').html())
  associates_template: _.template($('#tpl_associates').html())
  initialize: ->
    _.bindAll @, 'fetch'
  fetch: ->
    $('#header').html @template()
    $.getJSON '../api/me', (data) ->
      $('#header_me').html @me_template(JSON.stringify(data))
    $.getJSON '../api/live_feelings', (data) ->
      $('#header_live_feeling').html @live_feeling_template(JSON.stringify(data))
    $.getJSON '../api/associates', (data) ->
      $('#header_associates').html @associates_template(JSON.stringify(data))
  new_feeling: ->
    $.ajax
      url: '../api/my_feelings'
      type: 'POST'
      dataType: 'json'
      data:
        word_id: $('#wordselect').find('.active').attr('word-id')
        content: $('#new_feeling_content').val()
      success: (data) ->
        router.navigate 'my_feelings', true

class Comment extends Backbone.Model

class CommentView extends FsView
  events:
    'click .comments .remove': 'remove'
    'click .comments .like': 'like'
  template: _.template($('#tpl_comment').html())
  render: ->
    @$el.html @template(@model.toJSON())
    @
  remove: -> alert 'not implemented'
  like: -> alert 'not implemented'

class MyFeelingView extends FsView
  tagName: 'li'
  events:
    'click .comments': 'expand'
  template: _.template($('#tpl_my_feeling').html())
  render: ->
    @$el.html @template(@model.toJSON())
    @
  expand: (event) ->
    return if @model.get('comments').length == 0
    holder = $(event.target)
    holder.empty()
    for data in @model.get('comments')
      holder.append new CommentView(model: new Comment(data)).render().el

class MyFeeling extends Backbone.Model

class MyFeelings extends Backbone.Collection
  model: MyFeeling
  url: '../api/my_feelings'

class MyFeelingsView extends FsView
  tagName: 'ul'
  id: 'tiles'
  events:
    'click #more': 'fetch'
  template: _.template($('#tpl_my_feelings').html())
  initialize: ->
    _.bindAll @, 'concat', 'fetch'
    @collection = []
    $('#body').html(@$el)
  concat: (list) ->
    @collection.concat list
    for model in list
      @$el.append new MyFeelingView(model: model).render().el
    wookmark.apply()
  fetch: ->
    new MyFeelings().fetch
      data:
        skip: @collection.length
        n: 10
      success: (model, res) ->
        @concat model.models

class NewComment extends Backbone.Model      

class NewCommentView extends FsView
  className: 'new_comment'
  events:
    'click .comment_submit': 'submit'
  template: _.template($('#tpl_new_comment').html())
  render: ->
    @$el.html @template(@model.toJSON())
    @
  submit: -> alert 'not implemented'

class ReceivedFeeling extends Backbone.Model

class ReceivedFeelings extends Backbone.Collection
  model: ReceivedFeeling
  url: '../api/received_feelings'

class ReceivedFeelingView extends FsView
  tagName: 'li'
  events:
    'click .comment_link': 'comment'
    'click .like_link': 'like'
    'click .forward_link': 'forward'
  template: _.template($('#tpl_received_feeling').html())
  initialize: ->
    _.bindAll @, 'draw_new_comment'
  render: ->
    @$el.html @template(@model.toJSON())
    @
  comment: (event) ->
    @draw_new_comment new NewComment({type: 'comment'})
  like: (event) ->
    @draw_new_comment new NewComment({type: 'like'})
  forward: (event) ->
    @draw_new_comment new NewComment({type: 'forward'})
  draw_new_comment: (comment) ->
    $(event.target).find('.inputarea').html new NewCommentView(model: comment).render().el  

class ReceivedFeelingsView extends FsView
  tagName: 'ul'
  id: 'tiles'
  events:
    'click #more': 'fetch'
  template: _.template($('#tpl_received_feelings').html())
  initialize: ->
    _.bindAll @, 'concat', 'fetch', 'prepend'
    @collection = []
    @collection.on 'prepend', @prepend, @
    @$el.append new ArrivedFeelingView.render().el
    $('#body').html(@$el)
  concat: (list) ->
    @collection.concat list
    for model in list
      @$el.append new ReceivedFeelingView(model: model).render().el
    wookmark.apply()
  prepend: (model) ->
    @collection.unshift model
    $('#arrived_feeling').after new ReceivedFeelingView(model: model).render().el
    wookmark.apply()
  fetch: ->
    new ReceivedFeelings().fetch
      data:
        skip: @collection.length
        n: 10
      success: (model, res) ->
        @concat model.models
  unrender: ->
    @collection.off 'prepend'

class ArrivedFeelingView extends FsView
  tagName: 'li'
  id: 'arrived_feeling'
  events:
    'click .holder': 'fetch'
    'click .backside': 'flip'
  template: _.template($('#tpl_arrived_card_holder').html())
  initialize: ->
    @data = new ArrivedFeelingHolder()
  render: ->
    @$el.html @template(@data.toJSON())
    @
  fetch: (event) ->
    @data.fetch
      success: (model, res) -> @render()
  flip: (event) ->
    @data.save
      data:
        id: @data.get('id')
      success: (model, res) ->
        router.views.received_feelings?.collection.unshift model
        router.views.received_feelings?.collection.trigger 'prepend', model



