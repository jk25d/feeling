class Animal
  constructor: (@name) ->
  xx: {}
  move: (meters) ->
    console.log @name + " moved #{meters}m."

class Snake extends Animal
  move: ->
    @xx.a = 1
    console.log @xx
    console.log "Slithering..."
    super 5

class Horse extends Animal
  move: ->
    @xx.b=2
    console.log @xx
    console.log "Galloping..."
    super 45

sam = new Snake "Sammy the Python"
tom = new Horse "Tommy the Palomino"

sam.move()
tom.move()
sam.move()