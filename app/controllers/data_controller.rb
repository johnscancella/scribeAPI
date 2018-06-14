class DataController < ApplicationController

  def download
    @subjects = Subject.columns
    respond_to do |format|
      format.json {render json: CompleteSubjectsSerializer.new(@subjects)}
    end
  end
end
