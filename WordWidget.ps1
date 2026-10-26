param([switch]$SmokeTest)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$createdNew = $false
$instanceMutex = [System.Threading.Mutex]::new($true, 'Local\WordWidget', [ref]$createdNew)
if (-not $createdNew) {
    $instanceMutex.Dispose()
    if ($SmokeTest) { throw 'Close the running widget before starting the smoke test.' }
    return
}

$script:directory = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:wordsPath = Join-Path $script:directory 'words.txt'
$script:settingsPath = Join-Path $script:directory 'settings.json'
$script:words = @()
$script:order = @()
$script:orderIndex = 0
$script:lastIndex = -1
$script:lastModified = [datetime]::MinValue
$script:intervalSeconds = 60

if (-not (Test-Path -LiteralPath $script:wordsPath)) {
    @('# word | easy english | русский', 'hello | greeting word | привет') |
        Set-Content -LiteralPath $script:wordsPath -Encoding UTF8
}

if (Test-Path -LiteralPath $script:settingsPath) {
    try {
        $saved = Get-Content -LiteralPath $script:settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([int]$saved.IntervalSeconds -in @(15, 30, 60, 120, 300)) {
            $script:intervalSeconds = [int]$saved.IntervalSeconds
        }
    } catch { }
}

function Save-Settings {
    try {
        @{ IntervalSeconds = $script:intervalSeconds; Left = [int]$window.Left; Top = [int]$window.Top } |
            ConvertTo-Json | Set-Content -LiteralPath $script:settingsPath -Encoding UTF8
    } catch {
        if ($script:tray) {
            $script:tray.ShowBalloonTip(3000, 'Word Widget', 'Не удалось сохранить настройки.',
                [System.Windows.Forms.ToolTipIcon]::Warning)
        }
    }
}

function Load-Words {
    $loaded = [System.Collections.Generic.List[object]]::new()
    foreach ($line in (Get-Content -LiteralPath $script:wordsPath -Encoding UTF8)) {
        $entry = $line.Trim()
        if (-not $entry -or $entry.StartsWith('#')) { continue }
        $parts = $entry.Split('|')
        if ($parts.Count -notin @(2, 3)) { continue }
        $english = $parts[0].Trim()
        $easyEnglish = if ($parts.Count -eq 3) { $parts[1].Trim() } else { '' }
        $translation = $parts[$parts.Count - 1].Trim()
        if ($english -and $translation) {
            $loaded.Add([pscustomobject]@{
                English = $english
                EasyEnglish = $easyEnglish
                Translation = $translation
            })
        }
    }
    $script:words = $loaded.ToArray()
    $script:order = @()
    $script:orderIndex = 0
    $script:lastIndex = -1
    $script:lastModified = [System.IO.File]::GetLastWriteTimeUtc($script:wordsPath)
}

function New-Order {
    $script:order = @(0..($script:words.Count - 1))
    for ($index = $script:order.Count - 1; $index -gt 0; $index--) {
        $other = Get-Random -Minimum 0 -Maximum ($index + 1)
        $temporary = $script:order[$index]
        $script:order[$index] = $script:order[$other]
        $script:order[$other] = $temporary
    }
    if ($script:order.Count -gt 1 -and $script:order[0] -eq $script:lastIndex) {
        $other = Get-Random -Minimum 1 -Maximum $script:order.Count
        $temporary = $script:order[0]
        $script:order[0] = $script:order[$other]
        $script:order[$other] = $temporary
    }
    $script:orderIndex = 0
}

function Show-NextWord {
    try {
        if ([System.IO.File]::GetLastWriteTimeUtc($script:wordsPath) -ne $script:lastModified) {
            Load-Words
        }
    } catch {
        $englishLabel.Text = 'Не удалось открыть слова'
        $easyLabel.Text = 'Проверьте words.txt'
        $translationLabel.Text = ''
        return
    }
    if ($script:words.Count -eq 0) {
        $englishLabel.Text = 'Добавьте слова'
        $easyLabel.Text = 'Правый щелчок → Редактировать слова'
        $translationLabel.Text = ''
        return
    }
    if ($script:orderIndex -ge $script:order.Count) { New-Order }
    $index = $script:order[$script:orderIndex]
    $script:orderIndex++
    $script:lastIndex = $index
    $word = $script:words[$index]
    $englishLabel.Text = $word.English
    $englishLabel.ToolTip = $word.English
    $easyLabel.Text = $word.EasyEnglish
    $easyLabel.ToolTip = $word.EasyEnglish
    $translationLabel.Text = $word.Translation
    $translationLabel.ToolTip = $word.Translation
}

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Word Widget" Width="356" Height="158"
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True"
        Background="Transparent" Topmost="True" ShowInTaskbar="False"
        WindowStartupLocation="Manual" UseLayoutRounding="True">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#B7BBC0"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="ButtonSurface" Background="{TemplateBinding Background}" CornerRadius="7">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ButtonSurface" Property="Background" Value="#292B2E"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Border x:Name="Card" Margin="5" CornerRadius="18" Background="#141517"
            BorderBrush="#80FFFFFF" BorderThickness="1">
        <Border.Effect>
            <DropShadowEffect Color="Black" BlurRadius="12" ShadowDepth="2" Opacity="0.30"/>
        </Border.Effect>
        <Grid Margin="18,12,14,13">
            <Grid.RowDefinitions>
                <RowDefinition Height="24"/>
                <RowDefinition Height="44"/>
                <RowDefinition Height="28"/>
                <RowDefinition Height="27"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="ENGLISH  /  РУССКИЙ" VerticalAlignment="Center"
                       FontFamily="Segoe UI Variable Text" FontSize="10" FontWeight="SemiBold"
                       Foreground="#9DA1A7"/>
            <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="NextButton" Content="›" Width="26" Height="24"
                        FontFamily="Segoe UI" FontSize="22" Margin="0,0,4,0"/>
                <Button x:Name="HideButton" Content="×" Width="26" Height="24"
                        FontFamily="Segoe UI" FontSize="18"/>
            </StackPanel>
            <TextBlock x:Name="EnglishLabel" Grid.Row="1" VerticalAlignment="Center"
                       FontFamily="Segoe UI Variable Display" FontWeight="Bold" FontStretch="Expanded"
                       FontSize="26" Foreground="White" TextTrimming="CharacterEllipsis"/>
            <TextBlock x:Name="EasyLabel" Grid.Row="2" VerticalAlignment="Center"
                       FontFamily="Segoe UI Variable Text" FontSize="15" FontWeight="Medium"
                       Foreground="#B7BBC0" TextTrimming="CharacterEllipsis"/>
            <TextBlock x:Name="TranslationLabel" Grid.Row="3" VerticalAlignment="Center"
                       FontFamily="Segoe UI Variable Text" FontSize="15" FontWeight="SemiBold"
                       Foreground="#F0F1F2" TextTrimming="CharacterEllipsis"/>
        </Grid>
    </Border>
</Window>
'@

$window = [System.Windows.Markup.XamlReader]::Parse($xaml)
$card = $window.FindName('Card')
$englishLabel = $window.FindName('EnglishLabel')
$easyLabel = $window.FindName('EasyLabel')
$translationLabel = $window.FindName('TranslationLabel')
$nextButton = $window.FindName('NextButton')
$hideButton = $window.FindName('HideButton')

$workingArea = [System.Windows.SystemParameters]::WorkArea
$left = $workingArea.Right - $window.Width - 16
$top = $workingArea.Top + ($workingArea.Height - $window.Height) / 2
if ($saved -and $null -ne $saved.Left -and $null -ne $saved.Top) {
    $virtualLeft = [System.Windows.SystemParameters]::VirtualScreenLeft
    $virtualTop = [System.Windows.SystemParameters]::VirtualScreenTop
    $virtualRight = $virtualLeft + [System.Windows.SystemParameters]::VirtualScreenWidth
    $virtualBottom = $virtualTop + [System.Windows.SystemParameters]::VirtualScreenHeight
    if ([double]$saved.Left -ge $virtualLeft -and [double]$saved.Top -ge $virtualTop -and
        [double]$saved.Left + 100 -le $virtualRight -and [double]$saved.Top + 80 -le $virtualBottom) {
        $left = [double]$saved.Left
        $top = [double]$saved.Top
    }
}
$window.Left = $left
$window.Top = $top

$menu = [System.Windows.Forms.ContextMenuStrip]::new()
$showItem = $menu.Items.Add('Показать')
$showItem.Add_Click({ $window.Show(); $window.Activate() })
$nextItem = $menu.Items.Add('Следующее слово')
$nextItem.Add_Click({ Show-NextWord })
$editItem = $menu.Items.Add('Редактировать слова')
$editItem.Add_Click({ Start-Process notepad.exe -ArgumentList ('"{0}"' -f $script:wordsPath) })
$reloadItem = $menu.Items.Add('Обновить слова')
$reloadItem.Add_Click({ $script:lastModified = [datetime]::MinValue; Show-NextWord })
$intervalMenu = [System.Windows.Forms.ToolStripMenuItem]::new('Интервал')
foreach ($choice in @(
    @{ Label = '15 секунд'; Seconds = 15 },
    @{ Label = '30 секунд'; Seconds = 30 },
    @{ Label = '1 минута'; Seconds = 60 },
    @{ Label = '2 минуты'; Seconds = 120 },
    @{ Label = '5 минут'; Seconds = 300 }
)) {
    $item = [System.Windows.Forms.ToolStripMenuItem]::new($choice.Label)
    $item.Tag = $choice.Seconds
    $item.Checked = $choice.Seconds -eq $script:intervalSeconds
    $item.Add_Click({
        param($sender, $event)
        $script:intervalSeconds = [int]$sender.Tag
        foreach ($option in $intervalMenu.DropDownItems) { $option.Checked = $option -eq $sender }
        $timer.Interval = [timespan]::FromSeconds($script:intervalSeconds)
        Save-Settings
    })
    [void]$intervalMenu.DropDownItems.Add($item)
}
[void]$menu.Items.Add($intervalMenu)
[void]$menu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new())
$exitItem = $menu.Items.Add('Выход')
$exitItem.Add_Click({ $window.Close() })

$script:tray = [System.Windows.Forms.NotifyIcon]::new()
$script:tray.Icon = [System.Drawing.SystemIcons]::Application
$script:tray.Text = 'Word Widget'
$script:tray.ContextMenuStrip = $menu
$script:tray.Visible = $true
$script:tray.Add_DoubleClick({ $window.Show(); $window.Activate() })

$card.Add_MouseLeftButtonDown({ $window.DragMove(); Save-Settings })
$card.Add_MouseRightButtonUp({
    param($sender, $event)
    $menu.Show([System.Windows.Forms.Cursor]::Position)
    $event.Handled = $true
})
$nextButton.Add_Click({ Show-NextWord })
$hideButton.Add_Click({ Save-Settings; $window.Hide() })
$window.Add_Closed({ Save-Settings })

$timer = [System.Windows.Threading.DispatcherTimer]::new()
$timer.Interval = [timespan]::FromSeconds($script:intervalSeconds)
$timer.Add_Tick({ Show-NextWord })
Show-NextWord
$timer.Start()

if ($SmokeTest) {
    if ($script:words.Count -eq 0) { throw 'No valid words were loaded.' }
    if ($script:words.Count -gt 1) {
        $seen = [System.Collections.Generic.HashSet[int]]::new()
        [void]$seen.Add($script:lastIndex)
        for ($index = 1; $index -lt $script:words.Count; $index++) {
            Show-NextWord
            if (-not $seen.Add($script:lastIndex)) { throw 'A word repeated before the full list was shown.' }
        }
        $previousIndex = $script:lastIndex
        Show-NextWord
        if ($script:lastIndex -eq $previousIndex) { throw 'A word repeated across shuffled rounds.' }
    }
    $smokeTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $smokeTimer.Interval = [timespan]::FromMilliseconds(500)
    $smokeTimer.Add_Tick({ $smokeTimer.Stop(); $window.Close() })
    $smokeTimer.Start()
}

$app = [System.Windows.Application]::new()
$app.ShutdownMode = [System.Windows.ShutdownMode]::OnMainWindowClose
try {
    [void]$app.Run($window)
    if ($SmokeTest) { Write-Output ('Opened widget with {0} words.' -f $script:words.Count) }
} finally {
    $timer.Stop()
    $script:tray.Visible = $false
    $script:tray.Dispose()
    $menu.Dispose()
    $instanceMutex.ReleaseMutex()
    $instanceMutex.Dispose()
}