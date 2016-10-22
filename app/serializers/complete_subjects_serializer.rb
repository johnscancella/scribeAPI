class CompleteSubjectsSerializer < ActiveModel::MongoidSerializer
  attributes :data

  root false

  def data
    options = serialization_options.merge({root: false})
    object.map { |s| CompleteSubjectSerializer.new(s, root: false) }
  end

end
