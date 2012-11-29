define [
	'jquery'
	'anchosen/anchosen'
], ($, Anchosen) ->
	$.fn.anchosen = (options) ->
		throw new Error "Cannot call anchosen without any arguments" unless options?
		args = []

		for key,value of arguments
			if typeof key == 'number'
				args.push value

		# Shift first element away
		realResult = undefined
		args.splice 0, 1
		result = @each () ->
			$el = $(this)

			unless (anc = $el.data('anchosen'))?
				anc = new Anchosen $el, options
				$el.data 'anchosen', anc
			else
				if typeof options != 'string'
					throw new Error "When calling anchosen on an existing anchosen, first argument must be a string"

				res = anc[options].apply anc, args
				if options == 'destroy'
					$el.data 'anchosen', null

				realResult = res if res != undefined && realResult == undefined

		if realResult
			return realResult
		else
			return result
	return null