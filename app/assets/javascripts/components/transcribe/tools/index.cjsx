module.exports =
  # transcribeTool:   require './transcribe-row-tool'
  compositeTool: require './composite-tool'

  textTool:      require './text-tool' # this will soon be subsumed by single-tool
  dateTool:      require './date-tool'
  numberTool:    require './number-tool'
  textAreaTool:  require './text-area-tool'
  selectOneTool: require './select-one-tool'
  
