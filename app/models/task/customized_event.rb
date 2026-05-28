class Task::CustomizedEvent < Task
  validate :repetition_event_number_must_be_positive

  private

  def repetition_event_number_must_be_positive
    return if repetition_event_number.to_i.positive?

    errors.add(:repetition_event_number, "must be greater than 0")
  end
end
