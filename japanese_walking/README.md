# Японская ходьба (Japanese Interval Walking)

Приложение для интервальной ходьбы по методу университета Синсю (IWT): 3 минуты быстро → 3 минуты спокойно, 5 циклов = 30 минут.

## Возможности

- Таймер интервалов 3/3 (длительность фазы и число циклов настраиваются)
- Метроном «тик-ток» под темп шага — отдельный темп для быстрой и спокойной фазы, регулируется на ходу кнопками ±
- При смене фазы: вибрация (разные паттерны: 3 коротких = «ускорься», 1 длинная = «замедлись») + разные звуковые сигналы
- Подключение умных часов / пульсометра по Bluetooth LE (стандартный сервис Heart Rate 0x180D) — живой пульс на экране
- Тёмная тема Material 3, экран не гаснет во время тренировки
- Два языка: русский / английский (переключатель в настройках)
- Все настройки сохраняются между запусками

## Сборка

Требуется [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.32+.

```bash
cd japanese_walking

# 1. Сгенерировать платформенные папки (android/, ios/)
flutter create . --platforms=android,ios --org com.example

# 2. Сгенерировать звуковые файлы (Python 3, без зависимостей)
python3 tools/generate_audio.py

# 3. Зависимости и запуск
flutter pub get
flutter run
```

## Разрешения (добавить после `flutter create`)

**Android** — `android/app/src/main/AndroidManifest.xml`, внутри `<manifest>`:

```xml
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<!-- для Android 11 и ниже -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
```

Минимальный SDK в `android/app/build.gradle`: `minSdk = 21`.

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Подключение пульсометра или часов для отображения пульса во время ходьбы</string>
```

## Интеграция с умными часами — что реально работает

| Устройство | Как подключить |
|---|---|
| Garmin, Polar, Suunto, Coros, Amazfit | Включить на часах режим «трансляция пульса» (Broadcast HR) → приложение найдёт их через Bluetooth |
| Нагрудные пульсометры (Polar H10, Garmin HRM и т.п.) | Работают сразу, ничего включать не нужно |
| **Apple Watch** | Не транслируют пульс по BLE. Варианты: приложение-мост (HeartCast, BlueHeart, ECG HR) либо нативный companion-app на WatchKit + HealthKit |
| **Wear OS (Pixel Watch, Galaxy Watch)** | По умолчанию не транслируют. Варианты: приложение-мост на часах либо companion-app + Health Connect |

Для глубокой интеграции (запуск тренировки с часов, вибрация на запястье) нужны companion-приложения: WatchKit (Swift) для Apple Watch и Wear OS (Kotlin) — в пакет не входят, но архитектура (`SessionController` отделён от UI) позволяет добавить их без переписывания логики.

Опционально: раскомментируйте пакет `health` в `pubspec.yaml`, чтобы читать шаги/пульс из HealthKit (iOS) и Health Connect (Android) после тренировки.

## Структура

```
lib/
  main.dart                      — точка входа
  theme.dart                     — тема (Material 3, dark-first)
  l10n/strings.dart              — локализация RU/EN
  models/app_settings.dart       — настройки + сохранение
  services/metronome.dart        — метроном с коррекцией дрейфа
  services/session_controller.dart — машина состояний тренировки
  services/heart_rate_service.dart — BLE-пульс (сервис 0x180D)
  ui/home_screen.dart            — главный экран
  ui/session_screen.dart         — экран тренировки (кольцо прогресса)
  ui/settings_screen.dart        — настройки
tools/generate_audio.py          — генератор звуков (tick/tock/фазы/финиш)
```

## О методе

Метод разработали профессор Хироси Носэ и доцент Сидзуэ Масуки (Университет Синсю, Япония). Чередование 3 минут быстрой ходьбы (~70% от пиковой аэробной мощности, «тяжело разговаривать») и 3 минут спокойной, минимум 30 минут 4–5 раз в неделю. В исследованиях за 5 месяцев: рост аэробной выносливости ~10%, снижение давления и сахара в крови, укрепление мышц ног, снижение риска возрастных заболеваний до 20%.
