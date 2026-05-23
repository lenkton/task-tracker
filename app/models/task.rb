class Task < ApplicationRecord
  belongs_to :status

  validates :name, presence: true
  validates :scheduled_at, presence: true
end
