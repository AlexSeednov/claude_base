[English](README.md) | **Русский**

# claude_base

Общая конфигурация **Claude Code** для Flutter/Dart-проектов с чистой
архитектурой. Живёт в одном месте и переиспользуется всеми проектами: изменение
вносится один раз здесь, а не копипастится в каждый репозиторий.

Репозиторий выполняет сразу две роли:

- **маркетплейс плагинов** (`claude-base`), через который распространяется
  **плагин `flutter-base`** — скиллы для тестов и аудита рефакторинга, а также
  хуки Telegram-уведомлений;
- хранилище **постоянно действующих файлов инструкций** (`instructions/`),
  которые `CLAUDE.md` проекта подтягивает через `@import`.

Каналов два, потому что содержимое разное. Плагин распространяет исполняемый
инструментарий (скиллы, хуки, команды) и чисто обновляется через
`/plugin update`. Файлы инструкций — постоянно действующий контекст, и их нужно
импортировать в `CLAUDE.md` через `@import`: плагин Claude Code **не**
загружает `CLAUDE.md`, а скиллы подгружаются по требованию, а не всегда.
Поэтому один репозиторий обслуживает оба канала через два механизма, описанных
ниже.

## Чего здесь нет

Конфигурация, специфичная для проекта, остаётся в самом проекте и намеренно **не**
входит в эту базу:

- собственный `CLAUDE.md` проекта и любые импортируемые им файлы проектных
  инструкций (ссылки на дизайн, эндпоинты API, правила только для этого проекта);
- `.claude/settings.local.json` (локален для машины, хранит секреты вроде токена
  Telegram — см. [Telegram-хуки](#telegram-хуки));
- проектные записи в `settings.json` (включённые MCP-серверы, разрешения или
  исключаемые пути, нужные только этому проекту).

## Структура репозитория

```text
claude_base/
├── .claude-plugin/
│   └── marketplace.json          # marketplace catalog: lists the flutter-base plugin
├── plugin/                       # the flutter-base plugin (marketplace "source": "./plugin")
│   ├── .claude-plugin/
│   │   └── plugin.json           # plugin manifest (name, version, metadata)
│   ├── hooks/
│   │   └── hooks.json            # Stop + PreToolUse hooks, paths via ${CLAUDE_PLUGIN_ROOT}
│   ├── scripts/                  # hook implementations
│   │   ├── dispatch.js           # cross-platform launcher (picks .sh on Unix, .ps1 on Windows)
│   │   ├── telegram-notify.sh    # Stop notification (Unix)
│   │   ├── telegram-notify.ps1   # Stop notification (Windows)
│   │   ├── telegram-waiting.sh   # PreToolUse notification (Unix)
│   │   ├── telegram-waiting.ps1  # PreToolUse notification (Windows)
│   │   ├── project-name.sh       # project-name resolver shared by both hooks (Unix)
│   │   └── project-name.ps1      # project-name resolver shared by both hooks (Windows)
│   └── skills/                   # auto-discovered when the plugin is installed
│       ├── dart-add-unit-test/
│       ├── dart-checks-assertions/
│       ├── dart-collect-coverage/
│       ├── flutter-add-widget-test/
│       ├── flutter-add-integration-test/
│       ├── flutter-refactor-audit/
│       └── flutter-test-doubles/
├── instructions/                 # always-on context, consumed via @import (NOT part of the plugin)
│   ├── global.md
│   ├── architecture.md
│   ├── dart-conventions.md
│   ├── packages.md
│   └── layers.md
├── CHANGELOG.md
├── LICENSE
├── README.md
└── README.ru.md
```

## Быстрый старт

Два независимых шага на каждый проект. Выполняются один раз; обновление описано
в разделе [Обновление](#обновление).

1. **Установите плагин** (скиллы + хуки) — один раз на машину, затем включите его
   в каждом проекте. См. [Плагин](#плагин).
2. **Подключите инструкции** в `CLAUDE.md` проекта — см.
   [Инструкции](#инструкции).

## Плагин

Плагин `flutter-base` распространяется через маркетплейс `claude-base`, а
маркетплейс — это просто этот git-репозиторий.

### Ручная установка

На каждой машине, один раз:

```text
/plugin marketplace add https://github.com/AlexSeednov/claude_base.git
/plugin install flutter-base@claude-base
```

`/plugin marketplace add` регистрирует каталог; `/plugin install` скачивает
плагин в локальный кеш плагинов. Маркетплейс регистрируется на уровне
пользователя (хранится в `~/.claude/plugins/known_marketplaces.json`), поэтому
регистрация распространяется на все проекты на этой машине.

Репозиторий публичный, поэтому аутентификация не нужна. Приватный репозиторий
работал бы точно так же — он клонировался бы с вашими существующими учётными
данными git.

### Автоматическое включение в проекте (рекомендуется, готово для команды)

Закоммитьте это в `.claude/settings.json` проекта — тогда каждый, кто отметит
папку проекта как доверенную, получит предложение добавить маркетплейс, а плагин
включится у него автоматически:

```json
{
  "extraKnownMarketplaces": {
    "claude-base": {
      "source": {
        "source": "github",
        "repo": "AlexSeednov/claude_base"
      }
    }
  },
  "enabledPlugins": {
    "flutter-base@claude-base": true
  }
}
```

В `enabledPlugins` ключом плагина служит его идентификатор `name@marketplace`.
Не переименовывайте потом ни плагин, ни маркетплейс — именно по этому ключу на
него ссылается каждая установка.

## Инструкции

Пять файлов в `instructions/` — постоянно действующий контекст. `CLAUDE.md`
проекта подтягивает их через `@import`. Выберите один из двух вариантов доставки
ниже; итог у обоих один: `CLAUDE.md` импортирует один и тот же набор файлов.

Впервые встретив в проекте внешний импорт, Claude Code один раз показывает
диалог подтверждения со списком файлов.

### Вариант A — импорт из локального клона

Клонируйте этот репозиторий один раз на каждую машину по стабильному пути
относительно домашнего каталога (рядом с остальными вашими пакетами) и
импортируйте из него. Рекомендуется, если вы в основном работаете в одиночку на
нескольких компьютерах: один `git pull` обновляет инструкции сразу во всех
проектах.

```bash
git clone https://github.com/AlexSeednov/claude_base.git ~/Projects/Packages/claude_base
```

В `CLAUDE.md` каждого проекта:

```text
@~/Projects/Packages/claude_base/instructions/global.md
@~/Projects/Packages/claude_base/instructions/architecture.md
@~/Projects/Packages/claude_base/instructions/dart-conventions.md
@~/Projects/Packages/claude_base/instructions/packages.md
@~/Projects/Packages/claude_base/instructions/layers.md

@.claude/project.md
```

Держите путь к клону одинаковым на всех ваших машинах (и у коллег по команде),
чтобы импорты относительно `~/` разрешались везде. При этом варианте репозиторий
проекта сам по себе не самодостаточен — свежему чекауту нужен клон на месте.

### Вариант B — вендоринг через git subtree

Встройте копию этого репозитория в проект под `.claude/base/` — тогда обычный
`git clone` проекта уже содержит инструкции (работает у коллег и в CI без
дополнительной настройки). Обратная сторона — обновление требует subtree pull и
коммита в каждом проекте, что заодно фиксирует инструкции на известной версии.

```bash
# once, to add:
git subtree add --prefix .claude/base \
  https://github.com/AlexSeednov/claude_base.git main --squash
```

В `CLAUDE.md` каждого проекта:

```text
@.claude/base/instructions/global.md
@.claude/base/instructions/architecture.md
@.claude/base/instructions/dart-conventions.md
@.claude/base/instructions/packages.md
@.claude/base/instructions/layers.md

@.claude/project.md
```

> Скиллы ссылаются на инструкции по названию файла и раздела (Dart
> Conventions → *Singleton Pattern*), а не по пути: `CLAUDE.md` уже загрузил их
> в контекст, а путь подошёл бы только к одному из двух вариантов. Со скиллами
> работает любой вариант, ничего настраивать не нужно.

## Telegram-хуки

Плагин поставляется с двумя хуками, которые отправляют сообщение в Telegram:

- **`Stop`** — когда сессия завершается (`telegram-notify`). В сообщение в
  качестве имени сессии попадает первый промпт пользователя.
- **`PreToolUse`** с матчером `AskUserQuestion` — когда Claude задаёт
  уточняющий вопрос и ждёт вас (`telegram-waiting`).

`dispatch.js` — точка входа в обоих: на Unix он запускает реализацию `.sh`, на
Windows — `.ps1`, так что одна строка команды в `hooks.json` работает на любой
платформе.

### Формат сообщения

Каждое сообщение начинается с иконки статуса и имени проекта, чтобы на телефоне,
где видно сразу несколько сессий, всё оставалось читаемым:

```
✅ Claude: Stitchy — Convert the palette loader to a repository
✅ Claude: Stitchy done          # session with no prompt to quote
❓ Claude: Stitchy — Question
⚠️ Claude: Stitchy — Approval: git push --force
```

У правки этого формата есть одно ограничение: скрипты `.ps1` должны оставаться
**чистым ASCII** и собирать глифы из кодовых точек (`[char]0x2705`), как они
делают сейчас. Windows PowerShell 5.1 читает скрипт без BOM в системной кодовой
странице ANSI. Глиф, вставленный литералом, там может декодироваться в символ,
который обрывает окружающую строку, и хук падает с ошибкой парсера. Именно это
сломало все уведомления на Windows в 0.0.3. Варианты `.sh` принимают литералы
как есть.

### Имя проекта

`project-name.sh` / `.ps1` определяют имя; побеждает первое совпадение:

1. переменная окружения `CLAUDE_PROJECT_NAME`;
2. `name:` из `pubspec.yaml` в рабочем каталоге сессии;
3. имя этого каталога;
4. `Unknown project`.

Шаги 2–3 не требуют настройки. Переменная нужна, когда имя пакета или папки не
то, что вы хотите видеть на телефоне (`cross_stitch` → `Stitchy`). Задайте её в
блоке `env` файла `.claude/settings.local.json` проекта:

```json
{
  "env": {
    "CLAUDE_PROJECT_NAME": "Stitchy"
  }
}
```

### Учётные данные

Скрипты читают две переменные окружения и **не содержат секретов**:

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

Если хотя бы одной из них нет, каждый хук молча пропускает событие и никогда не
блокирует сессию. Задайте их один раз на машину в блоке `env` пользовательских
настроек (`~/.claude/settings.json`) или, если предпочитаете не держать их в
общем файле, — в `.claude/settings.local.json` проекта, добавленном в gitignore:

```json
{
  "env": {
    "TELEGRAM_BOT_TOKEN": "…",
    "TELEGRAM_CHAT_ID": "…"
  }
}
```

Никогда не коммитьте токен. Держите его в файле настроек, добавленном в
gitignore, или в пользовательских настройках.

### Опционально: уведомлять ещё и перед опасными shell-командами

`telegram-waiting` умеет уведомлять и перед рискованной командой `Bash`
(`rm`, `git push --force`, `--no-verify`, …), но поставляемый матчер покрывает
только `AskUserQuestion`. Чтобы включить ветку для Bash, добавьте `|Bash` к
матчеру `PreToolUse` в `plugin/hooks/hooks.json`:

```json
{ "matcher": "AskUserQuestion|Bash", "hooks": [ /* … */ ] }
```

## Скиллы

Все скиллы загружаются автоматически после установки плагина и видны как
`flutter-base:<name>`.

| Скилл                          | Назначение                                                                         |
| ------------------------------ | ---------------------------------------------------------------------------------- |
| `dart-add-unit-test`           | Юнит-тесты для domain/core-логики на чистом Dart; DI через `@visibleForTesting`-конструктор. |
| `dart-checks-assertions`       | Предпочитать `package:checks` (`check(x).equals(y)`) голым `expect`/матчерам.      |
| `dart-collect-coverage`        | Сбор покрытия в формате LCOV без учёта сгенерированного кода.                      |
| `flutter-add-widget-test`      | Компонентные/виджет-тесты с `WidgetTester` и UI на `ValueListenableBuilder`.       |
| `flutter-add-integration-test` | Сквозные сценарии на `integration_test` во всех флейворах.                         |
| `flutter-refactor-audit`       | Аудит закоммиченного кода: нарушения слоёв, дублирование, мёртвый код, нарушения конвенций. Перепроверяет находки, отвечает списком «обязательно» и списком «стоит сделать». |
| `flutter-test-doubles`         | Тестовые дублёры и подключение через getIt/injectable; фейки предпочтительнее моков. |

## Синглтоны и внедрение зависимостей (Singletons and dependency injection)

Это каноничный источник, на который ссылается `instructions/dart-conventions.md`.

Временем жизни синглтона владеет **getIt** (`@lazySingleton` / `@singleton`), а
не ручной `static final _instance`. Зависимости приходят через **конструктор**
(constructor injection), а не через вызовы `getIt<T>()` в теле. Конструктор
помечен `@visibleForTesting`: вне тестов анализатор запрещает создавать второй
экземпляр, а тест собирает изолированный экземпляр с фейками. `getIt.reset()`
действительно пересоздаёт объект между тестами, поэтому состояние не утекает.

```dart
/// First-level model: owns one domain area through its repository.
@lazySingleton
final class AccountModel {
  /// Constructor injection. @visibleForTesting so the analyzer blocks a second
  /// instance in app code, while a test can build an isolated one with fakes.
  @visibleForTesting
  AccountModel(this._repository);

  /// Contract from the domain layer; the concrete impl is bound in the data
  /// layer via @LazySingleton(as: AccountRepository) and injected by codegen.
  final AccountRepository _repository;

  /// UI-facing state; views listen via ValueListenableBuilder.
  final ValueNotifier<AccountEntity?> account = ValueNotifier(null);

  /// Async setup after the first frame (addPostFrameCallback).
  Future<void> prepare(Duration timeStamp) async {
    account.value = await _repository.fetchAccount();
  }
}
```

- `@lazySingleton` создаётся лениво, `@singleton` — сразу. Регистрация
  генерируется в `service_locator.config.dart` — никогда не регистрируйте
  вручную.
- **Не** используйте устаревший паттерн `_instance` + `factory .singleton()`:
  двойное управление жизненным циклом (static + getIt) приводит к утечке
  состояния между тестами.
- Сервисы из `application_base`, `firebase_base` и `metrica_base` доступны через
  injectable (внешние injectable-модули, подключённые в `@InjectableInit`) —
  получайте их через конструктор или через `getIt<T>()`. Зависимость,
  зарегистрированную **вне** кодогенерации (ручная регистрация), нельзя внедрить
  через конструктор — получайте её через `getIt<T>()` в теле метода.

В тесте сбросьте getIt, зарегистрируйте фейки и затем соберите модель через её
`@visibleForTesting`-конструктор:

```dart
setUp(() {
  getIt.reset();
  final repository = FakeAccountRepository();
  getIt.registerSingleton<AccountRepository>(repository);
  model = AccountModel(repository);
});
```

## Версионирование

Используйте **семантическое версионирование с git-тегами** — то же соглашение,
что и у остальных пакетов этого стека (`application_base`, `firebase_base`,
`metrica_base`). Это рекомендуемый ответ на вопрос «теги, ветки версий или
changelog?»: **теги плюс changelog в единственной ветке `main`, а не ветки,
названные по версиям.**

В каждом релизе вместе меняются три вещи:

1. **`version` в `plugin/.claude-plugin/plugin.json`** — Claude Code берёт версию
   плагина из этого поля и по ней определяет наличие обновлений: `/plugin
   update` подтягивает изменения, только когда эта строка меняется. Повышайте её
   в каждом релизе. Указывайте версию только в `plugin.json`, а не в записи
   маркетплейса: значение из манифеста молча побеждает, и версия, поднятая
   только в записи маркетплейса, была бы проигнорирована.
2. **Git-тег `vMAJOR.MINOR.PATCH`** — неизменяемая метка релиза, как у
   остальных пакетов. Он позволяет проекту при необходимости закрепить
   маркетплейс или subtree на точном ref.
3. **Запись в `CHANGELOG.md`** — история изменений в человекочитаемом виде.

Что означают номера для этого репозитория:

| Повышение | Когда                                                                                                  |
| --------- | ------------------------------------------------------------------------------------------------------ |
| **MAJOR** | Ломающее изменение: правило конвенций/архитектуры, которое вынуждает править проекты, или удаление/переименование скилла либо хука (что ломает ключи `enabledPlugins` и ссылки). |
| **MINOR** | Добавление: новый скилл, новый раздел инструкций, новый хук.                                           |
| **PATCH** | Правки формулировок и исправления багов в скриптах без изменения поведения для потребителей.           |

Файлы инструкций версионируются теми же тегами, поскольку живут в том же
репозитории. Вариант A (локальный клон) следует за той веткой/тегом, на которой
стоит клон; вариант B (subtree) закрепляет каждый проект на том коммите, который
в него завендорен.

**Альтернатива — скользящее версионирование / по SHA коммита.** В период
активных изменений поле `version` можно вовсе опустить; тогда Claude Code
считает каждый коммит новой версией, и `/plugin update` всегда подтягивает
`main`. Это настройка с минимумом формальностей, но она не даёт ни именованных
релизов, ни закрепления версий. Когда база стабилизируется, предпочитайте semver
с тегами, чтобы релизы можно было отследить, как у остальных ваших пакетов.

Избегайте веток, названных по версиям. Каналы релизов в Claude Code строятся на
различающихся разрешённых версиях (теги/SHA), а не на именах веток, и добавляют
сложность, которая базе для одного разработчика или небольшой команды не нужна.

## Обновление

Обновляются две независимые вещи, и **каждой нужен свой шаг**: обновление
плагина никогда не приносит инструкции, потому что `instructions/` импортируется
через `CLAUDE.md` и живёт вне плагина.

**Скиллы и хуки** — один раз на машину, после того как запушен новый релиз:

```text
/plugin marketplace update claude-base
/plugin update flutter-base@claude-base
```

**Инструкции** — зависит от того, какой вариант использует проект:

- **Вариант A (локальный клон):** `git pull` в `~/Projects/Packages/claude_base` —
  все проекты, которые из него импортируют, сразу подхватывают изменения.
- **Вариант B (subtree):** одна команда на проект, из его корня:

  ```bash
  GIT_MERGE_AUTOEDIT=no git subtree pull --prefix .claude/base \
    https://github.com/AlexSeednov/claude_base.git main --squash -m "Claude Base update"
  ```

  Она сама делает коммит — после неё ничего делать не нужно. Именно
  `GIT_MERGE_AUTOEDIT=no` и `-m` позволяют обойтись одной командой:
  `git subtree` под капотом вызывает обычный `git merge --no-ff`, который без них
  открывает `$EDITOR` с уже заполненным сообщением мержа. (Если всё же оказались
  в `vim`: `Esc`, затем `:wq`, Enter.)

В любом случае после этого **перезапустите сессию Claude**: импорты `CLAUDE.md`
читаются один раз при старте сессии, поэтому уже запущенная сессия продолжает
работать со старым текстом.

## Пополнение базы

- **Новый скилл:** создайте `plugin/skills/<name>/SKILL.md` с полями `name` и
  `description` во frontmatter. Он автоматически загрузится в следующей сессии
  после обновления плагина.
- **Новое правило в инструкциях:** отредактируйте файл в `instructions/` или
  добавьте новый и сошлитесь на него из `CLAUDE.md` проектов-потребителей.
- **Новый хук:** добавьте реализацию в `plugin/scripts/` и подключите её в
  `plugin/hooks/hooks.json`, указав путь через `${CLAUDE_PLUGIN_ROOT}`.

Затем повысьте версию, добавьте запись в `CHANGELOG.md`, закоммитьте, поставьте
тег и запушьте. Перед публикацией запустите `claude plugin validate ./plugin`,
чтобы проверить манифест, frontmatter скиллов/хуков и `hooks.json`.

Всё в этом репозитории ведите на **английском** и без имён и деталей какого-либо
отдельного проекта — им место в проекте-потребителе, а не в базе.
Единственное исключение — `README.ru.md`, русский перевод этого README: он
меняется вместе с английским, в той же правке (Global → *Package READMEs: Two
Languages*).
