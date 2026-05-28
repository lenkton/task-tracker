class Task::OneTime < Task
  validate :repetition_data_must_be_empty

  private

  def repetition_data_must_be_empty
    return if repetition_data.blank?

    errors.add(:repetition_data, "must be empty")
  end
end
