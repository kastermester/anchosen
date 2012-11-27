define [
	'jquery'
	'knockout'
	'anchosen/view_model'
	'anchosen/browser'
	'anchosen/bindings/search_field'
	'anchosen/bindings/fade_visible'
	'anchosen/jquery.placeholder'
], ($, ko, VM, browser) ->
	class Anchosen
		disposed: false
		$el: null
		viewModel: null
		staticId = 0
		id: 0
		tabIndex: null
		restoreTabIndex: false
		# Constructs a new Anchosen
		constructor: (@$el, options) ->
			@id = staticId
			@$el.addClass 'anchosen'
			staticId++

			@tabIndex = @$el.attr('tabindex')
			unless @tabIndex?
				@tabIndex = options.tabIndex
			else
				@restoreTabIndex = true


			@viewModel = viewModel = new VM options

			@setupElement()

			ko.applyBindings @viewModel, @$el[0]
			that = this

			@$el.delegate 'div.anchosen-drop', 'mousedown.anchosen', (e) ->
				e.stopPropagation()
				e.preventDefault()
				viewModel.searchFieldFocused(true)
			@$el.delegate 'ol.anchosen-available-options > li.anchosen-available-option', 'click.anchosen', (e) ->
				keepText = (browser.isMac && e.metaKey) || (!browser.isMac && e.ctrlKey) || e.shiftKey
				viewModel.selectOption(ko.dataFor(this), keepText)
				that.$searchField.select() if keepText

			@$el.delegate 'ol.anchosen-available-options > li.anchosen-choose-following', 'click.anchosen', (e) ->
				viewModel.chooseFollowing()

			@$el.delegate 'ol.anchosen-selected-options > li > span.anchosen-deselect-option', 'click.anchosen', (e) ->
				e.preventDefault()
				e.stopPropagation()
				viewModel.deselectOption ko.dataFor this

			@$el.delegate 'div.anchosen-search-box', 'click.anchosen', (e) ->
				e.preventDefault()
				viewModel.searchFieldFocused true

			@$el.delegate 'ol.anchosen-selected-options', 'mousedown.anchosen', (e) ->
				e.stopPropagation()
				e.preventDefault()

			@$el.delegate 'ol.anchosen-selected-options > li', 'click.anchosen', (e) ->
				viewModel.searchFieldFocused true

			@$el.delegate 'ol.anchosen-available-options > li.anchosen-available-option', 'hover.anchosen', (e) ->
				viewModel.highlighted ko.dataFor this

			@$el.delegate 'ol.anchosen-available-options > li.anchosen-choose-following, ol.anchosen-available-options > li.anchosen-create-new', 'hover.anchosen', (e) ->
				viewModel.highlightedIndex -1

			@$searchField = $(@$el.find('input.anchosen-search-input')[0])

			@$searchBox = $(@$el.find('div.anchosen-search-box')[0])

			@$dropBox = $(@$el.find('div.anchosen-drop')[0])

			@$window = $(window)
			@$container = options.container ? @$window

			@$window.on "resize.anchosen#{@id}", () =>
				@calculateSearchFieldWidth()
				@calculateDropPosition(true) if viewModel.availableOptionsVisible()


			viewModel.subscriptions.push viewModel.selectedOptions.subscribe () =>
				@calculateSearchFieldWidth()
				@calculateDropPosition()

			viewModel.subscriptions.push viewModel.availableOptionsVisible.subscribe (visible) => @calculateDropPosition(true) if visible
			viewModel.subscriptions.push viewModel.availableOptions.subscribe () => @calculateDropPosition(false) if viewModel.availableOptionsVisible()

			@viewModel.onHighlightNextOrPrevious = () => @scrollToHighlighted()

			@$searchField.width(100)
			setTimeout((() => @calculateSearchFieldWidth()), 100)

		setupElement: () ->
			@restoreContents = @$el.contents().detach()
			@$el.html('
			<div class="anchosen-search-box" data-bind="css: { focus: searchFieldFocused, \'anchosen-working\': disabled }">
				<ol class="anchosen-selected-options">
					<!-- ko foreach: selectedOptions -->
						<li class="anchosen-selected-option" data-bind="css: { marked: $root.isMarked($index), \'anchosen-working\': $root.disabled }">
							<span data-bind="text: label, css: { \'anchosen-working\': $root.disabled }" class="anchosen-label"></span><span class="anchosen-deselect-option" data-bind="css: { \'anchosen-working\': $root.disabled }">&times;</span>
						</li>
					<!-- /ko -->
					<li><input type="text" autocomplete="off" class="anchosen-search-input" data-bind="anchosenSearchField: { text: searchString, highlightPrevious: highlightPrevious, highlightNext: highlightNext, isLastSelectedMarked: isLastSelectedMarked, deselectLast: deselectLast, reset: resetSearch, selectHighlighted: selectHighlighted }, hasfocus: searchFieldFocused, attr: { placeholder: placeholderText, maxlength: searchFieldMaxLength }, enable: enabled, css: { \'anchosen-working\': disabled }"></li>
				</ol>
			</div>
			<div class="anchosen-drop" data-bind="anchosenFadeVisible: availableOptionsVisible">
				<ol class="anchosen-available-options">
					<li class="anchosen-choose-following" data-bind="text: chooseFollowingText, visible: chooseFollowingVisible, css: { highlighted: $root.chooseFollowingHighlighted }"></li>
					<!-- ko foreach: availableOptions -->
						<li class="anchosen-available-option" data-bind="text: label, css: { highlighted: $root.isHighlighted($data) }"></li>
					<!-- /ko -->
					<li data-bind="visible: noResultsVisible" class="anchosen-no-results">No results found for \'<span data-bind="text: searchString"></span>\'</li>
					<li data-bind="visible: alreadySelectedVisible, text: alreadySelectedText" class="anchosen-already-selected"></li>
					<li data-bind="visible: createNewVisible, text: formattedCreateNewText, click: createNew, css: { highlighted: createNewHighlighted }" class="anchosen-create-new"></li>
				</ol>
			</div>')

			@$el.find('input.anchosen-search-input').attr('tabindex', @tabIndex).anchosenPlaceholder()
			@$el.attr('tabindex', null)

		# A simple method to scale the input field to the remaining size available
		calculateSearchFieldWidth: () ->
			minWidth = 100
			@$searchField.width(minWidth)

			# Subtract one to remove the border on the left size
			offsetLeft = @$searchField.position().left - @$searchBox.position().left - 1

			searchBoxWidth = @$searchBox.innerWidth()

			width = searchBoxWidth - offsetLeft - (@$searchField.outerWidth() - minWidth)

			@$searchField.width(width-2)	# Subtract 2 to make IE9 happy

		# Calculate the position of the drop choices
		calculateDropPosition: (scrollToBeginning = false) ->
			display = @$dropBox.css 'display'
			@$dropBox.css 'display', 'none'
			containerHeight = @$container[0].innerHeight
			containerScrollTop = @$container.scrollTop()
			dropBoxMaxHeight = parseInt @$dropBox.css('max-height')
			dropBoxHeight = @$dropBox.height()
			searchBoxHeight = @$searchBox.height()
			position = @$searchBox.position()
			window.box = @$searchBox
			width = @$searchBox.width()

			# Only show the box at the top if the flexbox model is supported
			# Otherwise we get weird issues with not showing the dom elements in reverse order
			if browser.flexbox && containerHeight - (searchBoxHeight+position.top-containerScrollTop+dropBoxMaxHeight+2) < 0
				# Not enough space to show the drop box below the search box - is there enough to show it above?
				if position.top > dropBoxMaxHeight + 1
					# Good to go!
					@$dropBox.removeClass('drop-bottom').addClass('drop-top')
					@$dropBox.css
						display: display
						left: position.left
						top: position.top - dropBoxHeight - 1
						width: width
					@$dropBox.children('ol').addClass('reverse')
					@viewModel.reverseShowOrder(true)
					if scrollToBeginning && !@viewModel.highlighted()?
						@$dropBox.scrollTop(@$dropBox[0].scrollHeight)
					return

			@viewModel.reverseShowOrder(false)
			@$dropBox.children('ol').removeClass('reverse')
			@$dropBox.removeClass('drop-top').addClass('drop-bottom')
			@$dropBox.css
				display: display
				left: position.left
				top: position.top + searchBoxHeight + 2
				width: width
			if scrollToBeginning && !@viewModel.highlighted()?
				@$dropBox.scrollTop(0)

		scrollToHighlighted: () ->
			hl = @$dropBox.find('li.highlighted').first()

			return if hl.length == 0

			@scrollToHighlightedElement $(hl[0])

		scrollToHighlightedElement: ($el) ->
			offsetTop = $el.position().top
			offsetTop = 0 if offsetTop == -1
			height = @$dropBox.innerHeight()
			scrollTop = @$dropBox.scrollTop()
			offsetTop += scrollTop
			elementHeight = $el.outerHeight()

			if offsetTop < scrollTop
				@$dropBox.scrollTop(offsetTop)
			else if height+scrollTop < offsetTop + elementHeight
				@$dropBox.scrollTop(offsetTop-(height-elementHeight))


		# API methods
		refresh: () ->
			@calculateSearchFieldWidth()
			@calculateDropPosition(false) if @viewModel.availableOptionsVisible()

			# return undefined to signal chainability
			return undefined

		destroy: () ->
			@dispose()

		viewmodel: () ->
			return @viewModel

		value: (selected = null) ->
			return @viewModel.selectedOptions() unless selected?

			@viewModel.setSelection selected
			# return undefined to signal chainability
			return undefined
		# END API methods

		dispose: () ->
			unless @disposed
				@$el.removeClass 'anchosen'
				@$el.find('input.anchosen-search-input').off('.anchosen')
				@$el.empty().append(@restoreContents)
				@restoreContents = null
				@$el.attr('tabindex', @tabIndex) if @restoreTabIndex
				@viewModel.dispose()
				ko.applyBindings {}, @$el[0]
				@$el.undelegate '.anchosen'
				@$el = null
				@$searchField = null
				@$searchBox = null
				@$container = null
				@$window.off ".anchosen#{@id}"
				@$window = null
				@viewModel = null
				@disposed = true
				@restoreTabIndex = null
				@tabIndex = null