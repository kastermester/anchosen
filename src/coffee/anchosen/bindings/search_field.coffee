define ['jquery', 'knockout', 'anchosen/browser'], ($, ko, browser) ->
	UPARROW = 38
	DOWNARROW = 40
	BACKSPACE = 8
	ESCAPE = 27
	ENTER = 13
	ko.bindingHandlers.anchosenSearchField =
		init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
			$el = $ element
			binding = valueAccessor()


			text = binding.text

			$el.val ko.utils.unwrapObservable(text)

			callback = () ->
				val = $el.val()
				text val if val != $el.attr('placeholder') || val == ''
			$el.bind 'input.anchosen', callback if ko.isObservable text

			# IE doesn't fire input events on text deletions, only additions *sigh* who ever thought that was a great idea?
			if $.browser.msie && ko.isObservable text
				$el.bind 'keyup.anchosen', callback


			$el.bind 'keydown.anchosen', (e) ->
				switch e.keyCode
					when UPARROW
						e.preventDefault()
						binding.highlightPrevious.call(viewModel) if typeof binding.highlightPrevious == 'function'
					when DOWNARROW
						e.preventDefault()
						binding.highlightNext.call(viewModel) if typeof binding.highlightNext == 'function'
					when BACKSPACE
						if ko.utils.unwrapObservable(text) == ''
							if ko.utils.unwrapObservable(binding.isLastSelectedMarked)
								binding.deselectLast.call(viewModel) if typeof binding.deselectLast == 'function'
							else if ko.isObservable(binding.isLastSelectedMarked)
								binding.isLastSelectedMarked true


			$el.bind 'keyup.anchosen', (e) ->
				switch e.keyCode
					when ESCAPE then binding.reset.call(viewModel, true) if typeof binding.reset == 'function'
					when ENTER
						keepText = (browser.isMac && e.metaKey) || (!browser.isMac && e.ctrlKey) || e.shiftKey
						binding.selectHighlighted.call(viewModel, keepText) if typeof binding.selectHighlighted == 'function'
						if keepText
							$el.select()

		update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
			$el = $ element

			text = ko.utils.unwrapObservable(valueAccessor()).text

			$el.val ko.utils.unwrapObservable(text)

	return null