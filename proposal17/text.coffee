class Foo
  some: (x=false) ->
    @x = x

console.log new Foo().some()