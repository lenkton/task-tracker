class TasksController < ApplicationController
  before_action :set_task, only: %i[ show update destroy ]

  def index
    result = Tasks::Filter.call(scope: current_user.tasks, filters: filter_params)

    if result.success?
      render json: TaskSerializer.collection(result.value)
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def show
    render json: TaskSerializer.call(@task)
  end

  def create
    result = Tasks::Write.call(task: Task.new(user: current_user), attributes: task_params)

    if result.success?
      render json: TaskSerializer.call(result.value), status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def update
    result = if customize_occurrence?
               Tasks::CustomizeOccurrence.call(series: @task, attributes: task_params)
             else
               Tasks::Write.call(task: @task, attributes: task_params)
             end

    if result.success?
      render json: TaskSerializer.call(result.value)
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    head :no_content
  end

  private

  def set_task
    @task = current_user.tasks.includes(:status, :tags, :series_task).find(params[:id])
  end

  def task_params
    params.permit(
      :name, :description, :scheduled_at, :status,
      :repetition_type, :repetition_event_number,
      tags: [],
      repetition_data: {}
    )
  end

  def customize_occurrence?
    repetition_event_number = params[:repetition_event_number]
    repetition_event_number.present? && repetition_event_number.to_i.positive?
  end

  def filter_params
    params.permit(:scheduled_from, :scheduled_to, :statuses)
  end
end
