# Seeds for create statuses migration
_Exported on 5/23/2026 at 15:10:47 GMT+3 from Cursor (3.2.21)_

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

---

**User**

@db/migrate/20260523102749_create_tasks.rb добавь модель

---

**Cursor**

Добавляю модель `Task` и связь в `Status`.


Добавлена модель `Task` и обратная связь в `Status`.

**`app/models/task.rb`**
- `belongs_to :status`
- валидации `name` и `scheduled_at` (обязательные поля)
- `description` не валидируется на presence — в миграции для него задан `default: ""`

**`app/models/status.rb`**
- `has_many :tasks, dependent: :restrict_with_error` — статус с задачами нельзя удалить без явной обработки

Миграция применена, модель в консоли проходит валидацию.

---

**User**

а добавь для задач пару записей для девелопмент окружения

а добавь для задач пару записей для девелопмент окружения в сиды

---

**Cursor**

В `db/seeds.rb` добавлен блок только для `development`: две задачи с разными статусами, через `find_or_create_by!` по `name` — повторный `db:seed` не создаёт дубликаты.

| Задача | Статус |
|--------|--------|
| Review pull requests | `todo` |
| Implement task tracker API | `in_progress` |

В production и test эти записи не создаются.

---

**User**

так, а можешь написать простенький CRUDL для задач? и тесты под это дело

---

**Cursor**

Изучаю структуру проекта и существующие соглашения перед добавлением CRUDL для задач.


API-only приложение — делаю JSON CRUDL и integration-тесты.


Тесты запустились; исправляю хрупкую проверку порядка в index.


Готово: JSON API для задач и 8 integration-тестов (все проходят).

### Эндпоинты

| Метод | Путь | Действие |
|-------|------|----------|
| `GET` | `/tasks` | список |
| `GET` | `/tasks/:id` | одна задача |
| `POST` | `/tasks` | создать |
| `PATCH/PUT` | `/tasks/:id` | обновить |
| `DELETE` | `/tasks/:id` | удалить |

Тело запроса (JSON):

```json
{
  "task": {
    "name": "Write tests",
    "description": "Optional text",
    "scheduled_at": "2026-05-26T09:00:00Z",
    "status_id": 1
  }
}
```

Ответ включает вложенный `status` с полями `id` и `name`. Ошибки валидации — `422` с `{ "errors": { ... } }`, несуществующая задача — `404`.

### Что добавлено

- `app/controllers/tasks_controller.rb`
- `config/routes.rb` — `resources :tasks`
- `test/fixtures/statuses.yml`, `test/fixtures/tasks.yml`
- `test/controllers/tasks_controller_test.rb` — index, show, create, update, destroy + ошибки валидации и 404

Пример:

```bash
curl -s http://localhost:3000/tasks | jq
curl -s -X POST http://localhost:3000/tasks \
  -H "Content-Type: application/json" \
  -d '{"task":{"name":"New task","scheduled_at":"2026-05-26T09:00:00Z","status_id":1}}'
```

---

**User**

перепиши тесты на rspec

---

**Cursor**

Проверяю текущую настройку RSpec и существующие тесты.


Создаю RSpec request-спеки, переношу фикстуры и обновляю CI.


Тесты перенесены с Minitest на RSpec.

### Что сделано

- **`spec/requests/tasks_spec.rb`** — те же 8 сценариев, что были в integration-тестах
- **`spec/fixtures/`** — фикстуры перенесены из `test/fixtures/`
- **Удалена папка `test/`** (minitest больше не используется)
- **`.rspec`** — подключает `rails_helper`
- **`spec/rails_helper.rb`** — включён `infer_spec_type_from_file_location!`
- **CI** (`config/ci.rb`, `.github/workflows/ci.yml`) — запуск через `bundle exec rspec`
- **`.rubocop.yml`** — для `spec/requests` отключены `ExampleLength` и `MultipleExpectations` (типично для API-спеков)

Запуск:

```bash
bundle exec rspec
# или один файл:
bundle exec rspec spec/requests/tasks_spec.rb
```

Все 8 примеров проходят.

---

**User**

@spec/requests/tasks_spec.rb:9-11 сделай это хелпером (или как они тут называются в рспеке)

---

**Cursor**

Вынесу `json` в support-модуль и подключу его для request-спеков.


В RSpec такие вещи обычно лежат в **`spec/support/`** — это support-файлы, которые подключаются из `rails_helper`.

**`spec/support/json_response.rb`** — модуль-хелпер:

```ruby
module JsonResponse
  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include JsonResponse, type: :request
end
```

`config.include` подмешивает методы модуля в примеры с `type: :request` (для файлов в `spec/requests/` тип выводится через `infer_spec_type_from_file_location!`).

В `rails_helper` раскомментирована автозагрузка support-файлов. В `tasks_spec.rb` локальный `def json` убран — `json` доступен как и раньше.

---

**User**

@spec/requests/tasks_spec.rb перепиши, чтобы в тестах был только 1 expect

---

**Cursor**

Спеки разбиты на отдельные примеры с одним `expect` в каждом. Общий запрос вынесен в `before`, для `POST`/`DELETE` с проверкой счётчика — отдельный `it` с блоком `change`.

Было 8 примеров с несколькими `expect` → стало **24 примера**, все проходят. Структура:

- **`before`** — один HTTP-запрос на группу
- **`it { expect(...) }`** — одна проверка
- **`context "after request"`** — ответ после запроса, когда нужен отдельный пример на `change`

---

**User**

@spec/requests/tasks_spec.rb:26-28 дай этому название

---

**Cursor**

Готово — пример теперь называется `"returns fixture task names"`.

---

**User**

@/home/sergey/.cursor/projects/home-sergey-code-ruby-task-tracker/terminals/1.txt:993-1013 поправь замечания рубокопа

---

**Cursor**

Упрощаю вложенность и переименовываю контексты под правила RuboCop.


Сделано двумя изменениями:

1. **Вложенность** — вместо `describe → context → context "after request"` отдельные `describe` на одном уровне, например `POST /tasks with valid params when submitted`.
2. **ContextWording** — контексты переименованы в `when submitted` / `when deleted` (префиксы `when` / `with`).

RuboCop без замечаний, все 26 примеров проходят.

---

**User**

не, я ревертнул.

давай вот вложенность - увеличим лимит в .rubocop.yml, а навзания контекстов - как ты предложил

---

**Cursor**

Сделано:

**`.rubocop.yml`** — лимит вложенности поднят до 4:

```yaml
RSpec/NestedGroups:
  Max: 4
```

**`spec/requests/tasks_spec.rb`** — контексты переименованы:
- `after request` → `when submitted` (POST)
- `after request` → `when deleted` (DELETE)

Структура спеков как была, RuboCop без замечаний.

