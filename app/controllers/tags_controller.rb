class TagsController < ApplicationController
  before_action :set_tag, only: %i[ show update destroy ]

  def index
    tags = Tag.order(:id)
    render json: TagSerializer.collection(tags)
  end

  def show
    render json: TagSerializer.call(@tag)
  end

  def create
    result = Tags::Write.call(tag: Tag.new, attributes: tag_params)

    if result.success?
      render json: TagSerializer.call(result.value), status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def update
    result = Tags::Write.call(tag: @tag, attributes: tag_params)

    if result.success?
      render json: TagSerializer.call(result.value)
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @tag.destroy
      head :no_content
    else
      render json: { errors: @tag.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.permit(:name)
  end
end
