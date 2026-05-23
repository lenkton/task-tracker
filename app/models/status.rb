class Status < ApplicationRecord
  has_many :tasks, dependent: :restrict_with_error

  validates :name, uniqueness: true, presence: true
end
