class Task::OddEven < Task
  PARITIES = %w[even odd].freeze

  validate :repetition_data_must_include_parity

  private

  def repetition_data_must_include_parity
    parity = repetition_data["parity"]

    return if PARITIES.include?(parity)

    errors.add(:repetition_data, "parity must be even or odd")
  end
end
