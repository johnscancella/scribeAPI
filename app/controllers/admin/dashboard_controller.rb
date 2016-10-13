class Admin::DashboardController < Admin::AdminBaseController
  
  def index
  end

  def recalculate_stats
    # calculate project's stats
    project = Project.current
    project.check_and_update_stats

    # calculate group's stats
    Group.all.each do |group|
      group.check_and_update_stats
    end

    render :json => {:project => project, :stats => project.stats}
  end
end
