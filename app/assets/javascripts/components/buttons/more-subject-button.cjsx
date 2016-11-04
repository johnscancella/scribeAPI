React         = require 'react'
SmallButton   = require './small-button'

module.exports = React.createClass
  displayName: 'MoreSubjectButton'

  render: ->
    label = @props.label ? 'More to Mark'
    if not @props.active then label = label + "?"

    additional_classes = []
    additional_classes.push 'toggled' if @props.active
    additional_classes.push @props.className if @props.className?
    <SmallButton key="more-subject-button" label={label} onClick={@props.onClick} className="ghost toggle-button #{additional_classes.join(' ')}" />