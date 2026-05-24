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

      @task.save ? ServiceResult.success(@task) : ServiceResult.failure(@task.errors)
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
  end
end
