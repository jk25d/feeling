// Generated by CoffeeScript 1.6.3
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

$(function() {
  var AppRouter, Wine, WineCollection, WineListItemView, WineListView, WineView, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
  Wine = (function(_super) {
    __extends(Wine, _super);

    function Wine() {
      _ref = Wine.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return Wine;

  })(Backbone.Model);
  WineCollection = (function(_super) {
    __extends(WineCollection, _super);

    function WineCollection() {
      _ref1 = WineCollection.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    WineCollection.prototype.model = Wine;

    WineCollection.prototype.url = "api/wines";

    return WineCollection;

  })(Backbone.Collection);
  WineListView = (function(_super) {
    __extends(WineListView, _super);

    function WineListView() {
      _ref2 = WineListView.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    WineListView.prototype.tagName = 'ul';

    WineListView.prototype.initialize = function() {
      return this.model.bind('reset', this.render, this);
    };

    WineListView.prototype.render = function(event) {
      var wine, _fn, _i, _len, _ref3;
      _ref3 = this.model.models;
      _fn = function(wine) {
        return this.$el.append(new WineListItemView({
          model: wine
        }).render().el);
      };
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        wine = _ref3[_i];
        _fn(wine);
      }
      return this;
    };

    return WineListView;

  })(Backbone.View);
  WineListItemView = (function(_super) {
    __extends(WineListItemView, _super);

    function WineListItemView() {
      _ref3 = WineListItemView.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    WineListItemView.prototype.tagName = 'li';

    WineListItemView.prototype.template = _.template($('#tpl-wine-list-item').html());

    WineListItemView.prototype.render = function(event) {
      this.$el.html(this.template(this.model.toJSON));
      return this;
    };

    return WineListItemView;

  })(Backbone.View);
  WineView = (function(_super) {
    __extends(WineView, _super);

    function WineView() {
      _ref4 = WineView.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    WineView.prototype.template = _.template($('#tpl-wine-details').html());

    WineView.prototype.render = function(event) {
      this.$el.html(this.template(this.model.toJSON));
      return this;
    };

    return WineView;

  })(Backbone.View);
  AppRouter = (function(_super) {
    __extends(AppRouter, _super);

    function AppRouter() {
      _ref5 = AppRouter.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    AppRouter.prototype.routes = {
      "": "list",
      "wines/:id": "wineDetails"
    };

    AppRouter.prototype.list = function() {
      this.wineList = new WineCollection;
      this.wineListView = new WineListView({
        model: this.wineList
      });
      this.wineList.fetch();
      return $('#sidebar').html(this.wineListView.render().el);
    };

    AppRouter.prototype.wineDetails = function(id) {
      this.wine = this.wineList.get(id);
      this.wineView = new WineView({
        model: this.wine
      });
      return $('#content').html(this.wineView.render().el);
    };

    return AppRouter;

  })(Backbone.Router);
  new AppRouter;
  return Backbone.history.start();
});
