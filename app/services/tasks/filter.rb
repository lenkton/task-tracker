module Tasks
  class Filter
    def self.call(scope: Task.all, filters:)
      new(scope:, filters:).call
    end

    def initialize(scope:, filters:)
      @scope = scope
      @filters = filters.to_h.symbolize_keys
    end

    def call
      validate_filters
      return ServiceResult.failure(@errors) if @errors.any?

      scope = @scope.includes(:status, :tags)
      scope = filter_by_statuses(scope)
      occurrences = one_time_occurrences(scope) +
                    customized_occurrences(scope) +
                    recurring_occurrences(scope)
      ServiceResult.success(sort_occurrences(occurrences))
    end

    private

    def validate_filters
      @errors = {}
      @scheduled_from = parse_time(:scheduled_from, @filters[:scheduled_from], boundary: :beginning)
      @scheduled_to = parse_time(:scheduled_to, @filters[:scheduled_to], boundary: :end)

      @errors[:scheduled_from] = [ "can't be blank" ] if @filters[:scheduled_from].blank?
      @errors[:scheduled_to] = [ "can't be blank" ] if @filters[:scheduled_to].blank?
      return if @errors.any?

      if @scheduled_from > @scheduled_to
        @errors[:scheduled_to] = [ "must be on or after scheduled_from" ]
      end
    end

    def one_time_occurrences(scope)
      scope.one_time
           .where(scheduled_at: @scheduled_from..@scheduled_to)
           .map { |task| task.build_occurrence(0, task.scheduled_at) }
    end

    def customized_occurrences(scope)
      scope.customized_events
           .where(scheduled_at: @scheduled_from..@scheduled_to)
           .map { |task| task.build_occurrence(0, task.scheduled_at) }
    end

    def recurring_occurrences(scope)
      recurring_scope = scope.recurring.where(scheduled_at: ..@scheduled_to)
      skipped_by_series = customized_event_numbers_by_series(recurring_scope)

      recurring_scope.flat_map do |task|
        skipped = skipped_by_series[task.id] || []
        task.generate_occurrences(@scheduled_from, @scheduled_to)
            .reject { |occurrence| skipped.include?(occurrence.event_number) }
      end
    end

    def customized_event_numbers_by_series(recurring_scope)
      series_ids = recurring_scope.pluck(:id)
      return {} if series_ids.empty?

      Task::CustomizedEvent
        .where(series_task_id: series_ids)
        .pluck(:series_task_id, :repetition_event_number)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }
    end

    def sort_occurrences(occurrences)
      occurrences.sort_by { |occurrence| [ occurrence.scheduled_at, occurrence.task.id, occurrence.event_number ] }
    end

    def filter_by_statuses(scope)
      names = status_names
      return scope if names.empty?

      scope.joins(:status).where(statuses: { name: names })
    end

    def status_names
      raw = @filters[:statuses]
      return [] if raw.blank?

      names = case raw
      when String then raw.split(",")
      when Array then raw.flat_map { |value| value.to_s.split(",") }
      else []
      end

      names.map(&:strip).reject(&:blank?)
    end

    def parse_time(key, value, boundary:)
      return nil if value.blank?

      time = Time.zone.parse(value.to_s)
      if time.nil?
        @errors[key] = [ "is invalid" ]
        return nil
      end

      date_only?(value) ? time.public_send(boundary == :beginning ? :beginning_of_day : :end_of_day) : time
    end

    def date_only?(value)
      value.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    end
  end
end
