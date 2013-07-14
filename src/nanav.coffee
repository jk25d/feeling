$ ->
  class Item extends Backbone.Model
    defaults:
      part1: 'Hello'
      part2: 'Backbone'

  class List extends Backbone.Collection
    model: Item

  class ItemView extends Backbone.View
    tagName: 'li'
    initialize: -> _.bindAll @, 'render'
    render: -> 
      @$el.html "<span>#{@model.get 'part1'} #{@model.get 'part2'}!</span>"
      @

  class ListView extends Backbone.View
    el: $ 'body'

    initialize: ->
      _.bindAll @, 'render'
      @coll = new List
      @coll.bind 'add', @appendItem
      @counter = 0
      @render()

    render: ->
      @$el.append '<button>Add</button>'
      @$el.append '<ul></ul>'

    addItem: ->
      item = new Item
      item.set 'part2', "#{item.get 'part2'} #{@counter++}"
      @coll.add item

    appendItem: (item) ->
      v = new ItemView model: item
      $('ul').append v.render().el

    events: 'click button': 'addItem'

  list_view = new ListView

