# Seeds for create statuses migration
_Exported on 5/23/2026 at 13:20:51 GMT+3 from Cursor (3.2.21)_

---

**User**

@db/migrate/20260523094307_create_statuses.rb напиши сиды для этой миграции

---

**Cursor**

Просматриваю миграцию и структуру проекта, чтобы написать сиды.


Добавляю идемпотентные сиды со стандартными статусами таск-трекера (нижний регистр, по README).


В `db/seeds.rb` добавлены идемпотентные сиды для четырёх базовых статусов:

| name | смысл |
|------|--------|
| `todo` | ещё не начата |
| `in_progress` | в работе |
| `done` | завершена |
| `cancelled` | отменена |

Имена в нижнем регистре и на английском — как в README. Запись через `find_or_create_by!`, поэтому `bin/rails db:seed` можно запускать повторно.

```ruby
%w[todo in_progress done cancelled].each do |status_name|
  Status.find_or_create_by!(name: status_name)
end
```

Сиды уже прогнаны — в базе есть эти четыре статуса (плюс `new`, если он был создан раньше вручную). Если нужен другой набор (например, `backlog` / `review` вместо `cancelled`), напиши — поправлю.

