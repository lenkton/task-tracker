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

      scope = @scope.includes(:status, :tags).order(:id)
      scope = filter_by_statuses(scope)
      ServiceResult.success(filter_by_scheduled_at(scope))
    end

    private

    def validate_filters
      @errors = {}
      @scheduled_from = parse_time(:scheduled_from, @filters[:scheduled_from], boundary: :beginning)
      @scheduled_to = parse_time(:scheduled_to, @filters[:scheduled_to], boundary: :end)
    end

    def filter_by_statuses(scope)
      names = status_names
      return scope if names.empty?

      scope.joins(:status).where(statuses: { name: names })
    end

    def filter_by_scheduled_at(scope)
      scope = scope.where(scheduled_at: @scheduled_from..) if @scheduled_from
      scope = scope.where(scheduled_at: ..@scheduled_to) if @scheduled_to
      scope
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
