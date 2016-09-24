React             = require 'react'
TextTool          = require '../text-tool'

SelectOneTool = React.createClass
  displayName: 'SelectOneTool'

  render: ->
    # Everything about a textarea-tool is identical in text-tool, so let's parameterize text-tool
    <TextTool {...@props} inputType='select-one'/>

module.exports = SelectOneTool
