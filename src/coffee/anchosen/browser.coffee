define [
], () ->
	el = document.createElement 'anchosen'

	style = el.style

	cssPrefixes = ['webkit', 'Moz']

	hasFlex = () ->
		return true if style['flexDirection']?

		for pref in cssPrefixes
			return true if style[pref + 'FlexDirection']?

		return false


	hasPlaceholder = () ->
		test = document.createElement 'input'
		return 'placeholder' in test

	return {
		flexbox: hasFlex()
		placeholder: hasPlaceholder()
	}