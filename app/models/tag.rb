class Tag < ApplicationRecord
  SYSTEM_NAMES = %w[отчетность операции звонок].freeze

  has_many :tags_tasks, dependent: :destroy
  has_many :tasks, through: :tags_tasks

  validates :name, presence: true, uniqueness: true

  before_update :prevent_system_tag_update
  before_destroy :prevent_system_tag_destroy

  def self.system_tag?(name)
    SYSTEM_NAMES.include?(name)
  end

  def system_tag?
    self.class.system_tag?(name_in_database)
  end

  private

  def prevent_system_tag_update
    return unless system_tag?

    errors.add(:base, "system tags cannot be modified")
    throw :abort
  end

  def prevent_system_tag_destroy
    return unless system_tag?

    errors.add(:base, "system tags cannot be deleted")
    throw :abort
  end
end
