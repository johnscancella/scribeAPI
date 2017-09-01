React = require 'react'
{Navigation} = require 'react-router'
{Link} = require 'react-router'

BrowsePanel = require './browse-panel'
BaseWorkflowMethods     = require 'lib/workflow-methods-mixin'
 
module.exports = React.createClass
  displayName: "Browse"
  mixins: [Navigation, BaseWorkflowMethods]
  
  render: ->
    for option, i in @getWorkflowByName('transcribe').tasks.illustration.tool_config.options
      if option.value == 'category'
        categoryOptions = option.tool_config.options
    <div className='page-content custom-page'>
      <h1>Picture Gallery</h1>
      <div>
        <BrowsePanel categoryOptions={categoryOptions} />
      </div>
    </div>           
 
