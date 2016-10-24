React = require 'react'

SocialShare = React.createClass
  displayName: 'SocialShare'

  render: ->
    <div className="social-media-container">
      <a href="https://www.facebook.com/sharer.php?u=#{encodeURIComponent @props.url}" target="_blank">
        <i className="fa fa-facebook-square"/>
      </a>
      <a href="https://twitter.com/home?status=#{encodeURIComponent @props.url}%0A" target="_blank">
        <i className="fa fa-twitter-square"/>
      </a>
      <a href="https://plus.google.com/share?url=#{encodeURIComponent @props.url}" target="_blank">
        <i className="fa fa-google-plus-square"/>
      </a>
    </div>

module.exports = SocialShare