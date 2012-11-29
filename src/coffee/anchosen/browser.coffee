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


	isMac = () -> navigator.platform.indexOf('Mac') > -1


	window.Anchosen ?= {}
	return window.Anchosen.Browser = {
		flexbox: hasFlex()
		placeholder: hasPlaceholder()
		isMac: isMac()
	}