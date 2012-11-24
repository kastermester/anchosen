define ['jquery', 'knockout', 'anchosen/view_model'], ($, ko, VM) ->
	class Anchosen
		disposed: false
		$el: null
		viewModel: null
		# Constructs a new Anchosen
		constructor: (@$el, options) ->
			@viewModel = viewModel = new VM options
			ko.applyBindings @viewModel, @$el[0]

			@$el.delegate 'ol.anchosen-available-options > li', 'click.anchosen', (e) ->
				viewModel.selectOption ko.dataFor this

			@$el.delegate 'ol.anchosen-selected-options > li > span.anchosen-deselect-option', 'click.anchosen', (e) ->
				viewModel.deselectOption ko.dataFor this

		dispose: () ->
			unless @disposed
				@viewModel.dispose()
				ko.applyBindings {}, @$el[0]
				@$el.undelegate '.anchosen'
				@$el = null
				@viewModel = null
				@disposed = true
