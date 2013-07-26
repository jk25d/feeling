express = require 'express'
app = express()

app.get '/', (req,res) ->
  console.log '/'
  res.sendfile 'public/wine.html'

app.get '/api/wines', (req,res) ->
  console.log 'api/wines'
  res.json [ {id: '0', name: 'a'}, {id: '1', name: 'b'} ]
    

app.use express.static("#{__dirname}/public")
app.listen '3333'
console.log 'listening on 3333'