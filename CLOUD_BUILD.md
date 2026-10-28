# Сборка и подпись FitLife APK

Workflow **Build FitLife APK** запускается при push в `main`, в pull request
и вручную через GitHub Actions. Он использует Flutter 3.44.7 и Java 17,
проверяет lockfile, запускает строгий анализ, все тесты и release-сборку.
Исходники и тесты во время сборки не перезаписываются и не удаляются.

После успешного запуска скачайте артефакт **FitLife-APK**, внутри которого
находится `app-release.apk`. Артефакт хранится 30 дней.

## Постоянная подпись

Для обновлений приложения нужен один и тот же ключ. Локальный финальный APK
подписывается отдельным ключом FitLife; сохраняйте каталог `fitlife-signing`
рядом с рабочим репозиторием. Ключ и пароль не входят в Git и архив исходников.

Gradle читает переменные окружения:

| Переменная | Назначение |
| --- | --- |
| `FITLIFE_KEYSTORE_PATH` | Абсолютный путь к JKS |
| `FITLIFE_STORE_PASSWORD` | Пароль хранилища |
| `FITLIFE_KEY_ALIAS` | Псевдоним ключа, по умолчанию `fitlife` |
| `FITLIFE_KEY_PASSWORD` | Пароль ключа, по умолчанию пароль хранилища |

Для идентичной подписи в GitHub Actions добавьте repository secrets:
`FITLIFE_KEYSTORE_BASE64` (JKS в Base64), `FITLIFE_STORE_PASSWORD` и,
при необходимости, `FITLIFE_KEY_ALIAS` и `FITLIFE_KEY_PASSWORD`.
Не публикуйте ключ, пароль или Base64 в issues, логах и исходниках.

Без ключа workflow собирает проверочный release APK с debug-подписью.
Его сертификат отличается от сертификата локального финального APK.
Android не позволяет устанавливать APK с другой подписью поверх существующего
приложения с тем же package ID `com.example.fitlife`.
Старые облачные APK могли использовать временный debug-ключ GitHub runner.

## Проверка подписи

```sh
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
```

После изменения интерфейса повторите анализ, тесты и release-сборку.
Список успешно завершённых старых сборок GitHub не подтверждает состояние
новых локальных изменений до их отправки в репозиторий.
