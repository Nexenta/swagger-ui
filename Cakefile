fs          = require 'fs'
{exec}      = require 'child_process'
less        = require 'less'
handlebars  = require 'handlebars'

sourceFiles  = [
  'SwaggerUi'
  'view/HeaderView'
  'view/MainView'
  'view/ResourceView'
  'view/OperationView'
  'view/StatusCodeView'
  'view/ParameterView'
  'view/SignatureView'
  'view/ContentTypeView'
  'view/ResponseContentTypeView'
  'view/ParameterContentTypeView'
  'view/ApiKeyButton'
  'view/BasicAuthButton'
]


task 'clean', 'Removes distribution', ->
  console.log 'Clearing dist...'
  exec 'rm -rf dist'

task 'dist', 'Build a distribution', ->
  console.log "Build distribution in ./dist"
  fs.mkdirSync('dist') if not fs.existsSync('dist')
  fs.mkdirSync('dist/lib') if not fs.existsSync('dist/lib')

  appContents = new Array remaining = sourceFiles.length
  for file, index in sourceFiles then do (file, index) ->
    console.log "   : Reading src/main/coffeescript/#{file}.coffee"
    fs.readFile "src/main/coffeescript/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      precompileTemplates() if --remaining is 0

  precompileTemplates= ->
    console.log '   : Precompiling templates...'
    templateFiles  = fs.readdirSync('src/main/template')
    templateContents = new Array remaining = templateFiles.length
    for file, index in templateFiles then do (file, index) ->
      console.log "   : Compiling src/main/template/#{file}"
      fs.readFile "src/main/template/#{file}", 'utf8', (err, source) ->
        throw err if err
        compiled = handlebars.precompile(source)
        templateContents[index] = '(function() {\n  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};\ntemplates[\'' + file.replace('.handlebars', '') + '\'] = template(' + compiled + ');\n})();'
        fs.unlink 'dist/_' + file + '.js', (err) ->
          console.log "#{err.code}: #{err.path}" unless err.code == 'ENOENT'
        if --remaining is 0
          templateContents.push '\n\n'
          fs.writeFile 'dist/_swagger-ui-templates.js', templateContents.join('\n\n'), 'utf8', (err) ->
            throw err if err
            build()

  build = ->
    console.log '   : Collecting Coffeescript source...'

    appContents.push '\n\n'
    fs.writeFile 'dist/_swagger-ui.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      console.log '   : Compiling...'
      exec 'coffee --compile dist/_swagger-ui.coffee', (err, stdout, stderr) ->
        throw err if err
        fs.unlink 'dist/_swagger-ui.coffee'
        console.log '   : Combining with javascript...'

        fs.readFile 'package.json', 'utf8', (err, fileContents) ->
          obj = JSON.parse(fileContents)
          exec 'echo "// swagger-ui.js" > dist/swagger-ui.js'
          exec 'echo "// version ' + obj.version + '" >> dist/swagger-ui.js'
          exec 'cat src/main/javascript/doc.js dist/_swagger-ui-templates.js dist/_swagger-ui.js >> dist/swagger-ui.js', (err, stdout, stderr) ->
            throw err if err
            fs.unlink 'dist/_swagger-ui.js'
            fs.unlink 'dist/_swagger-ui-templates.js'
            console.log '   : Minifying all...'
            exec 'java -jar "./bin/yuicompressor-2.4.7.jar" --type js -o ' + 'dist/swagger-ui.min.js ' + 'dist/swagger-ui.js', (err, stdout, stderr) ->
              throw err if err
              lessc()

  lessc = ->
    # Someone who knows CoffeeScript should make this more Coffee-licious
    console.log '   : Compiling LESS...'

    less.render fs.readFileSync("src/main/less/screen.less", 'utf8'), (err, css) ->
      fs.writeFileSync("src/main/html/css/screen.css", css)
    less.render fs.readFileSync("src/main/less/reset.less", 'utf8'), (err, css) ->
      fs.writeFileSync("src/main/html/css/reset.css", css)
    pack()

  pack = ->
    console.log '   : Packaging...'
    exec 'cp -r lib dist'
    console.log '   : Copied swagger-ui libs'
    # exec 'cp -r node_modules/swagger-client/lib/swagger.js dist/lib'
    # console.log '   : Copied swagger dependencies'
    exec 'cp -r src/main/html/* dist'
    console.log '   : Copied html dependencies'
    console.log '   !'

task 'spec', "Run the test suite", ->
  exec "open spec.html", (err, stdout, stderr) ->
    throw err if err

task 'watch', 'Watch source files for changes and autocompile', ->
  # Function which watches all files in the passed directory
  watchFiles = (dir) ->
    files = fs.readdirSync(dir)
    for file, index in files then do (file, index) ->
      console.log "   : " + dir + "/#{file}"
      fs.watchFile dir + "/#{file}", (curr, prev) ->
        if +curr.mtime isnt +prev.mtime
          invoke 'dist'

  notify "Watching source files for changes..."

  # Watch specific source files
  for file, index in sourceFiles then do (file, index) ->
    console.log "   : " + "src/main/coffeescript/#{file}.coffee"
    fs.watchFile "src/main/coffeescript/#{file}.coffee", (curr, prev) ->
      if +curr.mtime isnt +prev.mtime
        invoke 'dist'

  # watch all files in these folders
  watchFiles("src/main/template")
  watchFiles("src/main/javascript")
  watchFiles("src/main/html")
  watchFiles("src/main/less")
  watchFiles("src/test")

notify = (message) ->
  return unless message?
  console.log message
#  options =
#    title: 'CoffeeScript'
#    image: 'bin/CoffeeScript.png'
#  try require('growl') message, options
