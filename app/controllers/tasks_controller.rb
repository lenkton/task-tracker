class TasksController < ApplicationController
  before_action :set_task, only: %i[ show update destroy ]

  def index
    tasks = Task.includes(:status).order(:id)
    render json: tasks, include: status_json_options
  end

  def show
    render json: @task, include: status_json_options
  end

  def create
    task = Task.new(task_params)

    if task.save
      render json: task, include: status_json_options, status: :created
    else
      render json: { errors: task.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      render json: @task, include: status_json_options
    else
      render json: { errors: @task.errors }, status: :unprocessable_entity
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
    params.require(:task).permit(:name, :description, :scheduled_at, :status_id)
  end

  def status_json_options
    { status: { only: %i[ id name ] } }
  end
end
