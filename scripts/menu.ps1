# =============================================================================
# Помощник сайта vaudit27.ru
# Запускается через ПОМОЩНИК.bat в корне проекта.
# =============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

$ROOT = Split-Path -Parent $PSScriptRoot
Set-Location $ROOT

function Pause-Anykey {
    param([string]$Text = "Нажмите Enter, чтобы вернуться в меню")
    Write-Host ""
    Write-Host $Text -ForegroundColor DarkGray
    [void][Console]::ReadLine()
}

function Check-Hugo {
    $h = Get-Command hugo -ErrorAction SilentlyContinue
    if (-not $h) {
        Write-Host ""
        Write-Host "❌ Hugo не установлен на компьютере." -ForegroundColor Red
        Write-Host "   Скачать: https://github.com/gohugoio/hugo/releases" -ForegroundColor Yellow
        Write-Host "   Берите файл со словом 'extended' для Windows." -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Check-Git {
    $g = Get-Command git -ErrorAction SilentlyContinue
    if (-not $g) {
        Write-Host ""
        Write-Host "❌ Git не установлен." -ForegroundColor Red
        Write-Host "   Скачать: https://git-scm.com/download/win" -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Check-GitRepo {
    if (-not (Test-Path (Join-Path $ROOT ".git"))) {
        Write-Host ""
        Write-Host "❌ Эта папка ещё не подключена к GitHub." -ForegroundColor Red
        Write-Host "   Чтобы автоматическая публикация работала, разработчик должен:" -ForegroundColor Yellow
        Write-Host "     1. Создать репозиторий на github.com" -ForegroundColor Yellow
        Write-Host "     2. Выполнить в этой папке: git init && git remote add origin <ссылка>" -ForegroundColor Yellow
        Write-Host "     3. Настроить .github/workflows/deploy.yml для автодеплоя" -ForegroundColor Yellow
        Write-Host "     4. Задеплоить первый раз вручную" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Свяжитесь с разработчиком." -ForegroundColor Yellow
        return $false
    }
    return $true
}

# -----------------------------------------------------------------------------
# 1. Запуск локального сервера
# -----------------------------------------------------------------------------
function Start-LocalServer {
    Clear-Host
    Write-Host "═══ Запуск локального сайта ═══" -ForegroundColor Cyan
    Write-Host ""
    if (-not (Check-Hugo)) { Pause-Anykey; return }

    Write-Host "Запускаю сайт по адресу http://localhost:1313/"
    Write-Host "Откройте этот адрес в браузере (откроется автоматически)."
    Write-Host ""
    Write-Host "Чтобы остановить сервер — закройте новое чёрное окно или нажмите Ctrl+C в нём." -ForegroundColor Yellow
    Write-Host ""

    Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "title Восток-Аудит — локальный сайт && cd /d `"$ROOT`" && hugo server"
    Start-Sleep -Seconds 3
    Start-Process "http://localhost:1313/"
    Pause-Anykey
}

# -----------------------------------------------------------------------------
# 2. Добавление нового года раскрытия информации
# -----------------------------------------------------------------------------
function Add-DisclosureYear {
    Clear-Host
    Write-Host "═══ Добавить новый год раскрытия информации ═══" -ForegroundColor Cyan
    Write-Host ""
    if (-not (Check-Hugo)) { Pause-Anykey; return }

    $year = Read-Host "Введите год (например, 2025)"
    if ($year -notmatch '^\d{4}$') {
        Write-Host "❌ Год должен состоять из 4 цифр." -ForegroundColor Red
        Pause-Anykey; return
    }

    $target = "content/about/disclosure/$year.md"
    if (Test-Path $target) {
        Write-Host "⚠ Файл $target уже существует. Откройте его для редактирования." -ForegroundColor Yellow
        Start-Process notepad.exe (Join-Path $ROOT $target)
        Pause-Anykey; return
    }

    & hugo new --kind disclosure $target
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Не удалось создать файл." -ForegroundColor Red
        Pause-Anykey; return
    }

    Write-Host ""
    Write-Host "✓ Файл создан: $target" -ForegroundColor Green
    Write-Host ""
    Write-Host "ЧТО ДАЛЬШЕ:" -ForegroundColor Cyan
    Write-Host "  1. В открывшемся окне Блокнота найдите раздел 'Сведения о выручке'"
    Write-Host "  2. Замените прочерки '___' на реальные цифры (3 числа)"
    Write-Host "  3. Если за год были новые проверки СРО/УФК — добавьте их в список"
    Write-Host "  4. Удалите все строчки <!-- TODO -->"
    Write-Host "  5. Сохраните файл (Ctrl+S)"
    Write-Host "  6. Вернитесь сюда и выберите пункт 6 (Опубликовать изменения)"
    Write-Host ""

    Start-Process notepad.exe (Join-Path $ROOT $target)
    Pause-Anykey
}

# -----------------------------------------------------------------------------
# 3. Добавление публикации в прессу
# -----------------------------------------------------------------------------
function Add-PressArticle {
    Clear-Host
    Write-Host "═══ Добавить публикацию в прессу ═══" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ПЕРЕД ТЕМ как продолжить — положите картинку (скан публикации)" -ForegroundColor Yellow
    Write-Host "в папку: $ROOT\static\images\" -ForegroundColor Yellow
    Write-Host "Например: 'Моя_публикация_2025.webp'" -ForegroundColor Yellow
    Write-Host ""
    $ok = Read-Host "Картинка уже в папке? (да/нет)"
    if ($ok -notmatch '^(да|y|yes|д)') { Pause-Anykey; return }

    $img = Read-Host "Имя файла картинки (без 'images/', только имя)"
    if (-not $img) { Pause-Anykey; return }
    $imgPath = Join-Path $ROOT "static\images\$img"
    if (-not (Test-Path $imgPath)) {
        Write-Host "⚠ Файл $imgPath не найден. Проверьте имя." -ForegroundColor Red
        Pause-Anykey; return
    }

    $date   = Read-Host "Дата публикации (например, 'Март 2025' или '2025 год')"
    $title  = Read-Host "Заголовок публикации"
    $source = Read-Host "Название издания (например, 'Дальневосточный капитал')"

    $entry = "`r`n- image: `"images/$img`"`r`n  date: `"$date`"`r`n  title: `"$title`"`r`n  source: `"$source`""
    Add-Content -Path (Join-Path $ROOT "data\press.yaml") -Value $entry -Encoding UTF8
    Write-Host ""
    Write-Host "✓ Публикация добавлена в data\press.yaml" -ForegroundColor Green
    Write-Host "   Чтобы увидеть результат — пункт 1 (запустить сайт локально),"
    Write-Host "   а потом пункт 6 (опубликовать)."
    Pause-Anykey
}

# -----------------------------------------------------------------------------
# 4. Добавление отзыва
# -----------------------------------------------------------------------------
function Add-Review {
    Clear-Host
    Write-Host "═══ Добавить отзыв клиента ═══" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ПЕРЕД ТЕМ как продолжить — положите скан отзыва" -ForegroundColor Yellow
    Write-Host "в папку: $ROOT\static\images\" -ForegroundColor Yellow
    Write-Host "Например: 'Отзыв_НоваяКомпания.webp'" -ForegroundColor Yellow
    Write-Host ""
    $ok = Read-Host "Картинка уже в папке? (да/нет)"
    if ($ok -notmatch '^(да|y|yes|д)') { Pause-Anykey; return }

    $img = Read-Host "Имя файла картинки (без 'images/', только имя)"
    if (-not $img) { Pause-Anykey; return }
    $imgPath = Join-Path $ROOT "static\images\$img"
    if (-not (Test-Path $imgPath)) {
        Write-Host "⚠ Файл $imgPath не найден." -ForegroundColor Red
        Pause-Anykey; return
    }

    $title = Read-Host "Название клиента (например, 'Новая Компания')"

    $entry = "`r`n- image: `"images/$img`"`r`n  title: `"$title`""
    Add-Content -Path (Join-Path $ROOT "data\reviews.yaml") -Value $entry -Encoding UTF8
    Write-Host ""
    Write-Host "✓ Отзыв добавлен в data\reviews.yaml" -ForegroundColor Green
    Pause-Anykey
}

# -----------------------------------------------------------------------------
# 5. Собрать готовый сайт (для проверки на ошибки)
# -----------------------------------------------------------------------------
function Build-Site {
    Clear-Host
    Write-Host "═══ Собрать готовый сайт ═══" -ForegroundColor Cyan
    Write-Host ""
    if (-not (Check-Hugo)) { Pause-Anykey; return }

    Write-Host "Запускаю Hugo (сборка займёт пару секунд)..."
    Write-Host ""
    & hugo --minify
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ Сборка завершилась с ошибкой. См. сообщение выше." -ForegroundColor Red
        Pause-Anykey; return
    }
    Write-Host ""
    Write-Host "✓ Сайт собран в папку 'public/'." -ForegroundColor Green
    Write-Host "   Эту папку можно загрузить на любой статический хостинг."
    Write-Host "   Если у вас настроен GitHub Action — используйте лучше пункт 6 (Опубликовать)."
    Pause-Anykey
}

# -----------------------------------------------------------------------------
# 6. Публикация изменений
# -----------------------------------------------------------------------------
function Publish-Changes {
    Clear-Host
    Write-Host "═══ Опубликовать изменения ═══" -ForegroundColor Cyan
    Write-Host ""
    if (-not (Check-Git))     { Pause-Anykey; return }
    if (-not (Check-GitRepo)) { Pause-Anykey; return }

    # Сначала собираем — если есть ошибки, не публикуем сломанное.
    if (-not (Check-Hugo)) { Pause-Anykey; return }
    Write-Host "→ Проверяю сборку перед публикацией..."
    & hugo --minify --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Сборка не удалась. Сначала исправьте ошибки." -ForegroundColor Red
        Pause-Anykey; return
    }
    Write-Host "  Сборка OK." -ForegroundColor Green
    Write-Host ""

    # Что изменилось?
    $status = git status --porcelain
    if (-not $status) {
        Write-Host "✓ Изменений нет — публиковать нечего." -ForegroundColor Green
        Pause-Anykey; return
    }

    Write-Host "Будут опубликованы следующие изменения:" -ForegroundColor Yellow
    git status --short
    Write-Host ""
    $msg = Read-Host "Опишите изменения одной строкой (например: 'добавил год 2025')"
    if (-not $msg) { $msg = "обновление контента" }

    Write-Host ""
    Write-Host "→ Сохраняю изменения..."
    git add . | Out-Null
    git commit -m "$msg" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Ошибка при коммите. См. сообщение выше." -ForegroundColor Red
        Pause-Anykey; return
    }

    Write-Host "→ Отправляю на GitHub..."
    git push
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ Push не удался. Возможные причины:" -ForegroundColor Red
        Write-Host "   • Нет интернета" -ForegroundColor Yellow
        Write-Host "   • Git не авторизован в GitHub (нужен токен или SSH-ключ)" -ForegroundColor Yellow
        Write-Host "   • Не добавлен remote (ссылка на репо)" -ForegroundColor Yellow
        Write-Host "   Свяжитесь с разработчиком." -ForegroundColor Yellow
        Pause-Anykey; return
    }

    Write-Host ""
    Write-Host "✓ Готово! Сайт обновится через 1-2 минуты." -ForegroundColor Green
    Write-Host "  Откройте https://vaudit27.ru/ через минуту, чтобы убедиться."
    Pause-Anykey
}

# -----------------------------------------------------------------------------
# Главное меню
# -----------------------------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║       Помощник сайта  vaudit27.ru                 ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Что вы хотите сделать?"
    Write-Host ""
    Write-Host "    1) 👁  Посмотреть сайт у себя на компьютере"
    Write-Host "    2) 📅 Добавить новый год раскрытия информации"
    Write-Host "    3) 📰 Добавить публикацию в раздел Пресса"
    Write-Host "    4) 💬 Добавить отзыв клиента"
    Write-Host "    5) 🔨 Собрать готовый сайт (проверка на ошибки)"
    Write-Host "    6) 🚀 Опубликовать изменения (отправить на сайт)"
    Write-Host ""
    Write-Host "    0) Выйти"
    Write-Host ""
    $choice = Read-Host "  Введите номер"

    switch ($choice) {
        "1" { Start-LocalServer }
        "2" { Add-DisclosureYear }
        "3" { Add-PressArticle }
        "4" { Add-Review }
        "5" { Build-Site }
        "6" { Publish-Changes }
        "0" { exit }
        default {
            Write-Host "  Не понял. Введите число от 0 до 6." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
