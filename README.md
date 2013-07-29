nanav
=====

  cake build

USECASE
-------

## 지금 내 느낌 & 생각을 일기처럼 기록하고 싶음(일기니즈)
--> 느낌적기

## 그동안 적은 내 느낌들을 한눈에 보고 싶음(일기니즈)
--> 내 느낌들 조회

## 내가 느끼는 기분을 남들이 볼 수 있게 간접적으로 표현하고 싶음(소셜니즈)
--> 느낌적은거 퍼블리싱

## 나랑 비슷한 느낌을 가진 사람들의 글을 보고 공감하고 싶음(소셜니즈)
--> 나랑 비슷한 느낌 가진 느낌들(사람들) 조회
--> 공감해요, 댓글

## 오늘(최근24시간)동안 다른 사람들은 어떤 느낌을 가졌는지 한눈에 보고 싶음
--> 느낌 맵

## 서로 자주 공감하는 사람과 좀 더 대화를 나누고 싶음(소셜니즈)
--> 소셜활동조회 --> 소셜 매칭
--> 쪽지조회, 쪽지보내기


기능
-----

## 느낌적기 & 퍼블리싱
## 내 느낌조회
## 다른사람 느낌들 조회
## 다른사람 느낌에 공감해요 기능
## 다른사람 느낌에 댓글 기능
## 최근 24시간동안 다른 사람느낌 맵으로 표현
## 내게 자주 공감과 댓글을 달아준 사람 조회
## 내가 자주 공감과 댓글을 달아준 사람 조회
## 쪽지보내기
## 받은쪽지 조회


# Frontend Routes
-----------------

## 느낌적기
  /feelings/new
## 내 느낌조회
## 다른사람 느낌들 조회
## 다른사람 느낌에 공감해요 기능
## 다른사람 느낌에 댓글 기능
## 최근 24시간동안 다른 사람느낌 맵으로 표현
## 내게 자주 공감과 댓글을 달아준 사람 조회
## 내가 자주 공감과 댓글을 달아준 사람 조회
## 쪽지보내기
## 받은쪽지 조회



Environment
-----------

## backbone + coffee guide
http://adamjspooner.github.io/coffeescript-meet-backbonejs/01/docs/script.html
http://arturadib.com/hello-backbonejs/docs/1.html

## backbone + coffee quick tour
http://www.scriptybooks.com/books/backbone-coffeescript/chapters/quick-tour

## coffee doc
http://coffeescript.org/

## backbone doc
http://backbonejs.org/

## requirements
nodejs
npm install coffee

## pixlr
http://pixlr.com/editor/

## css grad tool
http://www.colorzilla.com/gradient-editor/


Windows Development Setting
---------------------------

  install node.js for windows
  
  set HTTP_PROXY=http://userid:pass@localhost:port  # if use proxy
  npm config set registry "http://registry.npmjs.org/"  # ssl off

  npm install -g coffee-script
  npm install which  # for windows

  cake build

