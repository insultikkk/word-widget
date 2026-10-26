<div align="center">
  <img src="assets/logo.svg" width="88" alt="Word Widget logo">
  <h1>Word Widget</h1>
  <p>A tiny, distraction-free vocabulary widget for Windows.</p>

  ![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-111318?style=flat-square&logo=windows)
  ![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-111318?style=flat-square&logo=powershell)
  ![License](https://img.shields.io/badge/license-MIT-111318?style=flat-square)
</div>

![Word Widget preview](assets/preview.png)

Word Widget keeps one English word, a simple English explanation, and a Russian translation visible while you work or study. It stays above normal windows, rotates words automatically, and uses no installer or external dependencies.

## Features

- Minimal dark interface with smooth rounded corners.
- 60 ready-to-use words from Units 16–18.
- Custom word lists with hundreds of entries.
- Random rotation without repeats until the whole list is shown.
- 15, 30, 60, 120, and 300 second intervals.
- Tray support, saved window position, and single-instance protection.
- Runs locally with the Windows PowerShell already included in Windows.

## Quick start

1. Download the repository as a ZIP and extract it.
2. Double-click **Start Word Widget.cmd**.

Windows 10 or 11 is recommended. No installation is required.

## Add your words

Edit `words.txt`. Use one entry per line:

```text
adolescent | teenager | подросток
aptitude | natural ability | талант / способность
```

The shorter `word | translation` format also works. Blank lines and lines starting with `#` are ignored. After saving, choose **Обновить слова** from the widget menu or wait for the next rotation.

## Controls

- **›** shows the next word.
- **×** hides the widget to the notification area.
- Double-click the tray icon to restore it.
- Right-click the widget or tray icon to edit words, change the interval, or exit.

The widget works above the desktop and ordinary application windows. Exclusive fullscreen games can cover standard Windows widgets.

---

## Русский

Word Widget — компактный виджет для изучения английских слов. Он показывает слово, простое объяснение на английском и перевод на русский, работает в фоне и автоматически меняет карточки.

Для запуска распакуйте архив и дважды нажмите **Start Word Widget.cmd**. Слова находятся в `words.txt`; свои строки добавляйте в формате `word | easy english | русский`. Установка библиотек не требуется.

## License

[MIT](LICENSE)

