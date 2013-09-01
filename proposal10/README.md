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
