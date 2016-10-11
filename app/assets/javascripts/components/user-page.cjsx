React              = require("react")
LoadingIndicator   = require './loading-indicator'

UserPage = React.createClass
  displayName: "UserPage"

  getInitialState: ->
    user: null

  componentDidMount: ->
    @fetchUser()

  fetchUser:->
    @setState
      error: null
    request = $.getJSON "/current_user"

    request.done (result)=>
      if result?.data
        @setState
          user: result.data
      else

    request.fail (error)=>
      @setState
        loading:false
        error: "Having trouble getting user data"

  render: ->
    if ! @state.user?
      <div className='page-content custom-page'>
        <p><LoadingIndicator /></p>
      </div>
    else
      <div className='page-content custom-page'>
        <h1></h1>
        <div>
        <h2>Congratulations, {@state.user.name}!</h2>
        <p>You have made <span className='classification-count'>{@state.user.classification_count}</span> contributions to this project. Thank you!</p>
        </div>
      </div>


module.exports = UserPage
