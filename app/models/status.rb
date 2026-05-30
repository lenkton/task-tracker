class Status < ApplicationRecord
  DELETED_NAME = "deleted"
  PROTECTED_NAMES = [ DELETED_NAME ].freeze

  has_many :tasks, dependent: :restrict_with_error

  validates :name, uniqueness: true, presence: true

  before_update :prevent_protected_status_update
  before_destroy :prevent_protected_status_destroy

  def protected_status?
    self.class.protected_status?(name_in_database)
  end

  def self.protected_status?(name)
    PROTECTED_NAMES.include?(name)
  end

  private

  def prevent_protected_status_update
    return unless protected_status?

    errors.add(:base, "protected statuses cannot be modified")
    throw :abort
  end

  def prevent_protected_status_destroy
    return unless protected_status?

    errors.add(:base, "protected statuses cannot be deleted")
    throw :abort
  end
end
