define ['jquery', 'underscore', 'knockout'], ($, _, ko) ->
	class ViewModel
		defaultOptions:
			selected: []
			options: []
			placeholder: ''
			chooseFollowingText: 'Choose following'
			chooseFollowingThreshold: 7 # Set to 0 to disable threshold
			chooseFollowingEnabled: true
			createNewEnabled: false
			createNewText: 'Create new \'{0}\''
			substringMatch: false
			createNewHandler: (text, callback) ->
				callback
					label: text
					value: null

			maximumSelectionsAllowed: 0 # 0 for no limit
			maximumSelectionsReachedText: 'Maximum of {0} items reached'
			automaticClear: true
		subscriptions: null

		disposed: false

		constructor: (options) ->
			options = $.extend {}, ViewModel::defaultOptions, options
			@createNewHandler = options.createNewHandler
			@searchString = ko.observable ''
			@oldSearchString = ''
			@delayedSearchString = ko.computed(
				() => @searchString()
			).extend throttle: 1

			@reverseShowOrder = ko.observable(false)

			@automaticClear = ko.observable(options.automaticClear)

			@maximumSelectionsAllowed = ko.observable(options.maximumSelectionsAllowed)
			@maximumSelectionsReachedText = ko.observable(options.maximumSelectionsReachedText)

			@enabled = ko.observable(true)
			@disabled = ko.computed () => !@enabled()
			@placeholder = ko.observable(options.placeholder)
			@substringMatch = ko.observable(options.substringMatch)

			@searchFieldFocused = ko.observable(false)

			opts = if !ko.isObservable(options.options) then @extractAndSortOptions options else null
			selected = if !ko.isObservable(options.selected) then options.selected.slice() else null

			@chooseFollowingEnabled = ko.observable(options.chooseFollowingEnabled)
			@chooseFollowingThreshold = ko.observable(options.chooseFollowingThreshold)
			@chooseFollowingText = ko.observable(options.chooseFollowingText)

			@highlightedIndex = ko.observable(-2)

			@createNewEnabled = ko.observable(options.createNewEnabled)

			@chooseFollowingHighlighted = ko.computed () => @highlightedIndex() == -1

			@options = if !ko.isObservable(options.options) then ko.observableArray opts else options.options
			@selectedOptions = if !ko.isObservable(options.selected) then ko.observableArray selected else options.selected

			@singleSelectionAllowed = ko.computed () => @maximumSelectionsAllowed() == 0 || @maximumSelectionsAllowed() > @selectedOptions().length

			@searchFieldMaxLength = ko.computed () =>
				return 0 if !@singleSelectionAllowed()
				return ''

			@placeholderText = ko.computed () =>
				if @selectedOptions().length == 0
					return @placeholder()
				else if !@singleSelectionAllowed()
					return @formatText @maximumSelectionsReachedText(), @maximumSelectionsAllowed()
				else
					return ''

			@availableOptionsNoThrottle = ko.computed(() =>
				result = []
				search = @delayedSearchString().toLowerCase()
				ko.utils.arrayForEach @options(), (e) =>
					idxOf = e.label.toLowerCase().indexOf(search)

					if (@substringMatch() && idxOf > -1) || (!@substringMatch() && idxOf == 0)
						result.push e

				return result
			)

			# We throttle the available options to ensure that the list updates after we may decide to hide it
			@availableOptions = @availableOptionsNoThrottle.extend throttle: 250


			@availableOptionsVisible = ko.computed(() =>
				if @enabled() && @searchFieldFocused() && @singleSelectionAllowed() && @options().length > 0
					return @searchString().length > 0 || @highlightedIndex() != -2
				return false
			# This is throttled to ensure that clicking the list doesn't cause any weird effects
			# Like the field looses focus and then the list disappears
			).extend throttle: 100

			@noResultsVisible = ko.computed () =>
				!@createNewEnabled() &&
				@availableOptions().length == 0 &&
				@options().length > 0 &&
				@searchString().length > 0

			@highlighted = ko.computed
				read: () =>
					idx = @highlightedIndex()
					optsLength = @availableOptions().length
					if optsLength > 0 && idx < optsLength
						return @availableOptions()[idx]
					else
						return null
				write: (option) =>
					idx = ko.utils.arrayIndexOf @availableOptions(), option
					if idx > -1
						@highlightedIndex idx

			@isLastSelectedMarked = ko.observable(false)

			@chooseFollowingVisible = ko.computed () =>
				return false unless @chooseFollowingEnabled()
				avail = @availableOptions().length
				# Must have at least 2 results available. No point in showing Choose following for 0 or 1 option
				return false if avail < 2
				return false if avail > @chooseFollowingThreshold() && @chooseFollowingThreshold() != 0
				return false if @maximumSelectionsAllowed() > 0 && (@maximumSelectionsAllowed() - @selectedOptions().length) < @availableOptions().length
				return true
			@subscriptions = []
			@subscriptions.push @delayedSearchString.subscribe () =>
				@highlightedIndex -2
				@isLastSelectedMarked false

			@subscriptions.push @searchFieldFocused.subscribe () =>
				@isLastSelectedMarked false

			@subscriptions.push @searchFieldFocused.subscribe (focused) =>
				if !focused
					@resetSearch() if @automaticClear()

			@createNewText = ko.observable(options.createNewText)
			@createNewVisible = ko.computed () => @createNewEnabled() && @delayedSearchString() != '' && @availableOptions().length == 0 && @singleSelectionAllowed()

			@createNewHighlighted = ko.computed () => @highlightedIndex() == -1

			@formattedCreateNewText = ko.computed () =>
				@formatText @createNewText(), @delayedSearchString()


		formatText: (text, value) ->
			text.replace '{0}', value

		highlightNext: () ->
			if !@reverseShowOrder()
				@doHighlightNext()
			else
				@doHighlightPrevious()

		highlightPrevious: () ->
			if !@reverseShowOrder()
				@doHighlightPrevious()
			else
				@doHighlightNext()

		doHighlightNext: () ->
			return unless @enabled()
			highlighted = @highlightedIndex()

			if @createNewVisible()
				if !@createNewHighlighted()
					@highlightedIndex(-1)
					@onHighlightNextOrPrevious?()
				return

			if highlighted+1 < @availableOptions().length
				if highlighted == -2 && !@chooseFollowingVisible()
					highlighted = -1
				@highlightedIndex(highlighted+1)
				@onHighlightNextOrPrevious?()


		doHighlightPrevious: () ->
			return unless @enabled()
			highlighted = @highlightedIndex()

			if @createNewVisible()
				if @createNewHighlighted()
					@highlightedIndex(-2)
				return

			if highlighted > -2
				if highlighted == 0 && !@chooseFollowingVisible()
					highlighted = -1
				@highlightedIndex(highlighted-1)
				@onHighlightNextOrPrevious?()

		chooseFollowing: () ->
			return unless @enabled()
			following = @availableOptions()
			return unless following.length > 0
			return if @maximumSelectionsAllowed() != 0 && (@maximumSelectionsAllowed() - @selectedOptions().length) < following.length
			first = following[0]

			idxFirst = ko.utils.arrayIndexOf @options(), first

			# Remove the elements from the options
			@options.splice idxFirst, following.length
			# Now select them
			@selectedOptions.splice (@selectedOptions().length), 0, following...

			@resetSearch()

		selectHighlighted: (forceShowAvailableOptions = false) ->
			return unless @enabled()
			return @createNew() if @createNewVisible() && @createNewHighlighted()
			return @chooseFollowing() if @chooseFollowingVisible() && @chooseFollowingHighlighted()
			highlighted = @highlighted()

			return unless highlighted?

			@selectOption highlighted, forceShowAvailableOptions

		selectOption: (option, forceShowAvailableOptions = false) ->
			return unless @enabled()
			return unless @singleSelectionAllowed()
			hlIdx = @highlightedIndex()
			availLength = @availableOptions().length
			@options.remove option
			@selectedOptions.push option

			if forceShowAvailableOptions
				if hlIdx >= availLength-1
					if hlIdx > 0
						@highlightedIndex(hlIdx-1)
					else
						@highlightedIndex(-2)
				@isLastSelectedMarked(false)
			else
				@resetSearch()
			@searchFieldFocused(true)

		deselectOption: (option) ->
			return unless @enabled()
			@selectedOptions.remove option

			@addAndKeepSortOrder option, @options

			@searchFieldFocused(true)

		deselectLast: () ->
			return unless @enabled()
			return if @selectedOptions().length == 0
			@isLastSelectedMarked(false)
			@deselectOption @selectedOptions()[@selectedOptions().length-1]

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

		isMarked: (index) ->
			index = index()
			@isLastSelectedMarked() && index+1 == @selectedOptions().length

		resetSearch: (deselect = false) ->
			@searchString('')
			@highlightedIndex(-2)
			@isLastSelectedMarked(false)

			@searchFieldFocused(false) if deselect

		createNew: () ->
			return unless @enabled()
			return unless @singleSelectionAllowed()
			text = @delayedSearchString()

			automaticClear = @automaticClear()
			@automaticClear(false)

			@enabled(false)
			@createNewHandler text, (model) =>
				return if @disposed
				unless model?
					# Return and re-enable the ViewModel if the creation failed
					@enabled(true)
					# Reset the automatic clear back to its original value
					# For some, still unclear reason, we need a delay in here
					# Otherwise the field will be magically reset
					# I suspect this has to do with the fact that we fade in the search field
					setTimeout(() =>
						@automaticClear(automaticClear)
						if !@searchFieldFocused()
							# If the field is not focused, clear it
							@resetSearch() && @automaticClear()
					, 250)
					return

				@automaticClear(automaticClear)
				@resetSearch()
				@selectedOptions.push model
				@enabled(true)

		extractAndSortOptions: (options) ->
			@sortOptions _.filter options.options, (e) ->
				!_.find(options.selected, (s) -> e.value == s.value)

		sortOptions: (options) ->
			_.sortBy options, (e) -> e.label


		setSelection: (selected) ->


		dispose: () ->
			unless @disposed
				sub.dispose() for sub in @subscriptions
				@subscriptions = null
				@selectedOptions []
				@options []
				@disposed = true