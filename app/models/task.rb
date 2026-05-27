class Task < ApplicationRecord
  belongs_to :status
  # Join-таблица tags_tasks без первичного ключа (create_join_table).
  # dependent: :destroy пытается удалять по id и падает в PostgreSQL.
  has_many :tags_tasks, dependent: :delete_all
  has_many :tags, through: :tags_tasks

  validates :name, presence: true
  validates :scheduled_at, presence: true
end
