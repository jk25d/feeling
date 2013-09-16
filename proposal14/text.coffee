
concat = (a,b) ->
  a.push x for x in b
merge_sort = (a,b) ->
  r = []
  i = j = 0
  loop
    if a.length == i
      concat r, b.slice(j,b.length)
      return r
    if b.length == j
      concat r, a.slice(i,a.length)
      return r
    console.log "#{a[i]} vs #{b[j]}"
    r.push if a[i] > b[j] then a[i++] else b[j++]
  r
  

a = [8, 6, 4, 2]
b = [7, 5, 3, 1]
console.log merge_sort(a,b)