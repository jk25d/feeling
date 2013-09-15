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


## backbone.js page transition.. unrender.. event unbind..
http://lostechies.com/derickbailey/2011/09/15/zombies-run-managing-page-transitions-in-backbone-apps/

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

<div>
  <div id='fs_navbar'></div>
  <div id='fs_header'></div>
</div>
<div id='fs_body'></div>

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
  apply: (id) ->
    @handler?.wookmarkInstance?.clear()
    @handler = $("##{id}>ul>li")
    @handler.wookmark
      align: 'left'
      autoResize: true
      container: $("##{id}>ul")
      offset: 16
      itemWidth: 226   

class Router
  routes:
    '': 'received_feelings'
    'logout': 'logout'
    'signup': 'signup'
    'my_feelings': 'my_feelings'
    'received_feelings': 'received_feelings'
  views: {}
  active_views: []
  models: {}
  initialize: ->
    _.bindAll @, unrender, logout, signup, draw_login, my_feelings, received_feelings

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
    @views.my_feelings = new MyFeelingsView(model: @models.my)
    @views.received_feelings = new ReceivedFeelingsView(model: @models.received)

    @app_view = new AppView
    @app_view.render()

    router.navigate '#received_feelings', true
  unrender: ->
    while @active_views.length > 0
      @active_views.pop().unrender()
  draw_login: ->
    @unrender()
    @app_view.model.set {user: null, menu: '#login'}
    @views.login.render()
    @active_views.push @views.login
  logout: ->
    $.ajax
      url: '../sessions'
      type: 'DELETE'
      dataType: 'json'
      success: (data) -> @draw_login()
  signup: ->
    @unrender()
    @views.signup.render()
    @active_views.push @views.signup

    @app_view.model.set {menu: '#signup'}
  my_feelings: ->
    @unrender()
    @views.new_feeling.render()
    @views.my_feelings.render()
    @active_views.push @views.new_feeling
    @active_views.push @views.my_feelings

    @app_view.model.fetch()
    @app_view.model.set {menu: '#my_feelings'}
    @models.me.fetch()
    @models.live_feelings.fetch()
    @models.associates.fetch()
    @models.my.fetch()
  received_feelings: ->
    @unrender()
    @views.received_feelings.render()
    @active_views.push @views.new_feeling
    @active_views.push @views.received_feelings

    @app_view.model.fetch()
    @app_view.model.set {menu: '#received_feelings'}
    @models.me.fetch()
    @models.live_feelings.fetch()
    @models.associates.fetch()
    @models.received.fetch()


##### MODELS #####

class App extends Backbone.Model
  defaults:
    user: null
    menu: '#login'
  url: '../sessions'  
class Me extends Backbone.Model
  url: '../api/me'
class LiveFeeling extends Backbone.Model
class LiveFeelings extends Backbone.Collection
  model: LiveFeeling
  url: '../api/live_feelings'
class Associates extends Backbone.Model
  url: '../api/associates'

class Comment extends Backbone.Model
class MyFeeling extends Backbone.Model
class MyFeelings extends Backbone.Collection
  model: MyFeeling
  url: '../api/my_feelings'
  fetch:
    data:
      skip: @.models.length
      n: 10
    success: (model, res) ->
      @.trigger 'concat', model.models

class ArrivedFeeling extends Backbone.Model
class ArrivedFeelings extends Backbone.Collection
  model: ArrivedFeeling
  url: '../api/new_arrived_feelings'
class NewComment extends Backbone.Model      
class ReceivedFeeling extends Backbone.Model
class ReceivedFeelings extends Backbone.Collection
  model: ReceivedFeeling
  url: '../api/received_feelings'
  fetch:
    data:
      skip: @.models.length
      n: 10
    success: (model, res) ->
      @.trigger 'concat', model.models

##### VIEWS #####

class FsView extends Backbone.View
  views: []
  unrender: ->
    while @views.length > 0
      @views.pop().unrender()

class AppView extends FsView
  template: _.template($('#tpl_navbar').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    $('#fs_navbar').html @template(@app.toJSON())
    $('#fs_navbar .fs_menu').removeClass 'active'
    $(@model.get('menu')).addClass 'active'
    @model.off 'change'
    @model.on 'change', @render, @
  unrender: ->
    @model.off 'change'
    $('#fs_navbar').empty()

class LoginView extends FsView
  events:
    'click .fs_submit': 'on_submit'
  template: _.template($('#tpl_login').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    $('#fs_header').html @template()
  on_submit: ->
    $.ajax
      url: '../sessions'
      type: 'POST'
      dataType: 'json'
      data:
        user_id: $('#user_id').val()
        password: $('#password').val()
      success: (data) ->
        router.navigate '', true
  unrender: ->
    $('#fs_header').empty()

class SignupView extends FsView
  template: _.template($('#tpl_signup').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    $('#fs_header').html @template()
  unrender: ->
    $('#fs_header').empty()

class NewFeelingView extends FsView
  events:
    'click .fs_submit': 'on_submit'
  template: _.template($('#tpl_new_feeling').html())
  me_template: _.template($('#tpl_me').html())
  associates_template: _.template($('#tpl_associates').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    $('#fs_header').html @template()
    @me.on 'change', @render_me, @
    @live_feelings.on 'change', @render_live_feelings, @
    @associates.on 'change', @render_associates, @
  render_me: ->
    $('#fs_header_me').html @me_template(JSON.stringify(data))
  render_live_feelings: ->
    $('#fs_header_live_feeling').empty()
    for word, n of data
      $('#fs_header_live_feeling').append "<li>#{word}</li>"
  render_associates: ->
    $('#fs_header_associates').empty()
    for asso in data
      $('#fs_header_associates').append @associates_template(JSON.stringify(asso))
  on_submit: ->
    $.ajax
      url: '../api/my_feelings'
      type: 'POST'
      dataType: 'json'
      data:
        word_id: $('#wordselect').find('.active').attr('word-id')
        content: $('#new_feeling_content').val()
      success: (data) ->
        router.navigate 'my_feelings', true
  unrender: ->
    @me.off 'change'
    @live_feelings.off 'change'
    @associates.off 'change'
    $('#fs_header').empty()

class CommentView extends FsView
  events:
    'click .icon-remove': 'on_remove'
    'click .icon-heart': 'on_like'
  template: _.template($('#tpl_comment').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    @$el.html @template(@model.toJSON())
    @model.on 'change', @render, @
    @
  on_remove: -> 
    alert 'not implemented'
  on_like: -> 
    alert 'not implemented'
  unrender:
    @model.off 'change'

class MyFeelingView extends FsView
  tagName: 'li'
  events:
    'click .card': 'on_expand'
  template: _.template($('#tpl_my_feeling').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    @set_comments_count()
    @$el.addClass('rd6').addClass('_sd0').addClass('card')
    @$el.html @template(@model.toJSON())
    if @model.get('expand')
      holder = @$el.find('.comments')
      holder.empty()
      for m in @model.get('comments')
        view = new CommentView(model: new Comment(m))
        views.push view
        holder.append view.render().el
    @model.on 'change', @render, @
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
    super
    @model.off 'change'

class MyFeelingsView extends FsView
  id: 'my_feelings_holder'
  events:
    'click .fs_more': 'on_more'
  template: _.template($('#tpl_feelings').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    @$el.html @template()
    $('#fs_body').html @$el
    @model.on 'concat', @on_concat, @
  on_concat: (list) ->
    @model.models.concat list
    for m in list
      view = new MyFeelingView(model: m)
      @views.push view
      @$el.append view.render().el
    wookmark.apply(@id)
  on_more: (event) ->
    @model.fetch()
  unrender: ->
    super
    @model.off 'concat'
    $('#fs_body').empty()

class NewCommentView extends FsView
  className: 'new_comment'
  events:
    'click .fs_submit': 'on_submit'
  template: _.template($('#tpl_new_comment').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    @$el.html @template()
    @model.on 'change', @render, @
    @
  on_submit: (event) -> 
    alert 'not implemented'
  unrender: ->
    super
    @model.off 'change'

class ReceivedFeelingView extends FsView
  tagName: 'li'
  events:
    'click .icon-comment': 'on_comment'
    'click .icon-heart': 'on_like'
    'click .icon-share-alt': 'on_forward'
  template: _.template($('#tpl_received_feeling').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    @$el.addClass('rd6').addClass('_sd0').addClass('card')
    @$el.html @template(@model.toJSON())
    if @model.type == 'comment'
      $('.icon-comment').css 'background-color', '#44f9b8'
    if @model.type == 'like'
      $('.icon-heart').css 'background-color', '#44f9b8'
    if @model.type == 'forward'
      $('.icon-share-alt').css 'background-color', '#44f9b8'
    if @model.type
      view = new NewCommentView
      views.push view
      @$.find('.inputarea').html view.render().el 
    @model.on 'change', @render, @
    @
  on_comment: (event) ->
    @model.set 'type', 'comment'
  on_like: (event) ->
    @model.set 'type', 'like'
  on_forward: (event) ->
    @model.set 'type', 'forward'
  unrender: ->
    super
    @model.off 'change'

class ReceivedFeelingsView extends FsView
  id: 'received_feelings_holder'
  events:
    'click .fs_more': 'on_more'
  template: _.template($('#tpl_feelings').html())
  initialize: ->
    _.bindAll @, 'unrender'
  render: ->
    @$el.html @template()

    view = new ArrivedFeelingView
    @views.push view
    @$el.append view.render().el

    $('#fs_body').html @$el
    @model.on 'prepend', @on_prepend, @
    @model.on 'concat', @on_concat, @
  on_concat: (list) ->
    @model.models.concat list
    for m in list
      view = new ReceivedFeelingView(model: m)
      @views.push view
      @$el.append view.render().el
    wookmark.apply(@id)
  on_prepend: (data) ->
    model = new ReceivedFeeling(data)
    @model.models.unshift model
    view = new ReceivedFeelingView(model: model)
    @views.push view
    $('#arrived_feeling').after view.render().el
    wookmark.apply(@id)
  on_more: (event) ->
    @model.fetch()
  unrender: ->
    super
    @model.off 'concat'
    @model.off 'prepend'
    $('#fs_body').empty()

class ArrivedFeelingView extends FsView
  tagName: 'li'
  id: 'arrived_feeling'
  events:
    'click #receive_arrived': 'on_receive'
    'click #flipcard': 'on_flip'
  template: _.template($('#tpl_arrived_feeling').html())
  holder_template: _.template($('#tpl_arrived_holder').html())
  initialize: ->
    _.bindAll @, 'unrender'
    @model = new ArrivedFeelings
  render: ->
    if @model.length > 0
      @$el.html @template(@model.toJSON())
    else
      @$el.html @holder_template(router.models.me.toJSON())
    @model.on 'reset', @render, @
    @
  on_receive: (event) ->
    @model.fetch()
  on_flip: (event) ->
    model = @model.at 0
    $.ajax
      url: "../api/new_arrived_feelings/#{model.get('id')}"
      type: 'PUT'
      dataType: 'json'
      success: (data) ->
        @model.reset()
        router.models.received.trigger 'prepend', data
  unrender: ->
    @model.off 'reset'
  
wookmark = new Wookmark
router = new Router
Backbone.history.start({pushState: true})
$.ajaxSetup
  statusCode:
    401: -> router.draw_login()
    403: -> router.draw_login()


======backbone 주의점 ========

view의 이벤트 셀렉터는 그 view하위에서만 셀렉트 됨..
  'click .button' ... 밖에있는 .button클래스는 무시..

jquery selector를 변수에 저장하면.. 캐싱됨..

pushState
navigate
several render..
@$el.html
sync

new on render()
model.once
double listening..

parent's array or hash is call by ref
class Parent
  x: []
classs Child extends Parent
  constructor: -> @x.push 1
parent.x=[1]

set model in render()

parent.html @$el in render()

####

      console.log $._data @$el.get(0), 'events'



============ 0914 ============

user
  arrived_feeling:
  my_feelings:
  rcv_feelings:


Feeling
  id
  status: 공개-쉐어/공개-종료/비공개/삭제
  time
  feeling
  blah
  talks
    id:
    comments: [
      {id: '', blah: '', time: ''}
    ]

class Feeling
  ..
  talks: []
class Talk
  id
  comments: []
class Comment
  id, blah, time

class FeelingView
  events
    'click .card'   
    'click .public'  --> PUT /feelings/:id
    'click .del'     --> DEL /feelings/:id
class TalkView
  events
    'click .like'    --> PUT /feelings/:id/like
    'click .repl'    
    'click .send'    --> POST /feelings/:id/talks/:user/comments
    
랜덤으로 느낌 받는거면.. 계속 공유안되는 느낌이 생길수도..
  오래된 느낌도 가중치..


GET /feelings?type=[my,rcv,share]


my feeling
  talks
    'uid'
      last comment.uid == talks.uid  --> input

rcv fee
  talks
    'uid'
      no comment --> input
      last comment.uid != talks.uid --> input


card-rcv

----------

  plsa  id           비공개*  <-- 나중에 비공개로 전환되었다면
                      10:10

  혼란스러움  OLD LOVE??
  무슨뜻이지?? 
  ------
  my-plsa 3
  --->
  .....                       <-- 하트주는거 없음..


card-my

  plsa  id      [비공개][삭제]  <-- 클릭해서 공개 전환 가능
                OCT 10 10:10

  혼란스러움  OLD LOVE??
  무슨뜻이지?? 

  ------
  a-plsa 3  p-plsa 1 ...

  --->

  a-plsa  id          [like]
  a-plsa blahbalh
  my-plsa blahblah
  a-plsa blahblah     [repl]
  ------
  b-plsa  id
  b-plsa blahblah

  tarea
                      [send]



Card
  id
  time

  Talks

============ 0914 ============

TODO
----

# session store ... 무시

# sign up .. 무시

# /api/live_feelings ..무시

# /api/associates.. 무시


REST
----

# GET /api/me

# GET /api/feelings
  skip, n, type

# POST /api/feelings
  word, blah

# GET /api/feelings/:id

# PUT /api/feelings/:id
  is_public

# PUT /api/feelings/:id/like
  email

# DEL /api/feelings/:id

# POST /api/feelings/:id/talks/:user_id/comments
  blah

# GET /api/arrived_feelings


DATA
----

# g_users =
    id: <user>

# g_feelings =
    id: <feeling>

# g_feelings_q =   # ordered. latest last
    [ <share_feeling_id>, ... ]

# g_feelings_seq
# g_feelings_seq
# g_users_seq

# <user>
    id:
    name:
    email:
    img:
    n_hearts:
    n_availables:
    wait_time:
    arrived_feelings: []
    my_feelings: []     # ordered. latest first
    rcv_feelings: []    # ordered. latest first

# <feeling>
    id
    user_id
    status: public/private/removed
    time
    word
    blah
    talks
      user_id: [
          {user_id: '', blah: '', time: ''}  # ordered. latest last
        ]
