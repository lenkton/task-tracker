class Task::Monthly < Task
  validate :repetition_data_must_include_day_of_month

  def generate_occurrences(from, to)
    return [] if scheduled_at > to

    day = repetition_data["day_of_month"]
    occurrences = []
    month = from.beginning_of_month

    while month <= to.beginning_of_month
      time = occurrence_time_in_month(month, day)
      if time && time.between?(from, to) && time >= scheduled_at
        occurrences << build_recurring_occurrence(event_number_for(time), time)
      end

      month = month.next_month
    end

    occurrences
  end

  private

  def occurrence_time_in_month(month, day)
    year = month.year
    month_number = month.month
    return nil unless Date.valid_date?(year, month_number, day)

    Time.zone.local(
      year, month_number, day,
      scheduled_at.hour, scheduled_at.min, scheduled_at.sec
    )
  end

  def event_number_for(time)
    (time.year * 12 + time.month) - (scheduled_at.year * 12 + scheduled_at.month)
  end

  def repetition_data_must_include_day_of_month
    day_of_month = repetition_data["day_of_month"]

    return if day_of_month.is_a?(Integer) && day_of_month.between?(1, 31)

    errors.add(:repetition_data, "day_of_month must be between 1 and 31")
  end
end
