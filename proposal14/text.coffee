x = []
class Foo
  a: []
  constructor: ->
  do: ->
    @a.length

console.log new Foo().do()
