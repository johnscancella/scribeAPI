React = require 'react'
{Navigation} = require 'react-router'
{Link} = require 'react-router'
API = require 'lib/api'

GenericButton = require 'components/buttons/generic-button'
Pagination = require 'components/core-tools/pagination'


module.exports = React.createClass
  displayName: "BrowsePanel"
  mixins: [Navigation]

  getDefaultProps: ->
    page: 1
    browse: true
    limit: 5
    status: 'complete'
    show_pagination: true

  componentDidMount: ->
    @fetchSubjects @props

  componentWillReceiveProps: (newProps) ->
    if @props.page != newProps.page
      @fetchSubjects newProps

  getInitialState: ->
    subjects: []

  fetchSubjects: (params, callback) ->
    API.type('subjects').get(params).then (subjects) =>
      if subjects.length is 0
        @setState noMoreSubjects: true

      else
        @setState
          subject_index: 0
          subjects_next_page: subjects[0].getMeta("next_page")
          subjects_prev_page: subjects[0].getMeta("prev_page")
          subjects_total_results: subjects[0].getMeta("total")
          subjects_current_page: subjects[0].getMeta("current_page")
          subjects_total_pages: subjects[0].getMeta("total_pages")
          subjects: subjects

      # Does including instance have a defined callback to call when new subjects received?
      if @fetchSubjectsCallback?
        @fetchSubjectsCallback()

  render: ->
    if @props.show_pagination
      pagination =  <div className="browse-nav row">
          <Pagination currentPage={@state.subjects_current_page}
            nextPage={@state.subjects_next_page}
            previousPage={@state.subjects_prev_page}
            urlBase="/gallery"
            totalPages={@state.subjects_total_pages}/>
        </div>
    else
      pagination = <span/>

    <div className="browse">
      { pagination }
      <div className="browse-group columns">
         <div className="row small-up-2 medium-up-4 large-up-5 align-center">
            {
             for subj, index in @state.subjects
                resize_factor = if subj.meta_data.resize? then subj.meta_data.resize else 1
                x1 = Math.round(subj.region.x / resize_factor)
                y1 = Math.round(subj.region.y / resize_factor)
                x2 = Math.round((subj.region.x + subj.region.width) / resize_factor)
                y2 = Math.round((subj.region.y + subj.region.height) / resize_factor)
                full_width = Math.round(subj.region.width / resize_factor)
                full_height = Math.round(subj.region.height / resize_factor)
                width = 1000
                height = Math.round(subj.region.height / subj.region.width * width)
                orientation = "square"
                if subj.region.width / subj.region.height > 1.3
                  orientation = "landscape"
                if subj.region.height / subj.region.width > 1.3
                  orientation = "portrait"
                <div className="column" key={index}>
                  <a href="#{subj.meta_data.subject_url}image_#{full_width}x#{full_height}_from_#{x1},#{y1}_to_#{x2},#{y2}.jpg">
                    <img src="#{subj.meta_data.subject_url}image_#{width}x#{height}_from_#{x1},#{y1}_to_#{x2},#{y2}.jpg" className="#{orientation}"/>
                  </a>
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
            }
          </div>
      </div>
      { pagination }
   </div>
