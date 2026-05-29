class Task::OddEven < Task
  PARITIES = %w[even odd].freeze

  validate :repetition_data_must_include_parity

  def generate_occurrences(from, to)
    time = scheduled_at
    return [] if time > to

    event_number, time = fast_forward_to(from)

    occurrences = []

    while time <= to
      occurrences << build_occurrence(event_number, time)
      event_number += 1
      time = next_parity_occurrence_after(time)
    end

    occurrences
  end

  private

  def fast_forward_to(from)
    start = scheduled_at
    return [ 0, start ] if start >= from

    event_number = 0
    time = start
    from_month = from.to_date.beginning_of_month
    month_cursor = time.to_date.beginning_of_month

    if month_cursor == from_month
      while time < from
        event_number += 1
        time = next_parity_occurrence_after(time)
      end

      return [ event_number, time ]
    end

    event_number, time = advance_partial_month(
      month_cursor.end_of_month,
      event_number:,
      time:
    )
    month_cursor = month_cursor.next_month

    while month_cursor < from_month
      month_end = month_cursor.end_of_month
      event_number += full_month_occurrence_count(month_end.day)
      time = occurrence_time_on(
        Date.new(month_end.year, month_end.month, last_parity_day_in_month(month_end))
      )
      month_cursor = month_cursor.next_month
    end

    while time < from
      event_number += 1
      time = next_parity_occurrence_after(time)
    end

    [ event_number, time ]
  end

  def advance_partial_month(month_end, event_number:, time:)
    entry_day = time.to_date.day
    last_parity_day = last_parity_day_in_month(month_end)
    return [ event_number, time ] if entry_day > last_parity_day

    count = ((last_parity_day - entry_day) / 2) + 1

    [
      event_number + count,
      occurrence_time_on(Date.new(month_end.year, month_end.month, entry_day + ((count - 1) * 2)))
    ]
  end

  def full_month_occurrence_count(days_in_month)
    parity_odd? ? (days_in_month + 1) / 2 : days_in_month / 2
  end

  def last_parity_day_in_month(date)
    last_day = date.end_of_month.day

    parity_odd? ? (last_day.odd? ? last_day : last_day - 1) : (last_day.even? ? last_day : last_day - 1)
  end

  def occurrence_time_on(date)
    Time.zone.local(
      date.year, date.month, date.day,
      scheduled_at.hour, scheduled_at.min, scheduled_at.sec
    )
  end

  def parity_odd?
    repetition_data["parity"] == "odd"
  end

  def repetition_data_must_include_parity
    parity = repetition_data["parity"]

    return if PARITIES.include?(parity)

    errors.add(:repetition_data, "parity must be even or odd")
  end

  def next_parity_occurrence_after(time)
    candidate = (time.to_date + 1.day).in_time_zone + time.seconds_since_midnight.seconds

    candidate += 1.day until parity_day?(candidate)

    candidate
  end

  def parity_day?(time)
    day = time.day

    parity_odd? ? day.odd? : day.even?
  end
end
