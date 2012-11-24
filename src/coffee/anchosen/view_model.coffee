define ['jquery', 'underscore', 'knockout'], ($, _, ko) ->
	class ViewModel
		defaultOptions: {
			selected: [],
			options: []
		}

		subscriptions: null

		disposed: false

		constructor: (options) ->
			options = $.extend {}, ViewModel::defaultOptions, options
			@searchString = ko.observable ''
			@oldSearchString = ''
			@delayedSearchString = ko.computed(
				() -> @searchString(),
				this
			).extend throttle: 1

			that = this
			@searchFieldFocused = ko.observable(false)

			opts = @extractAndSortOptions options
			selected = @sortOptions options.selected


			@highlightedIndex = ko.observable(-1)


			@options = ko.observableArray opts
			@selectedOptions = ko.observableArray selected

			@availableOptions = ko.computed () ->
				result = []
				search = @delayedSearchString().toLowerCase()
				ko.utils.arrayForEach @options(), (e) ->
					if e.label.toLowerCase().indexOf(search) == 0
						result.push e

				return result
			, this

			@availableOptionsVisible = ko.computed(() ->
				@searchFieldFocused()
			, this).extend throttle: 100

			@highlighted = ko.computed () ->
				idx = @highlightedIndex()
				optsLength = @availableOptions().length
				if optsLength > 0 && idx < optsLength
					return @availableOptions()[idx]
				else
					return null
			, this

			@subscriptions = []
			@subscriptions.push @delayedSearchString.subscribe () =>
				@highlightedIndex -1

		highlightNext: () ->
			highlighted = @highlightedIndex()

			if highlighted+1 < @availableOptions().length
				@highlightedIndex(highlighted+1)


		highlightPrevious: () ->
			highlighted = @highlightedIndex()

			if highlighted > 0
				@highlightedIndex(highlighted-1)

		selectHighlighted: () ->
			highlighted = @highlighted()

			return unless highlighted?

			@selectOption highlighted

		selectOption: (option) ->
			@options.remove option
			@addAndKeepSortOrder option, @selectedOptions

			@resetSearch()
			@searchFieldFocused(true)

		deselectOption: (option) ->
			@selectedOptions.remove option

			@addAndKeepSortOrder option, @options

		addAndKeepSortOrder: (option, observableArray) ->
			array = observableArray()
			after = ko.utils.arrayFirst array, (e) -> e.label > option.label

			if after?
				idx = ko.utils.arrayIndexOf array, after
				observableArray.splice idx, 0, option
			else
				observableArray.push option

		isHighlighted: (option) ->
			@highlighted()?.value == option.value

		resetSearch: (deselect = false) ->
			@searchString('')
			@highlightedIndex(-1)

			@searchFieldFocused(false) if deselect

		extractAndSortOptions: (options) ->
			opts = _.filter options.options, (e) ->
				!_.find(options.selected, (s) -> e.value == s.value)

		sortOptions: (options) ->
			_.sortBy options, (e) -> e.label

		dispose: () ->
			unless @disposed
				sub.dispose() for sub in @subscriptions
				@subscriptions = null
				@selectedOptions []
				@options []
				@disposed = true