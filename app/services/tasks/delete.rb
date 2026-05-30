module Tasks
  class Delete
    def self.call(task:, event_number: nil)
      new(task:, event_number:).call
    end

    def initialize(task:, event_number: nil)
      @task = task
      @event_number = event_number.to_i
    end

    def call
      if delete_occurrence?
        delete_series_occurrence
      else
        delete_task
      end
    end

    private

    def delete_occurrence?
      @event_number.positive?
    end

    def delete_series_occurrence
      return not_found if deleted_occurrence_slot?

      result = CustomizeOccurrence.call(
        series: @task,
        attributes: { repetition_event_number: @event_number, status: Status::DELETED_NAME },
        delete: true
      )
      return result if result.failure?

      ServiceResult.success(nil)
    end

    def delete_task
      @task.status = deleted_status
      return ServiceResult.failure(@task.errors) unless @task.save

      ServiceResult.success(nil)
    end

    def deleted_occurrence_slot?
      Task::CustomizedEvent.occurrence_slot(@task.id, @event_number)&.deleted?
    end

    def deleted_status
      Status.find_by!(name: Status::DELETED_NAME)
    end

    def not_found
      ServiceResult.failure(
        repetition_event_number: [ "does not exist for this series" ]
      )
    end
  end
end
