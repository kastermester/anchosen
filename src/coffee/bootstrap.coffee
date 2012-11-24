requirejs.config
	baseUrl: 'bin/js'
	paths: {
		"jquery": "jquery"
		"knockout": "knockout"
		"underscore": "underscore"
	},
	shim: {
		"underscore":
			{ "exports": "_" }
	}