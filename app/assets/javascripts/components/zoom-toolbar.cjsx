React                         = require 'react'
SubjectZoomPan                = require 'components/subject-zoom-pan'
{Link}                        = require 'react-router'


module.exports = React.createClass
  displayName: "ZoomToolbar"

  getInitialState: ->
    zoomPanViewBox: @props.viewBox
    active_pane: ''
    hideMarks: true

  togglePane: (name) ->
    if @state.active_pane == name
      @setState active_pane: ''
      @props.onHide()
    else
      @setState active_pane: name
      @props.onExpand()

  componentWillMount: ->
    # reset parent's state
    @props.onZoomChange null
    @props.onHide()

  render: ->
    <div className="subject-set-toolbar">
      <div className="subject-set-toolbar-panes">
        <div className={"pan-zoom-area pan-zoom pane" + if @state.active_pane == 'pan-zoom' then ' active' else '' }>
          <SubjectZoomPan subject={@props.subject} onChange={@props.onZoomChange} viewBox={@state.zoomPanViewBox}/>
        </div>
      </div>
      <div className="subject-set-toolbar-links">
        <a className={"toggle-pan-zoom" + if @state.active_pane == 'pan-zoom' then ' active' else '' } onClick={() => @togglePane 'pan-zoom'}><div className="helper">Toggle pan and zoom tool</div></a>
      </div>
    </div>
