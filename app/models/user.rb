class User < ApplicationRecord
  has_many :tasks, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :auth_token, presence: true, uniqueness: true

  before_validation :generate_auth_token, on: :create

  private

  def generate_auth_token
    self.auth_token ||= SecureRandom.hex(32)
  end
end
