React = require 'react'
{Link} = require 'react-router'

Page = React.createClass
  displayName: 'Page'

  getDefaultProps: ->
    href: null
    pagenum: null
    hide: false

  render: ->
    <li key={@props.pagenum} className="#{'hide' if @props.hide}">
      <Link to="#{@props.href}" ariaLabel="Page #{@props.pagenum}">{@props.pagenum}</Link>
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
    urlBase: null

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
        <Page pagenum={x} key={x} href="#{@props.urlBase}/#{x}" />

    if @props.nextPage
      rights = for x in [(@props.currentPage + 1) .. largestPage]
        <Page pagenum={x} key={x} href="#{@props.urlBase}/#{x}" />


    <ul className="pagination text-center column" role="navigation" ariaLabel="Pagination">
      <li className="pagination-previous #{'disabled' unless @props.previousPage} ">
        {
         if @props.previousPage
           <Link to="#{@props.urlBase}/#{@props.previousPage}" ariaLabel="Previous page">Previous <span className="show-for-sr">page</span></Link>
         else
           <span>Previous <span className="show-for-sr">page</span></span>
        }
      </li>

      <Page pagenum="1" href="#{@props.urlBase}/1" hide={hideStartNav} />

      <li className="ellipsis #{'hide' if hideStartNav }" ariaHidden="true"></li>

      { lefts }

      <li className="current"><span className="show-for-sr">Current page is</span> {@props.currentPage}</li>


      { rights }


      <li className="ellipsis #{'hide' if hideFinalNav }" ariaHidden="true"></li>

      <Page pagenum={lastPage} href="#{@props.urlBase}/#{lastPage}" hide={hideFinalNav} />

      <li className="pagination-next #{'disabled' unless @props.nextPage}">
        {
         if @props.nextPage
           <Link to="#{@props.urlBase}/#{@props.nextPage}" ariaLabel="Next page">Next<span className="show-for-sr">page</span></Link>
         else
           <span>Next <span className="show-for-sr">page</span></span>
        }
      </li>
    </ul>
