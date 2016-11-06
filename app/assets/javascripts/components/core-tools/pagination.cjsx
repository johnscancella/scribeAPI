React = require 'react'
{Link} = require 'react-router'

Page = React.createClass
  displayName: 'Page'

  getDefaultProps: ->
    pagenum: null
    hide: false

  clicked: (pageNumber) ->
    @props.onClick pageNumber

  render: ->
    <li key={@props.pagenum} className="#{'hide' if @props.hide}">
      <a onClick={@clicked.bind(this, @props.pagenum)} ariaLabel="Page #{@props.pagenum}">{@props.pagenum}</a>
    </li>



module.exports = React.createClass
  displayName: 'Pagination'

  getDefaultProps: ->
    totalPages: 1
    currentPage: 0
    nextPage: null
    previousPage: null
    leftsidePages: 2  # How many items to show in the left side of the pagination list: 1, 2, [3]
    rightsidePages: 2 # How many items to show in the left side of the pagination list: [50] 50, 51 ... 100

  clicked: (pageNumber) ->
    @props.onClick pageNumber
    
  render: ->
    lefts = []
    rights = []
    lastPage = @props.totalPages
    largestPage = Math.min [@props.currentPage + @props.rightsidePages, @props.totalPages]...
    smallestPage = Math.max [@props.currentPage - @props.leftsidePages, 1]...

    hideFinalNav = true unless @props.nextPage and @props.totalPages - @props.currentPage > @props.rightsidePages

    hideStartNav = true unless @props.previousPage and @props.currentPage > @props.leftsidePages + 1

    if @props.previousPage
      lefts = for x in [smallestPage ... @props.currentPage]
        <Page pagenum={x} key={x} onClick={@props.onClick} />

    if @props.nextPage
      rights = for x in [(@props.currentPage + 1) .. largestPage]
        <Page pagenum={x} key={x} onClick={@props.onClick} />


    <ul className="pagination text-center column" role="navigation" ariaLabel="Pagination">
      <li className="pagination-previous #{'disabled' unless @props.previousPage} ">
        {
         if @props.previousPage
           <a onClick={@clicked.bind(this, @props.previousPage)} ariaLabel="Previous page">Previous <span className="show-for-sr">page</span></a>
         else
           <span>Previous <span className="show-for-sr">page</span></span>
        }
      </li>

      <Page pagenum="1" onClick={@props.onClick} hide={hideStartNav} />

      <li className="ellipsis #{'hide' if hideStartNav }" ariaHidden="true"></li>

      { lefts }

      <li className="current"><span className="show-for-sr">Current page is</span> {@props.currentPage}</li>


      { rights }


      <li className="ellipsis #{'hide' if hideFinalNav }" ariaHidden="true"></li>

      <Page pagenum={lastPage} onClick={@props.onClick} hide={hideFinalNav} />

      <li className="pagination-next #{'disabled' unless @props.nextPage}">
        {
         if @props.nextPage
           <a onClick={@clicked.bind(this, @props.nextPage)} ariaLabel="Next page">Next <span className="show-for-sr">page</span></a>
         else
           <span>Next <span className="show-for-sr">page</span></span>
        }
      </li>
    </ul>
