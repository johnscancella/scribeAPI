React = require 'react'
API = require 'lib/api'
SocialShare   = require 'components/social-share'


module.exports = React.createClass
  displayName: "ViewPanel"

  getInitialState: ->
    subject: null

  componentWillMount: ->
    @fetchSubject @props

  fetchSubject: ->
    API.type('subjects').get(@props.subject_id).then (subject) =>
      @setState subject: subject

  render: ->
    subj = @state.subject
    if subj?
      <div className="browse">
        <div className="browse-group columns">
          <div className="row">
            {
              resize_factor = if subj.meta_data.resize? then subj.meta_data.resize else 1
              x1 = Math.round(subj.region.x / resize_factor)
              y1 = Math.round(subj.region.y / resize_factor)
              x2 = Math.round((subj.region.x + subj.region.width) / resize_factor)
              y2 = Math.round((subj.region.y + subj.region.height) / resize_factor)
              full_width = Math.round(subj.region.width / resize_factor)
              full_height = Math.round(subj.region.height / resize_factor)
              width = 1000
              height = Math.round(subj.region.height / subj.region.width * width)
              <div className="column">
                
                <img src="#{subj.meta_data.subject_url}image_#{width}x#{height}_from_#{x1},#{y1}_to_#{x2},#{y2}.jpg" className="large"/>

                <div className="item-description">
                  {
                    if subj.data.caption
                      <div className="caption">
                        {subj.data.caption}
                      </div>
                  }
                  {
                    if subj.data.creator
                      <div className="creator">
                        By {subj.data.creator}
                      </div>
                  }
                  {
                    if subj.data.category
                      <div className="category">
                        {subj.data.category}
                      </div>
                  }
                  {
                    if subj.meta_data.subject_description
                      <div className="citation">
                        Appeared in <a href="#{subj.meta_data.subject_url}" target="_blank">{subj.meta_data.subject_description}</a>
                      </div>
                  }
                </div>

                <SocialShare url="#{location.origin}/#/view/#{subj.id}"/>

              </div>
            }
          </div>
        </div>
      </div>
    else
      <div className="browse"/>
