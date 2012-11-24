fs = require 'fs'
nodejs_exec = require('child_process').exec

cwd = __dirname + '/'

exec = (command, env, cont) ->
	nodejs_exec command, env, (error, stdout, stderr) ->
		console.log "Error running command: #{command}" if error?
		console.log error if error?
		return console.log stderr if error?
		cont(stdout) if cont?

deps = (cont) ->
	knockoutSource = fs.createReadStream cwd + 'vendor/knockout/build/output/knockout-latest.debug.js'
	knockoutDest = fs.createWriteStream cwd + 'bin/js/knockout.js'
	knockoutSource.pipe knockoutDest
	knockoutDest.on 'close', () ->
		underscoreSource = fs.createReadStream cwd + 'vendor/underscore/underscore.js'
		underscoreDest = fs.createWriteStream cwd + 'bin/js/underscore.js'
		underscoreSource.pipe underscoreDest
		underscoreDest.on 'close', () ->
			exec 'grunt', {
				cwd: cwd + 'vendor/jquery'
			}, () ->
				fs.renameSync cwd + 'vendor/jquery/dist/jquery.js', 'bin/js/jquery.js'

				requirejsSource = fs.createReadStream cwd + '/vendor/requirejs/require.js'
				requirejsDest = fs.createWriteStream cwd + '/bin/js/require.js'
				requirejsSource.pipe requirejsDest
				requirejsDest.on 'close', () ->
					cont() if cont?

clean = (cont) ->
	makeDirs = () ->
		fs.mkdirSync 'bin'
		fs.mkdirSync 'bin/js'
		fs.mkdirSync 'bin/css'

		cont() if cont?

	if fs.existsSync 'bin'
		exec 'rm -R bin', {}, (stdout) ->
			makeDirs()

	else
		makeDirs()


build = (cont) ->
	compile_coffee () -> compile_less()

compile_less = (cont) ->
	exec 'lessc src/less/anchosen.less bin/css/anchosen.css', {}, (stdout) ->
		cont() if cont?

compile_coffee = (cont) ->
	exec 'coffee -co bin/js src/coffee', {}, (stdout) ->
		cont() if cont?

task 'all', 'compiles all of them!', () ->
	clean () ->
		deps () -> build()

task 'deps', 'compiles vendor libraries', () ->
	deps()

task 'build', 'compiles the project itself', () ->
	build()

task 'clean', 'cleans the bin directory', () ->
	clean()