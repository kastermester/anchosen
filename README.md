# Anchosen - The other chosen library #

[Chosen by HarvestHQ](https://github.com/harvesthq/chosen) is a great library for creating better HTML &lt;select&gt;'s.
However, as they are so awesome, one starts to use the HTML select tag for things it was never meant to do.

Anchosen is a library that attempts to recreate the look & feel of Chosen, but without trying to limit itself to the boundaries
of the HTML select tags capabilities. It is implemented in [KnockoutJS](http://www.knockoutjs.com) and [jQuery](http://www.jquery.com).

Anchosen is still in heavy development, and far from feature complete. Here is a list of goals that I hope to achieve:

  * Support for showing the drop-down on either to the top or the bottom of the "input" field - depending on where there is room.
  * Support for server side fetching of the drop-down elements.
  * Support for on-the-fly user creation of items for selection.

To begin with, I plan to implement only the multiple select capabilities of Chosen - as for most operations I have come across,
Chosen works exceptionally well for single selection in most cases.


## Usage ##

In its simplest form, Anchosen can be used as a jQuery plugin. Create a &lt;div&gt; element and assign it a width:

```html
<div class="my-anchosen" style="width: 250px">Loading anchosen...</div>
```

Now - after having loaded the Anchosen library simply call the `anchosen` method. There are only two required options:

  * options: An array of available options in the Anchosen.
  * selected: An array of selected options in the Anchosen.

Both `options` and `selected` are objects that take form like so:

```json
{
	"label": "Label here...",
	"value": "Value here..."
}
```

As an example, here is how to setup a new Anchosen with three options and a single selected option:

```javascript
$('.my-anchosen').anchosen({
	options:
	[
		{ "label": "Pizza", "value": "pz" },
		{ "label": "Spaghetti", "value": "sp" },
		{ "label": "Lasagne", "value": "ls" }
	],
	selected: [
		{ "label": "Spaghetti", "value": "sp" }
	]
});
```

This is all very good - however, often it might be useful to show a hint regarding what is to be selected - enter the `placeholder` option! This allows you to place placeholder text in your Anchosen when no option is selected, alas you can now write:

 ```javascript
$('.my-anchosen').anchosen({
	options:
	[
		{ "label": "Pizza", "value": "pz" },
		{ "label": "Spaghetti", "value": "sp" },
		{ "label": "Lasagne", "value": "ls" }
	],
	selected: [
		{ "label": "Spaghetti", "value": "sp" }
	],
	placeholder: 'Select your favorite Italian foods...'
});
```

There's plenty of options to set when working with Anchosen - here is a complete list, and their default values:

```javascript
{
	selected: [], // The selected options when Anchosen is created
	options: [], // The options to choose from in this Anchosen
	placeholder: '', // The placeholder text when no option is selected
	// Anchosen supports a concept called 'Choose following'
	// It inserts a special choose following option that the user can choose from when searching -
	// this option will select all options that are being shown in the available options menu when clicked
	chooseFollowingText: 'Choose following', // The text shown for the choose following option
	chooseFollowingThreshold: 7, // The maximum amount of elements that can be shown while the choose following option is visible. Set to 0 to disable threshold
	chooseFollowingEnabled: true, // Enable the choose following option?
	// In order to support a 'tag box' style Anchosen, Anchosen supports letting the user create new options
	createNewEnabled: false, // Enable creation of new options?
	createNewText: 'Create new \'{0}\'', // Text to be shown for the create new option. Use {0} to insert the user entered text
	// When creating a new option - Anchosen must know how to turn the user entered text into a new option.
	// Call the callback function with the option to let Anchosen do its magic.
	createNewHandler: function(text, callback){
		callback({
			label: text
			value: null
		});
	},
	substringMatch: false, // Default matching algorithm is String.startsWith (case insensitive). Change this to true to enable case insensitive substring matching instead.
	maximumSelectionsAllowed: 0, // Set a maximum of how many selections can be made. 0 Means no limit
	maximumSelectionsReachedText: 'Maximum of {0} items reached' // Set the text to be shown once the limit has been reached.
}
```

### API methods ###

Once an Anchosen has been created, there are a couple of jQuery API methods available for you to work with. All of these are called by reapplying the `anchosen` jQuery plugin method.

  * `refresh` - Recalculates positioning and size of the various elements in Anchosen. There really shouldn't be a need to call this manually, unless you host Anchosen inside a container that supports resizing. Anchosen will recalculate its size if the window is resized.
  * `value` - Gets the selected options in the Anchosen.
  * `destroy` - Disposes of the Anchosen and leaves the DOM in the state it was found prior to creating anchosen.
  * `viewmodel` - Gets the KnockoutJS view model being used with this Anchosen. Using this model a ton of possibilities will be available to you - however, this requires great knowledge of how Anchosen is coded, so use with care.