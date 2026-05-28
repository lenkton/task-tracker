class Task::Monthly < Task
  validate :repetition_data_must_include_day_of_month

  private

  def repetition_data_must_include_day_of_month
    day_of_month = repetition_data["day_of_month"]

    return if day_of_month.is_a?(Integer) && day_of_month.between?(1, 31)

    errors.add(:repetition_data, "day_of_month must be between 1 and 31")
  end
end
