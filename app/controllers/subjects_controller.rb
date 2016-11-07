# a monkey patch solution for sorting on text search scores
# https://github.com/mongoid/moped/issues/358#issuecomment-81156032
module Origin
  module Optional
    def with_fields(fields_def = {})
      fields_def ||= {}
      fields_def.merge!({_id: 1})
      option(fields_def) do |options|
        options.store(:fields,
          fields_def.inject(options[:fields] || {}) do |sub, field_def|
            key, val = field_def
            sub.tap { sub[key] = val }
          end
        )
      end
    end

    def include_text_search_score
      with_fields({score: {"$meta" => "textScore"}})
    end

    def sort_by_text_search_score
      option({}) do |options, query|
        add_sort_option(options, :score, {"$meta" => "textScore"})
      end
    end
  end
end

class SubjectsController < ApplicationController
  respond_to :json

  def index
    user = current_or_guest_user

    workflow_id           = get_objectid :workflow_id
    group_id              = get_objectid :group_id
    subject_set_id        = get_objectid :subject_set_id
    parent_subject_id     = get_objectid :parent_subject_id
    # Note that pagination is kind of useless when randomizing
    random                = get_bool :random, false
    limit                 = get_int :limit, 10
    page                  = get_int :page, 1
    type                  = params[:type]
    # `status` filter must be one of: 'active', 'complete', any'
    status                = ['active','complete','any'].include?(params[:status]) ? params[:status] : 'active'

    @subjects = Subject.page(page).per(limit)

    # Only active subjects?
    @subjects = @subjects.active if status == 'active'

    # Filter by subject type (e.g. 'root')
    @subjects = @subjects.by_type(type) if type

    # Filter by workflow (There should almost always be a workflow_id filter)
    @subjects = @subjects.by_workflow(workflow_id) if workflow_id

    # Filter by subject?
    @subjects = @subjects.by_parent_subject(parent_subject_id) if parent_subject_id

    # Filter by group?
    @subjects = @subjects.by_group(group_id) if group_id

    # Filter by subject set?
    @subjects = @subjects.by_subject_set(subject_set_id) if subject_set_id

    # gallery specific logic
    # Filter by data
    params.each do |key, value|
      if key.start_with?("data.")
        @subjects = @subjects.by_data(key, value, true)
      end
    end

    # gallery specific logic
    # text search
    keyword = params[:text]
    @subjects = @subjects.where({"$text" => {"$search" => keyword} } ).include_text_search_score.
          sort_by_text_search_score.only(:region, :meta_data, :data) if keyword

    # gallery specific logic
    @subjects = @subjects.complete if status == 'complete'

    if ! subject_set_id
      # Randomize?
      # @subjects = @subjects.random(limit: limit) if random
      # PB: Above randomization method produces better randomness, but inconsistent totals
      @subjects = @subjects.random_order if random

      # If user/guest active, filter out anything already classified:
      @subjects = @subjects.user_has_not_classified user.id.to_s if ! user.nil?

      # Should we filter out subjects that the user herself created?
      if ! user.nil? && workflow_id && ! (workflow = Workflow.find(workflow_id)).nil? && ! workflow.subjects_classifiable_by_creator
        # Note: creating_user_ids are stored as ObjectIds, so no need to filter on user.id.to_s:
        @subjects = @subjects.user_did_not_create user.id if ! user.nil?
      end
    end

    links = {
      "next" => {
        href: @subjects.next_page.nil? ? nil : url_for(controller: 'subjects', page: @subjects.next_page),
      },
      "prev" => {
        href: @subjects.prev_page.nil? ? nil : url_for(controller: 'subjects', page: @subjects.prev_page)
      }
    }
    respond_with SubjectResultSerializer.new(@subjects, scope: self.view_context), workflow_id: workflow_id, links: links
  end

  def show
    subject_id = get_objectid :subject_id

    links = {
      self: url_for(@subject)
    }
    @subject = Subject.find subject_id
    respond_with SubjectResultSerializer.new(@subject, scope: self.view_context), links: links
  end


end
