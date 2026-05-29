class Task::Daily < Task
  validate :repetition_data_must_include_period

  def generate_occurrences(from, to)
    period = repetition_data["period"].days
    start = scheduled_at
    return [] if start > to

    k_min = start >= from ? 0 : ((from - start) / period).ceil
    k_max = ((to - start) / period).floor
    return [] if k_min > k_max

    (k_min..k_max).map { |k| build_recurring_occurrence(k, start + k * period) }
  end

  private

  def repetition_data_must_include_period
    period = repetition_data["period"]

    return if period.is_a?(Integer) && period.positive?

    errors.add(:repetition_data, "period must be a positive integer")
  end
end
