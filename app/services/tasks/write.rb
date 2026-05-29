module Tasks
  class Write
    def self.call(task:, attributes:)
      new(task:, attributes:).call
    end

    def initialize(task:, attributes:)
      @attributes = attributes.to_h.deep_symbolize_keys
      @task = resolve_task(task)
    end

    def call
      @task.assign_attributes(@attributes.slice(:name, :description, :scheduled_at))
      assign_repetition_attributes if @task.new_record?
      assign_status
      return ServiceResult.failure(@task.errors) if @task.errors.any?

      saved = false
      @task.transaction do
        saved = @task.save
        assign_tags if saved && @attributes.key?(:tags)
        raise ActiveRecord::Rollback if @task.errors.any?
      end

      if saved && @task.errors.empty?
        ServiceResult.success(@task.reload)
      else
        ServiceResult.failure(@task.errors)
      end
    end

    private

    def resolve_task(task)
      return build_task(nil) if task.blank?
      return task if task.new_record? && repetition_type_matches?(task)
      return build_task(task) if task.new_record?

      task
    end

    def repetition_type_matches?(task)
      expected_api_type = @attributes[:repetition_type].presence || "one_time"
      task.class == Task.class_for_api_type(expected_api_type)
    rescue Task::UnknownRepetitionType
      false
    end

    def build_task(fallback_task)
      api_type = @attributes[:repetition_type].presence || "one_time"
      task = Task.class_for_api_type(api_type).new
      task.user = fallback_task.user if fallback_task&.user
      task
    rescue Task::UnknownRepetitionType
      task = fallback_task || Task.new
      task.errors.add(:repetition_type, "is invalid")
      task
    end

    def assign_repetition_attributes
      @task.repetition_data = normalize_repetition_data(@attributes[:repetition_data])
      @task.repetition_event_number = 0
    end

    def normalize_repetition_data(raw_data)
      return {} if raw_data.nil?

      raw_data.to_h.transform_keys(&:to_s)
    end

    def assign_status
      return unless @attributes.key?(:status)

      status_name = @attributes[:status]
      status = Status.find_by(name: status_name)

      if status
        @task.status = status
      else
        @task.errors.add(:status, "is invalid")
      end
    end

    def assign_tags
      @task.tags = resolve_tags(@attributes[:tags])
    end

    def resolve_tags(raw_tags)
      tag_names(raw_tags).map do |name|
        Tag.find_or_create_by!(name: name)
      end
    end

    def tag_names(raw_tags)
      Array(raw_tags).map(&:to_s).map(&:strip).reject(&:blank?).uniq
    end
  end
end
