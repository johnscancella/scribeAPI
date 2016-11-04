React                   = require 'react'
{Navigation}            = require 'react-router'
SubjectSetViewer        = require '../subject-set-viewer'
coreTools               = require 'components/core-tools'
FetchSubjectSetsMixin   = require 'lib/fetch-subject-sets-mixin'
BaseWorkflowMethods     = require 'lib/workflow-methods-mixin'
JSONAPIClient           = require 'json-api-client' # use to manage data?
ForumSubjectWidget      = require '../forum-subject-widget'
API                     = require '../../lib/api'
HelpModal               = require 'components/help-modal'
Tutorial                = require 'components/tutorial'
HelpButton              = require 'components/buttons/help-button'
BadSubjectButton        = require 'components/buttons/bad-subject-button'
HideOtherMarksButton    = require 'components/buttons/hide-other-marks-button'
DraggableModal          = require 'components/draggable-modal'
GenericButton           = require 'components/buttons/generic-button'
Draggable               = require 'lib/draggable'
{Link}                  = require 'react-router'
SocialShare             = require 'components/social-share'

module.exports = React.createClass # rename to Classifier
  displayName: 'Mark'

  propTypes:
    onCloseTutorial: React.PropTypes.func.isRequired

  getDefaultProps: ->
    workflowName: 'mark'
    # hideOtherMarks: false

  mixins: [FetchSubjectSetsMixin, BaseWorkflowMethods, Navigation] # load subjects and set state variables: subjects, currentSubject, classification

  getInitialState: ->
    taskKey:             null
    classifications:     []
    classificationIndex: 0
    subject_set_index:   0
    subject_index:       0
    currentSubToolIndex: 0
    helping:             false
    hideOtherMarks:      false
    currentSubtool:      null
    showingTutorial:     @showTutorialBasedOnUser @props.user
    lightboxHelp:        false
    activeSubjectHelper: null
    subjectCurrentPage:  1

  componentWillReceiveProps: (new_props) ->
    @setState showingTutorial: @showTutorialBasedOnUser(new_props.user)

  showTutorialBasedOnUser: (user) ->
    # Show tutorial by default
    show = true
    if user?.tutorial_complete?
      # If we have a user, show tutorial if they haven't completed it:
      show = ! user.tutorial_complete
    show

  componentDidMount: ->
    @fetchSubjectSetsBasedOnProps()
    @fetchGroups()

  componentWillMount: ->
    @setState taskKey: @getActiveWorkflow().first_task
    @beginClassification()

  componentDidUpdate: (prev_props) ->
    # If visitor nav'd from, for example, /mark/[some id] to /mark, this component won't re-mount, so detect transition here:
    if prev_props.hash != @props.hash
      @fetchSubjectSetsBasedOnProps()

  toggleHelp: ->
    @setState helping: not @state.helping
    @hideSubjectHelp()

  toggleTutorial: ->
    @setState showingTutorial: not @state.showingTutorial
    @hideSubjectHelp()

  toggleLightboxHelp: ->
    @setState lightboxHelp: not @state.lightboxHelp
    @hideSubjectHelp()

  toggleHideOtherMarks: ->
    @setState hideOtherMarks: not @state.hideOtherMarks

  # User changed currently-viewed subject:
  handleViewSubject: (index) ->
    @setState subject_index: index, => @forceUpdate()
    @toggleBadSubject() if @state.badSubject

  # User somehow indicated current task is complete; commit current classification
  handleToolComplete: (annotation) ->
    @handleDataFromTool(annotation)
    @commitCurrentClassification()


  handleMarkDelete: (m) ->
    @flagSubjectAsUserDeleted m.subject_id

  destroyCurrentClassification: ->
    classifications = @state.classifications
    classifications.splice(@state.classificationIndex,1)
    @setState
      classifications: classifications
      classificationIndex: classifications.length-1

    # There should always be an empty classification ready to receive data:
    @beginClassification()

  completeSubjectSetWithMoreToMark: ->
    @setMoreSubject()
    @completeSubjectSet()
    @resetMoreSubject()

  completeSubjectSet: ->
    @commitCurrentClassification()
    @beginClassification()

    show_subject_assessment = @getActiveWorkflow()?.show_completion_assessment_task ? true
    if show_subject_assessment
      @setState
        taskKey: "completion_assessment_task"
    else
      @advanceToNextSubject()

  completeSubjectAssessment: ->
    @commitCurrentClassification()
    @beginClassification()
    @advanceToNextSubject()

  nextPage: (callback_fn)->
    new_page = @state.subjectCurrentPage + 1
    @setState subjectCurrentPage: new_page, => @fetchSubjectsForCurrentSubjectSet(new_page, null, callback_fn)

  prevPage: (callback_fn) ->
    new_page = @state.subjectCurrentPage - 1
    @setState subjectCurrentPage: new_page
    @fetchSubjectsForCurrentSubjectSet(new_page, null, callback_fn)

  showSubjectHelp: (subject_type) ->
    @setState
      activeSubjectHelper: subject_type
      helping: false
      showingTutorial: false
      lightboxHelp: false

  hideSubjectHelp: () ->
    @setState
      activeSubjectHelper: null

  render: ->
    if @getCurrentSubjectSet()? && @getActiveWorkflow()?
      currentTask = @getCurrentTask()
      TaskComponent = @getCurrentTool()
      activeWorkflow = @getActiveWorkflow()
      firstTask = activeWorkflow.first_task
      onFirstAnnotation = @state.taskKey == firstTask
      currentSubtool = if @state.currentSubtool then @state.currentSubtool else @getTasks()[firstTask]?.tool_config.tools?[0]

      # direct link to this page
      pageURL = "#{location.origin}/#/mark?subject_set_id=#{@getCurrentSubjectSet().id}&selected_subject_id=#{@getCurrentSubject()?.id}"

      if currentTask?.tool is 'pick_one'
        currentAnswer = (a for a in currentTask.tool_config.options when a.value == currentAnnotation.value)[0]
        waitingForAnswer = not currentAnswer

    <div className="classifier">

      <div className="subject-area">
        { if @state.noMoreSubjectSets
            <DraggableModal
              header          = { "Nothing to mark" }
              buttons         = {<GenericButton label='Continue' href='/#' />}
            >
              Currently, there are no {@props.project.term('subject')}s for you to {@props.workflowName}. Try <a href="/#/transcribe">transcribing</a> or <a href="/#/verify">verifying</a> instead!
            </DraggableModal>

          else if @state.notice
            <DraggableModal header={@state.notice.header} onDone={@state.notice.onClick}>{@state.notice.message}</DraggableModal>

          else if @getCurrentSubjectSet()?
            <SubjectSetViewer
              subject_set={@getCurrentSubjectSet()}
              subject_index={@state.subject_index}
              workflow={@getActiveWorkflow()}
              task={currentTask}
              annotation={@getCurrentClassification()?.annotation ? {}}
              onComplete={@handleToolComplete}
              onChange={@handleDataFromTool}
              onDestroy={@handleMarkDelete}
              onViewSubject={@handleViewSubject}
              subToolIndex={@state.currentSubToolIndex}
              nextPage={@nextPage}
              prevPage={@prevPage}
              subjectCurrentPage={@state.subjectCurrentPage}
              totalSubjectPages={@state.subjects_total_pages}
              destroyCurrentClassification={@destroyCurrentClassification}
              hideOtherMarks={@state.hideOtherMarks}
              toggleHideOtherMarks={@toggleHideOtherMarks}
              currentSubtool={currentSubtool}
              lightboxHelp={@toggleLightboxHelp}
              interimMarks={@state.interimMarks}
            />
        }
      </div>
      <div className="right-column">
        <div className={"task-area " + @getActiveWorkflow().name}>
          { if @getCurrentTask()? && @getCurrentSubject()?
              <div className="task-container">
                <TaskComponent
                  key={@getCurrentTask().key}
                  task={currentTask}
                  annotation={@getCurrentClassification()?.annotation ? {}}
                  onChange={@handleDataFromTool}
                  onSubjectHelp={@showSubjectHelp}
                  subject={@getCurrentSubject()}
                />

                <nav className="task-nav">
                  { if @getNextTask() and not @state.badSubject?
                      <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@advanceToNextTask}>Next</button>
                    else
                      if @state.taskKey == "completion_assessment_task"
                        if @getCurrentSubject() == @getCurrentSubjectSet().subjects[@getCurrentSubjectSet().subjects.length-1]
                          <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@completeSubjectAssessment}>Next</button>
                        else
                          <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@completeSubjectAssessment}>Next Page</button>
                      else
                        <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@completeSubjectSet}>Done</button>
                  }
                </nav>

                <nav className="task-nav">
                  { if not @getActiveWorkflow()?.show_completion_assessment_task
                      <GenericButton className="secondary continue small-button" label={"Done for now, more left to mark"} onClick={@completeSubjectSetWithMoreToMark} />
                  }
                </nav>
                <nav className="task-nav">
                  <GenericButton className="secondary continue small-button" label={"Skip this " + @props.project.term('subject')} onClick={@advanceToNextSubject} />
                </nav>

                <div className="help-bad-subject-holder">
                  { if @getCurrentTask().help?
                    <HelpButton onClick={@toggleHelp} label="" className="task-help-button" />
                  }
                  { if onFirstAnnotation and @getActiveWorkflow()?.show_bad_subject_button
                    <BadSubjectButton className="bad-subject-button" label={"Bad " + @props.project.term('subject')} active={@state.badSubject} onClick={@toggleBadSubject} />
                  }
                  { if @state.badSubject
                    <p>You&#39;ve marked this {@props.project.term('subject')} as BAD. Thanks for flagging the issue! <strong>Press DONE to continue.</strong></p>
                  }
                </div>
              </div>
          }

          <div className="task-secondary-area">

            {
              if @getCurrentTask()?
                <p>
                  <a className="tutorial-link" onClick={@toggleTutorial}>View A Tutorial</a>
                </p>
            }

            {
              if @getCurrentTask()? && @getActiveWorkflow()? && @getWorkflowByName('transcribe')?
                <p>
                  <Link to="/transcribe/#{@getWorkflowByName('transcribe').id}/#{@getCurrentSubject()?.id}" className="transcribe-link">Transcribe this {@props.project.term('subject')} now!</Link>
                </p>
            }

            {
              if @getCurrentSubject()?.meta_data?.subject_url?
                <p>
                  <a className="view-original-link" href="#{@getCurrentSubject().meta_data.subject_url}" target="_blank">
                    View the original {@props.project.term('subject')}
                  </a>
                </p>
            }

            {
              if @getActiveWorkflow()? and @state.groups?.length > 1 and @getCurrentSubjectSet()?
                <p>
                  <Link to="/groups/#{@getCurrentSubjectSet().group_id}" className="about-link">About this {@props.project.term('group')}</Link>
                </p>
            }

            <div className="forum-holder">
              <ForumSubjectWidget subject={@getCurrentSubject()} subject_set={@getCurrentSubjectSet()} project={@props.project} />
            </div>

            <SocialShare url="#{pageURL}"/>
          </div>

        </div>
      </div>
      { if @props.project.tutorial? && @state.showingTutorial
          # Check for workflow-specific tutorial
          if @props.project.tutorial.workflows? && @props.project.tutorial.workflows[@getActiveWorkflow()?.name]
            <Tutorial tutorial={@props.project.tutorial.workflows[@getActiveWorkflow().name]} onCloseTutorial={@props.onCloseTutorial} />
          # Otherwise just show general tutorial
          else
            <Tutorial tutorial={@props.project.tutorial} onCloseTutorial={@props.onCloseTutorial} />
      }
      { if @state.helping
        <HelpModal help={@getCurrentTask().help} onDone={=> @setState helping: false } />
      }
      {
        if @state.lightboxHelp
          <HelpModal help={{title: "The Lightbox", body: "<p>This Lightbox displays a complete set of documents in order. You can use it to go through the documents sequentially—but feel free to do them in any order that you like! Just click any thumbnail to open that document and begin marking it.</p><p>However, please note that **once you start marking a page, the Lightbox becomes locked ** until you finish marking that page! You can select a new page once you have finished.</p>"}} onDone={=> @setState lightboxHelp: false } />
      }
      {
        if @getCurrentTask()?
          for tool, i in @getCurrentTask().tool_config.options
            if tool.help && tool.generates_subject_type && @state.activeSubjectHelper == tool.generates_subject_type
              <HelpModal key={i} help={tool.help} onDone={@hideSubjectHelp} />
      }

    </div>


window.React = React
