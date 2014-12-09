class ResourceView extends Backbone.View
  onFilter: (filter) ->
    if filter.length < 2
      @.$el.show()
      @.$el.removeClass 'active'
      @.$el.children('ul').hide()
      @.$el.children('ul li').show()
      return

    regex = new RegExp filter

    show = false;
    $.each @model.operations, (i, op) ->
      if regex.test op.path
        show = true

    if show
      @.$el.show()
      @.$el.addClass 'active'
      @.$el.children('ul').show()
    else
      @.$el.hide()

  onChildFound: (name) ->
    @.$el.children('ul').show()

  initialize: (opts={}) ->
    @auths = opts.auths
    if "" is @model.description 
      @model.description = null

    eventBus.on 'filter', @onFilter, @
    eventBus.on 'childFound', @onChildFound, @

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
