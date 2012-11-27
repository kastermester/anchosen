define [
	'jquery'
	'knockout'
], ($, ko) ->
	ko.bindingHandlers.anchosenFadeVisible =
		update: (element, valueAccessor, allBindingsAccessor) ->
			# First get the latest data that we're bound to
			value = valueAccessor()
			allBindings = allBindingsAccessor()

			# Next, whether or not the supplied model property is observable, get its current value
			valueUnwrapped = ko.utils.unwrapObservable(value)

			# Grab some more data from another binding property
			duration = ko.utils.unwrapObservable(allBindings.fadeDuration) || 200; # 400ms is default duration unless otherwise specified

			# Now manipulate the DOM element
			if (valueUnwrapped == true)
				$(element).fadeIn(duration) # Make the element visible
			else
				$(element).hide()   # Make the element invisible