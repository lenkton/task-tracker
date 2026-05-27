# Join-таблица tags ↔ tasks без колонки id (см. миграцию create_join_table).
# Модель нужна для валидаций и has_many :through; primary key у записей нет.
class TagsTask < ApplicationRecord
  belongs_to :tag
  belongs_to :task

  # WARN: could throw an exception even on a Task#update without a !
  validates :tag_id, uniqueness: { scope: :task_id }
end
