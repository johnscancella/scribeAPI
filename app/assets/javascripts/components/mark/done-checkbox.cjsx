# @cjsx React.DOM

React = require 'react'

module.exports = React.createClass
  displayName: 'DoneCheckbox'

  getInitialState: ->
    markStatus: @props.markStatus

  # componentWillReceiveProps: ->
    # @setState
    #   markComplete: @props.markComplete
    #   transcribeComplete: @props, =>
    #     if @props.markComplete and not @props.transcribeComplete 
    #       @setState 
    #         # fillColor: 'rgba(100,200,50,1.0)'
    #         buttonLabel: "TRANSCRIBE"
    #     if @props.markComplete and @props.transcribeComplete
    #       @setState fillColor: 'rgba(100,200,50,1.0)'
            
  render: ->
    fillColor    = 'rgba(100,200,50,0.2)'
    strokeColor  = 'rgb(0,0,0)'
    strokeWidth  = 4
    borderRadius = 10
    width        = 200
    height       = 40
    
    markStatus = @props.markStatus
    switch markStatus
      when 'mark'
        fillColor = 'rgba(100,200,50,0.2)'
        buttonLabel = 'DONE.'
      when 'mark-finished'
        fillColor = 'rgba(100,200,50,0.6)'
        buttonLabel = 'TRANSCRIBE'
      when 'transcribe'
        fillColor = 'rgba(80,80,80,0.6)'
        buttonLabel = 'SUBMIT'
      when 'transcribe-finished'
        fillColor = 'rgba(100,200,50,1.0)'
        buttonLabel = 'COMPLETE'
      else
        console.log 'WARNING: Unknown state in DoneCheckbox.render()'

    <g 
      onClick     = {@props.onClickMarkButton}
      transform   = {@props.transform} 
      className   = "clickable drawing-tool-done-button" 
      stroke      = {strokeColor} 
      strokeWidth = {strokeWidth} >
      <rect 
        transform = "translate(0,-5)"
        rx        = "#{borderRadius}" 
        ry        = "#{borderRadius}" 
        width     = "#{width}" 
        height    = "#{height}" 
        fill      = "#{fillColor}" />
      <text
        transform = "translate(12,24)"
        fontSize  = "26">
        {buttonLabel}
      </text>
    </g>