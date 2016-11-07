React = require 'react'
{Link} = require 'react-router'
API = require 'lib/api'
SocialShare   = require 'components/social-share'

Pagination = require 'components/core-tools/pagination'
LoadingIndicator   = require 'components/loading-indicator'


module.exports = React.createClass
  displayName: "BrowsePanel"    

  componentDidMount: ->
    @fetchSubjects()

  getInitialState: ->
    page: 1
    limit: 5
    subjects: []
    selected_category: ""
    entered_keyword: ""
    loading: false

  fetchSubjects: ->
    params =
      page:   @state.page
      limit:  @state.limit
      status: 'complete'

    if @state.selected_category != ""
      params = $.extend(params, { "data.category": @state.selected_category });

    if @state.entered_keyword.trim() != ""
      params = $.extend(params, { "text": @state.entered_keyword });

    @setState loading: true
    API.type('subjects').get(params).then (subjects) =>
      if subjects.length is 0
        @setState 
          noMoreSubjects: true
          loading: false
      else
        @setState
          subject_index: 0
          subjects_next_page: subjects[0].getMeta("next_page")
          subjects_prev_page: subjects[0].getMeta("prev_page")
          subjects_total_results: subjects[0].getMeta("total")
          subjects_current_page: subjects[0].getMeta("current_page")
          subjects_total_pages: subjects[0].getMeta("total_pages")
          subjects: subjects
          noMoreSubjects: false
          loading: false

  handleKeyPress: (e) ->
    if @isMounted()
      if [13].indexOf(e.keyCode) >= 0 # ENTER:
        @fetchSubjects

  handleKeywordChange: (e) ->
    @setState entered_keyword: e.target.value

  handleCategorySelect: (e) ->
    @setState selected_category: e.target.value

  gotoPage: (page) ->
    @state.page = page
    @fetchSubjects()

  render: ->
    <div className="browse">
      <form>
        <div className="search-field">
          <select ref="search_category" value={@state.selected_category} onChange={@handleCategorySelect}>
            <option value="">All</option>
            { for option, i in @props.categoryOptions
                <option key={i} value={option.value}>{option.label}</option>
            }
          </select>
        </div>
        <div className="search-field">
          <input id="data-search" type="text" placeholder="Enter keywords" ref="search_input" value={@state.entered_keyword} onChange={@handleKeywordChange} onKeyDown={@handleKeyPress} />
          <button className="standard-button" onClick={@fetchSubjects}>Search</button>
        </div>
      </form>

      { if @state.loading
          <div className="classifier">
              <LoadingIndicator />
          </div>
        else if @state.noMoreSubjects
          <div>No pictures found.</div>
        else
          <div>
            <div className="browse-nav row">
              <Pagination currentPage={@state.subjects_current_page}
                nextPage={@state.subjects_next_page}
                previousPage={@state.subjects_prev_page}
                onClick={@gotoPage}
                totalPages={@state.subjects_total_pages}/>
            </div>
            <div className="browse-group columns">
               <div className="row small-up-2 medium-up-4 large-up-5">
                  {
                   for subj, index in @state.subjects
                      viewURL = "#{location.origin}/#/view/#{subj.id}"
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
                        <Link to="/view/#{subj.id}">
                          <img src="#{subj.meta_data.subject_url}image_#{width}x#{height}_from_#{x1},#{y1}_to_#{x2},#{y2}.jpg" className="#{orientation}"/>
                        </Link>
                        
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
            <div className="browse-nav row">
              <Pagination currentPage={@state.subjects_current_page}
                nextPage={@state.subjects_next_page}
                previousPage={@state.subjects_prev_page}
                onClick="@gotoPage"
                totalPages={@state.subjects_total_pages}/>
            </div>
          </div>

      }
   </div>
