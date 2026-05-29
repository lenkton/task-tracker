class Task < ApplicationRecord
  REPETITION_TYPE_CLASS_NAMES = {
    "one_time" => "Task::OneTime",
    "daily" => "Task::Daily",
    "monthly" => "Task::Monthly",
    "odd_even" => "Task::OddEven",
    "customized_event" => "Task::CustomizedEvent"
  }.freeze

  RECURRING_STI_TYPES = %w[Task::Daily Task::Monthly Task::OddEven].freeze

  class UnknownRepetitionType < StandardError; end

  belongs_to :status
  belongs_to :user
  belongs_to :series_task, class_name: "Task", optional: true, inverse_of: :customized_occurrences
  has_many :customized_occurrences,
           -> { where(repetition_type: "Task::CustomizedEvent") },
           class_name: "Task",
           foreign_key: :series_task_id,
           dependent: :delete_all,
           inverse_of: :series_task
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

  scope :one_time, -> { where(repetition_type: "Task::OneTime") }
  scope :recurring, -> { where(repetition_type: RECURRING_STI_TYPES) }
  scope :customized_events, -> { where(repetition_type: "Task::CustomizedEvent") }

  def self.class_for_api_type(api_type)
    class_name = REPETITION_TYPE_CLASS_NAMES.fetch(api_type) { raise UnknownRepetitionType }
    class_name.constantize
  end

  def api_repetition_type
    REPETITION_TYPE_CLASS_NAMES.key(self.class.name)
  end

  def api_repetition_data
    repetition_data
  end

  def build_occurrence(event_number, scheduled_at)
    Tasks::Occurrence.new(task: self, event_number:, scheduled_at:)
  end

  # series_index 0 — якорь в БД; в API отдаём как repetition_event_number 1.
  def build_recurring_occurrence(series_index, scheduled_at)
    build_occurrence(series_index + 1, scheduled_at)
  end

  def generate_occurrences(from, to)
    raise NotImplementedError
  end
end
