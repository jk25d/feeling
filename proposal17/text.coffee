###
class OrderedMap
  constructor: -> 
    @_h = {}
    @_a = []
    @length = 0
  get: (k) -> 
    @_h[k]
  set: (k,v) -> 
    @_h[k] = v
    @_a.push k
    @length++
  del: (k) ->
    if @_h[k]
      delete @_h[k]
      @length--
  keys: ->
    h = @_h
    @_a = @_a.filter (k) -> h[k]
    @length = @_a.length
  _find_idx: (k) ->
    return -1 if a.length == 0
    for i in [0..a.length-1]
      if a
    return -1
  subkeys: (from, skip, n) ->
    from_idx = _find_idx from
    return [] if from_idx == -1 || from_idx + skip > @_a.length-1
    r = []
    for k in @_a[from_idx+skip..-1]
      break if r.length == n
      r.push k if h[k]
    r
      

class OrderedSet extends OrderedMap
  set: (k) -> super k,k

x = new OrderedSet
y = new OrderedSet
x.set 99
x.set 2
x.set 44
console.log x.keys()
console.log x.length
x.del 1
x.del 2
console.log x.keys()
console.log x.length
console.log y.get 2
console.log y.length
###


x = try 1
console.log x