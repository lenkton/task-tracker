class Task::CustomizedEvent < Task
  belongs_to :series_task, class_name: "Task", optional: false, inverse_of: :customized_occurrences

  validates :repetition_event_number,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :series_task_id }
  validate :repetition_data_must_be_empty
  validate :series_must_be_recurring

  scope :for_series, ->(series_id) { where(series_task_id: series_id) }

  def self.for_series_and_event(series_id, event_number)
    for_series(series_id).find_by(repetition_event_number: event_number)
  end

  def api_repetition_type
    series_task.api_repetition_type
  end

  def api_repetition_data
    series_task.api_repetition_data
  end

  private

  def repetition_data_must_be_empty
    return if repetition_data.blank?

    errors.add(:repetition_data, "must be empty")
  end

  def series_must_be_recurring
    series = series_task
    return if series && Task::RECURRING_STI_TYPES.include?(series.repetition_type)

    errors.add(:series_task_id, "must reference a recurring task")
  end
end
