foo = (a, b) ->
  a.filter (e) -> e >= b

a =[1,2,3]
console.log foo a, 2