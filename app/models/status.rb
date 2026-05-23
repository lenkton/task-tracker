class Status < ApplicationRecord
  validates :name, uniqueness: true, presence: true
end
