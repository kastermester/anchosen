define ['jquery', 'underscore', 'knockout'], ($, _, ko) ->
	UPARROW = 38
	DOWNARROW = 40
	ESCAPE = 27
	ENTER = 13
	ko.bindingHandlers.searchField =
		init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
			$el = $ element
			value = valueAccessor()
			val = ko.utils.unwrapObservable value
			$el.val val
			callback = () ->
				val = $el.val()
				value val
			$el.bind 'input.anchosen', callback
			$el.bind 'propertychange.anchosen', callback


			$el.bind 'keydown.anchosen', (e) ->
				switch e.keyCode
					when UPARROW
						e.preventDefault()
						viewModel.highlightPrevious()
					when DOWNARROW
						e.preventDefault()
						viewModel.highlightNext()

			$el.bind 'keyup.anchosen', (e) ->
				switch e.keyCode
					when ESCAPE then viewModel.resetSearch(deselect = true)
					when ENTER then viewModel.selectHighlighted()


		update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
			$el = $ element
			$el.val ko.utils.unwrapObservable(valueAccessor())