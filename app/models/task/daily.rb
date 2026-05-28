class Task::Daily < Task
  validate :repetition_data_must_include_period

  private

  def repetition_data_must_include_period
    period = repetition_data["period"]

    return if period.is_a?(Integer) && period.positive?

    errors.add(:repetition_data, "period must be a positive integer")
  end
end
