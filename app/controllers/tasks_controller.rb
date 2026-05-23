class TasksController < ApplicationController
  before_action :set_task, only: %i[ show update destroy ]

  def index
    tasks = Task.includes(:status).order(:id)
    render json: TaskSerializer.collection(tasks)
  end

  def show
    render json: TaskSerializer.call(@task)
  end

  def create
    task = Tasks::Write.call(task: Task.new, attributes: task_params)

    if task.persisted?
      render json: TaskSerializer.call(task), status: :created
    else
      render json: { errors: task.errors }, status: :unprocessable_entity
    end
  end

  def update
    task = Tasks::Write.call(task: @task, attributes: task_params)

    if task.errors.empty?
      render json: TaskSerializer.call(task)
    else
      render json: { errors: task.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    head :no_content
  end

  private

  def set_task
    @task = Task.includes(:status).find(params[:id])
  end

  def task_params
    params.permit(:name, :description, :scheduled_at, :status)
  end
end
