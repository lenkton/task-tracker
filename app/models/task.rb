class Task < ApplicationRecord
  belongs_to :status
  has_many :tags_tasks, dependent: :destroy
  has_many :tags, through: :tags_tasks

  validates :name, presence: true
  validates :scheduled_at, presence: true
end
