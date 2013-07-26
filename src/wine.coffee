$ ->
  class Wine extends Backbone.Model

  class WineCollection extends Backbone.Collection
    model: Wine
    url: "api/wines"

  class WineListView extends Backbone.View
    tagName: 'ul'
    initialize: ->
      @model.bind 'reset', @render, @
    render: (event) ->
      for wine in @model.models
        do (wine) ->
          @$el.append new WineListItemView(model: wine).render().el
      @

  class WineListItemView extends Backbone.View
    tagName: 'li'
    template: _.template $('#tpl-wine-list-item').html()
    render: (event) ->
      @$el.html @template(@model.toJSON)
      @

  class WineView extends Backbone.View
    template: _.template $('#tpl-wine-details').html()
    render: (event) ->
      @$el.html @template(@model.toJSON)
      @

  class AppRouter extends Backbone.Router
    routes:
      "": "list"
      "wines/:id": "wineDetails"
    list: ->
      @wineList = new WineCollection
      @wineListView = new WineListView model: @wineList
      @wineList.fetch()
      $('#sidebar').html @wineListView.render().el

    wineDetails: (id) ->
      @wine = @wineList.get id
      @wineView = new WineView model: @wine
      $('#content').html @wineView.render().el

  new AppRouter
  Backbone.history.start()