define [
	'anchosen/browser'
	'jquery'
], (browser, $) ->
	# Code greatly inspired by gist at https://gist.github.com/765595
	applyPlaceholder = (() ->
		if browser.placeholder
			return ($el) ->

		($el) ->
			$el.on('focus.anchosen', () ->
				_placeholder = $el.attr('placeholder')
				_val = $el.val()

				if _placeholder != '' && _val == _placeholder
					$el.val('').removeClass('anchosen-has-placeholder')
			).on('blur.anchosen', () ->
				_placeholder = $el.attr('placeholder')
				_val = $el.val()

				if _placeholder && (_val == '' || _val == _placeholder)
					$el.val(_placeholder).addClass 'anchosen-has-placeholder'
			).on('keydown.anchosen keyup.anchosen', () ->
				_placeholder = $el.attr('placeholder')
				_val = $el.val()

				if _val != '' && _val != _placeholder
					$el.removeClass 'anchosen-has-placeholder'
			)
	)()
	$.fn.anchosenPlaceholder = () -> @each () -> applyPlaceholder($(this))