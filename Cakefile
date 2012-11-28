fs = require 'fs'
path = require 'path'
spawn = require('child_process').spawn

cwd = __dirname + '/'

rjs = (cont) ->
	requirejs = require 'requirejs'
	config =
		appDir: 'bin'
		dir: 'build'
		baseUrl: 'js'
		keepBuildDir: true
		skipDirOptimize: true
		optimize: "none"
		useStrict: true
		removeCombined: true
		modules: [
			{
				name: 'anchosen'
				exclude: ['knockout', 'jquery', 'underscore']
			}
		]
		paths:
			jquery: "jquery"
			knockout: "knockout"
			underscore: "underscore"
		shim:
			underscore:
				exports: "_"


	requirejs.optimize config, (buildResponse) ->
		config =
			appDir: 'bin'
			dir: 'build_min'
			baseUrl: 'js'
			keepBuildDir: true
			skipDirOptimize: false
			optimize: "uglify2"
			useStrict: true
			removeCombined: true
			optimizeCss: "standard"
			modules: [
				{
					name: 'anchosen'
					exclude: ['knockout', 'jquery', 'underscore']
				}
			]
			paths:
				jquery: "jquery"
				knockout: "knockout"
				underscore: "underscore"
			shim:
				underscore:
					exports: "_"
		requirejs.optimize config, (buildResponse) ->
			cont?()

exec = (command, args, env, cont) ->
	env.stdio = 'inherit'
	proc = spawn(command, args, env)

	proc.on 'exit', (code) ->
		cont?() if code == 0

deps = (cont) ->
	console.log 'Compiling dependencies...'
	knockoutSource = fs.createReadStream cwd + 'vendor/knockout/build/output/knockout-latest.debug.js'
	knockoutDest = fs.createWriteStream cwd + 'bin/js/knockout.js'
	knockoutSource.pipe knockoutDest
	knockoutDest.on 'close', () ->
		underscoreSource = fs.createReadStream cwd + 'vendor/underscore/underscore.js'
		underscoreDest = fs.createWriteStream cwd + 'bin/js/underscore.js'
		underscoreSource.pipe underscoreDest
		underscoreDest.on 'close', () ->
			exec 'node_modules/grunt/bin/grunt', [], {
				cwd: cwd + 'vendor/jquery'
			}, () ->
				fs.renameSync cwd + 'vendor/jquery/dist/jquery.js', 'bin/js/jquery.js'

				requirejsSource = fs.createReadStream cwd + '/vendor/requirejs/require.js'
				requirejsDest = fs.createWriteStream cwd + '/bin/js/require.js'
				requirejsSource.pipe requirejsDest
				requirejsDest.on 'close', () ->
					cont?()

deleteDir = (dir, cont) ->
	if fs.existsSync dir
		exec 'rm', ['-R', dir], {}, (stdout) ->
			cont?()
	else
		cont?()

clean = (cont) ->
	console.log 'Cleaning bin/ dir'
	deleteDir 'bin', () ->
		fs.mkdirSync 'bin'
		fs.mkdirSync 'bin/js'
		fs.mkdirSync 'bin/css'

		deleteDir 'build', () -> deleteDir 'build_min', () -> cont?()


build = (cont) ->
	console.log 'Building Anchosen...'
	compile_coffee () -> compile_less()

compile_less = (cont) ->
	console.log 'Compiling .less files...'
	exec 'node_modules/less/bin/lessc', ['src/less/anchosen.less', 'bin/css/anchosen.css'], {}, (stdout) ->
		cont?()

compile_coffee = (cont) ->
	console.log 'Compiling .coffee files...'
	exec 'node_modules/coffee-script/bin/coffee', ['--bare', '-co', 'bin/js', 'src/coffee'], {}, (stdout) ->
		cont?()

setup = (cont) ->
	console.log 'Initting git submodules...'
	exec 'git', ['submodule', 'update', '--init', '--recursive'], {}, () -> cont?()

npm = (cont) ->
	console.log 'Running npm install...'
	exec 'npm', ['install'], {}, (stdout) ->
		exec 'npm', ['install'], { cwd: 'vendor/jquery' }, (stdout) ->
			cont?()

option '-p', '--port [PORT]', 'Sets the port number to use in the example server, defaults to 8080'


task 'all', 'compiles all of them!', () ->
	clean () ->
		setup () ->
			npm () ->
				deps () -> build()

task 'deps', 'compiles vendor libraries', () ->
	deps()

task 'build', 'compiles the project itself', () ->
	build()

task 'clean', 'cleans the bin directory', () ->
	clean()

task 'rjs', 'RequireJSs the library', () ->
	rjs()

task 'setup', 'Sets up git submodules and runs npm install', () ->
	setup () -> npm()


task 'serve', 'Fire up a webserver for use with the example files', (options) ->
	port = if options.port? then parseInt options.port else 8080
	console.log "Server started on port #{port} - see http://localhost:#{port}/examples/example.html for an example run"
	exec "node_modules/coffee-script/bin/coffee", ['examples/server.coffee', "--port #{port}"], {}