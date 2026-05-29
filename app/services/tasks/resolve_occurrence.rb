module Tasks
  class ResolveOccurrence
    def self.call(series:, event_number:)
      new(series:, event_number:).call
    end

    def initialize(series:, event_number:)
      @series = series
      @event_number = event_number
    end

    def call
      customized = find_customized
      return ServiceResult.success(customized) if customized

      return failure(not_found_error) unless recurring?

      occurrence = @series.find_occurrence_by_event_number(@event_number)
      return ServiceResult.success(occurrence) if occurrence

      failure(not_found_error)
    end

    private

    def find_customized
      Task::CustomizedEvent
        .includes(:status, :tags, :series_task)
        .for_series_and_event(@series.id, @event_number)
    end

    def recurring?
      Task::RECURRING_STI_TYPES.include?(@series.repetition_type)
    end

    def not_found_error
      { repetition_event_number: [ "does not exist for this series" ] }
    end

    def failure(errors)
      ServiceResult.failure(errors)
    end
  end
end
