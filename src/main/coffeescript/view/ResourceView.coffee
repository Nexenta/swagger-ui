class ResourceView extends Backbone.View
  onFilter: (filter) ->
    items = filter.split '/'
    regex = new RegExp items[0]

    if regex.test @model.name
      @.$el.show()
    else
      @.$el.hide()

    if items.length > 1
      @.$el.children('ul').show()
    else
      @.$el.children('ul').hide()

  initialize: (opts={}) ->
    @auths = opts.auths
    if "" is @model.description 
      @model.description = null

    eventBus.on 'filter', @onFilter, @

  render: ->
    $(@el).html(Handlebars.templates.resource(@model))

    methods = {}

    if @model.description
      @model.summary = @model.description

    # Render each operation
    cmp = (a, b) ->
      a_ = a.path.replace(/\{\w*\}/g, '{}')
      b_ = b.path.replace(/\{\w*\}/g, '{}')
      a_.localeCompare(b_)

    ops = @model.operationsArray.sort(cmp)
    for operation in ops
      counter = 0

      id = operation.nickname
      while typeof methods[id] isnt 'undefined'
        id = id + "_" + counter
        counter += 1

      methods[id] = operation

      operation.nickname = id
      operation.parentId = @model.id
      @addOperation operation 

    $('.toggleEndpointList', @el).click(this.callDocs.bind(this, 'toggleEndpointListForResource'))
    $('.collapseResource', @el).click(this.callDocs.bind(this, 'collapseOperationsForResource'))
    $('.expandResource', @el).click(this.callDocs.bind(this, 'expandOperationsForResource'))
    
    return @

  addOperation: (operation) ->

    operation.number = @number

    # Render an operation and add it to operations li
    operationView = new OperationView({
      model: operation,
      tagName: 'li',
      className: 'endpoint',
      swaggerOptions: @options.swaggerOptions,
      auths: @auths
    })
    $('.endpoints', $(@el)).append operationView.render().el

    @number++

  #
  # Generic Event handler (`Docs` is global)
  #

  callDocs: (fnName, e) ->
    e.preventDefault()
    Docs[fnName](e.currentTarget.getAttribute('data-id'))
