## data
USERS  // not ordered
{ uid:
    feelings: [id, ...]
    comments: [id, ...]
    float_feelings: [id,id,id] // max 3

FEELINGS  // not ordered
[ feeling_id:
    user:
    time:
    word_id:
    content:
    comments: [id]

COMMENTS  // not ordered
[ comment_id:
    user:
    time:
    word_id:
    keep:
    feeling_id:

DAILY_WORDS  // not ordered
{ word_id:
    n:

FLOAT_FEELINGS  // can be removed
{ id:
    feeling_id:
    nforwards:
    remains: 3

FEELINGQ // ordered
[ float_feeling_id:

## rest api

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

--------

tile layout

http://www.wookmark.com/jquery-plugin         # MIT, 1.4.2, 15k(6k)
https://github.com/xlune/jQuery-vGrid-Plugin	# MIT, 0.1.11, 9.7k, has delay if reduce size
http://yconst.com/web/freetile/		            # MIT, 0.3.1, 30k(12k)
https://github.com/thinkpixellab/tilesjs      # MIT, , 21k
http://masonry.desandro.com/		              # MIT, 3.1.1, 70k(24k)

http://www.inwebson.com/demo/blocksit-js/  # no responsive?
http://isotope.metafizzy.co/		# commercial license
http://jsonenglish.com/projects/flex/         # no dynamic alignment