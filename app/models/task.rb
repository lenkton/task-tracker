class Task < ApplicationRecord
  REPETITION_TYPE_CLASS_NAMES = {
    "one_time" => "Task::OneTime",
    "daily" => "Task::Daily",
    "monthly" => "Task::Monthly",
    "odd_even" => "Task::OddEven",
    "customized_event" => "Task::CustomizedEvent"
  }.freeze

  class UnknownRepetitionType < StandardError; end

  belongs_to :status
  # Join-таблица tags_tasks без первичного ключа (create_join_table).
  # dependent: :destroy пытается удалять по id и падает в PostgreSQL.
  has_many :tags_tasks, dependent: :delete_all
  has_many :tags, through: :tags_tasks

  validates :name, presence: true
  validates :scheduled_at, presence: true
  validates :repetition_event_number,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  self.inheritance_column = "repetition_type"

  def self.class_for_api_type(api_type)
    class_name = REPETITION_TYPE_CLASS_NAMES.fetch(api_type) { raise UnknownRepetitionType }
    class_name.constantize
  end

  def api_repetition_type
    REPETITION_TYPE_CLASS_NAMES.key(self.class.name)
  end
end
