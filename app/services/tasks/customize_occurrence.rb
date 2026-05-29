module Tasks
  class CustomizeOccurrence
    def self.call(series:, attributes:)
      new(series:, attributes:).call
    end

    def initialize(series:, attributes:)
      @series = series
      @attributes = attributes.to_h.deep_symbolize_keys
      @event_number = @attributes[:repetition_event_number]&.to_i
    end

    def call
      return failure(series_error) unless recurring_series?
      return failure(event_number_error) unless valid_event_number?

      customized = find_or_build_customized
      return failure(customized.errors) if customized.errors.any?

      apply_attributes(customized)
      save(customized)
    end

    private

    def recurring_series?
      Task::RECURRING_STI_TYPES.include?(@series.repetition_type)
    end

    def valid_event_number?
      @event_number.to_i.positive?
    end

    def series_error
      { series: [ "must be a recurring task" ] }
    end

    def event_number_error
      { repetition_event_number: [ "must be a positive integer" ] }
    end

    def failure(errors)
      ServiceResult.failure(errors)
    end

    def find_or_build_customized
      existing = Task::CustomizedEvent.for_series_and_event(@series.id, @event_number)
      return existing if existing

      build_customized
    end

    def build_customized
      scheduled_at = @attributes[:scheduled_at] || default_scheduled_at
      return invalid_event_number_task if scheduled_at.nil?

      Task::CustomizedEvent.new(
        name: @series.name,
        description: @series.description,
        scheduled_at: scheduled_at,
        status: @series.status,
        series_task: @series,
        repetition_data: {},
        repetition_event_number: @event_number,
        tags: @series.tags
      )
    end

    def invalid_event_number_task
      Task::CustomizedEvent.new.tap do |task|
        task.errors.add(:repetition_event_number, "does not exist for this series")
      end
    end

    def default_scheduled_at
      from = @series.scheduled_at
      to = from + 20.years
      occurrence = @series.generate_occurrences(from, to).find { |item| item.event_number == @event_number }
      occurrence&.scheduled_at
    end

    def apply_attributes(task)
      task.assign_attributes(@attributes.slice(:name, :description, :scheduled_at))
      assign_status(task)
    end

    def assign_status(task)
      return unless @attributes.key?(:status)

      status = Status.find_by(name: @attributes[:status])
      if status
        task.status = status
      else
        task.errors.add(:status, "is invalid")
      end
    end

    def assign_tags(task)
      task.tags = resolve_tags(@attributes[:tags])
    end

    def resolve_tags(raw_tags)
      tag_names(raw_tags).map { |name| Tag.find_or_create_by!(name: name) }
    end

    def tag_names(raw_tags)
      Array(raw_tags).map(&:to_s).map(&:strip).reject(&:blank?).uniq
    end

    def save(task)
      saved = false

      task.transaction do
        saved = task.save
        assign_tags(task) if saved && @attributes.key?(:tags)
        raise ActiveRecord::Rollback if task.errors.any?
      end

      if saved && task.errors.empty?
        ServiceResult.success(task.reload)
      else
        ServiceResult.failure(task.errors)
      end
    end
  end
end
