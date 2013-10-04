class Foo
  a = []
  constructor: -> b = 'im b'
  prv = -> @
  pub: -> "public method"
  do: ->
    console.log prv()
    console.log @pub()
    console.log @a
    console.log b
  inc: -> a.push "11"
  print: -> a

class Foo2 extends Foo
  inc: -> a.push "22"

f = new Foo
f.do()
