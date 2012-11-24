define ['jquery', 'knockout'], ($, ko) ->
	UPARROW = 38
	DOWNARROW = 40
	BACKSPACE = 8
	ESCAPE = 27
	ENTER = 13
	ko.bindingHandlers.anchosenSearchField =
		init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
			$el = $ element
			value = valueAccessor()
			val = ko.utils.unwrapObservable value
			$el.val val
			callback = () ->
				val = $el.val()
				value val if val != $el.attr('placeholder')
			$el.bind 'input.anchosen', callback

			# IE doesn't fire input events on text deletions, only additions *sigh* who ever thought that was a great idea?
			if $.browser.msie
				$el.bind 'keyup.anchosen', callback


			$el.bind 'keydown.anchosen', (e) ->
				switch e.keyCode
					when UPARROW
						e.preventDefault()
						viewModel.highlightPrevious()
					when DOWNARROW
						e.preventDefault()
						viewModel.highlightNext()
					when BACKSPACE
						if value() == ''
							if viewModel.lastSelectedIsMarked()
								viewModel.deselectLast()
							else
								viewModel.lastSelectedIsMarked true

			$el.bind 'keyup.anchosen', (e) ->
				switch e.keyCode
					when ESCAPE then viewModel.resetSearch(deselect = true)
					when ENTER then viewModel.selectHighlighted()


		update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
			$el = $ element
			$el.val ko.utils.unwrapObservable(valueAccessor())