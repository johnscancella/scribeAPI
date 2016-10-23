React = require 'react'
{Navigation} = require 'react-router'
{Link} = require 'react-router'

BrowsePanel = require './browse-panel'
 
module.exports = React.createClass
  displayName: "Browse"
  mixins: [Navigation]
  
  render: ->
    <div className='page-content custom-page'>
      <div>
        <h2>Picture Gallery</h2>
        <BrowsePanel page={@props.params.page} show_pagination={true} />
      </div>
    </div>           
 
