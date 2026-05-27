module Tasks
  class Write
    def self.call(task:, attributes:)
      new(task:, attributes:).call
    end

    def initialize(task:, attributes:)
      @task = task
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      @task.assign_attributes(@attributes.slice(:name, :description, :scheduled_at))
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
