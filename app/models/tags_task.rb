# just a class for the join table
class TagsTask < ApplicationRecord
  belongs_to :tag
  belongs_to :task

  # WARN: could throw an exception even on a Task#update without a !
  validates :tag_id, uniqueness: { scope: :task_id }
end
