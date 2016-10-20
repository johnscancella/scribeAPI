module.exports =

  skipToNext: ->
    @clearAnnotation()
    @commitAnnotation()

  clearAnnotation: ->
    @state.annotation = {}
    @props.clearAnnotation()
