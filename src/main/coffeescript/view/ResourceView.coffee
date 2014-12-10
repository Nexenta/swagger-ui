class ResourceView extends Backbone.View
  onFilter: (filter) ->
    if filter.length < 3
      @visible = true
      @hideChildren()
      @.$el.show()
      return

    if @.$el.is(':visible')
      @visible = false
      @.$el.hide()

  onChildFound: (name) ->
    if !@visible
      @.$el.show()
      @.$el.addClass('active');
      @.$el.children('ul').show()
      @visible = true;

  hideChildren: ->
    if @visible
      @.$el.children('ul.endpoints').hide()
      @.$el.children('ul.endpoints').children('li').show()
      @.$el.removeClass('active');
      @visible = false;

  initialize: (opts={}) ->
    @auths = opts.auths
    if "" is @model.description 
      @model.description = null

    @visible = true
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
      auths: @auths,
      parentView: @
    })
    $('.endpoints', $(@el)).append operationView.render().el

    @number++

  #
  # Generic Event handler (`Docs` is global)
  #

  callDocs: (fnName, e) ->
    e.preventDefault()
    Docs[fnName](e.currentTarget.getAttribute('data-id'))
