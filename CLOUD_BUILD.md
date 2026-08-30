# Сборка FitLife APK без установки Android Studio

Этот проект содержит GitHub Actions workflow, который автоматически собирает APK в облаке.

1. Создай пустой репозиторий на GitHub, например `fitlife`.
2. Распакуй этот ZIP.
3. Загрузи все файлы проекта в репозиторий.
4. Открой вкладку **Actions**.
5. Выбери **Build FitLife APK** и нажми **Run workflow**.
6. После окончания открой завершённый workflow → **Artifacts** → `FitLife-APK`.
7. Скачай `app-release.apk` и передай его на Samsung.

Workflow сам создаёт Android-часть Flutter-проекта, устанавливает зависимости и выполняет `flutter build apk --release`.

Официальная документация Flutter подтверждает сборку release APK командой `flutter build apk --release`.
