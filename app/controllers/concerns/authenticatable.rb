module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    @current_user = User.find_by(auth_token: bearer_token) if bearer_token.present?
    return if @current_user

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def current_user
    @current_user
  end

  def bearer_token
    authorization = request.headers["Authorization"]
    return unless authorization&.start_with?("Bearer ")

    authorization.delete_prefix("Bearer ").strip.presence
  end
end
