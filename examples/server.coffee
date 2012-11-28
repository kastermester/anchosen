express = require 'express'
path = require 'path'
optimist = require 'optimist'
fs = require 'fs'
CoffeeScript = require 'coffee-script'
less = require 'less'

app = express()

port = 8080

args = optimist.argv

if args['port']
	port = parseInt args['port']

root = path.join __dirname, '..'


coffeeStatic = (root, sourceRoot = root) ->
	expressStatic =	express.static(root)
	(req, res, next) ->
		reqPath = req.path.substring 1

		idx = reqPath.lastIndexOf('.')

		if idx > -1
			ext = reqPath.substring idx
			if ext == '.js'
				reqPath = path.join sourceRoot, (reqPath.substring(0, idx) + '.coffee')
				if fs.existsSync reqPath
					js = CoffeeScript.compile fs.readFileSync(reqPath, 'utf-8').toString(), bare: true, filename: path.basename reqPath
					res.writeHead 200, {'Content-Type': 'application/javascript' }
					res.end(js)
					return
			if ext == '.css'
				reqPath = path.join sourceRoot, (reqPath.substring(0, idx) + '.less')
				if fs.existsSync reqPath
					parser = new(less.Parser)(
						paths: [path.dirname reqPath],
						fileName: path.basename reqPath
						optimization: 0
						strictImports: true
					)
					parser.parse fs.readFileSync(reqPath, 'utf-8'), (err, tree) ->
						if err?
							res.writeHead 500
							return res.end(err) 
						css = tree.toCSS({yuicompress: false})
						res.writeHead 200, {'Content-Type': 'text/css' }
						res.end(css)
					return
		expressStatic(req, res, next)

app.use '/bin/js', coffeeStatic (path.join root, 'bin/js'), (path.join root, 'src/coffee')
app.use '/bin/css', coffeeStatic (path.join root, 'bin/css'), (path.join root, 'src/less')
app.use '/examples', coffeeStatic path.join root, 'examples'

app.listen port