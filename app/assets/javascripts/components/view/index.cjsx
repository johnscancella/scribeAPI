React = require 'react'
{Navigation} = require 'react-router'
{Link} = require 'react-router'

ViewPanel = require './view-panel'
 
module.exports = React.createClass
  displayName: "View"
  mixins: [Navigation]
  
  render: ->
    <div className='page-content custom-page'>
      <div>
        <ViewPanel subject_id={@props.params.subject_id}/>
      </div>
    </div>           
 
