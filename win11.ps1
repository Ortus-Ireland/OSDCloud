### Ekco MSP - OSDCloud Image Selection ###
### Reads enabled devices from imageStaging.json via IIS ###

$wdsHost = "wds"
try {
    $serverCfg = Invoke-WebRequest -Uri "http://wds/imageStaging/wdsServer.json" -UseBasicParsing -ErrorAction Stop
    $raw = $serverCfg.Content.Trim()
    if ($raw[0] -eq [char]0xFEFF) { $raw = $raw.Substring(1) }
    $srv = $raw | ConvertFrom-Json
    if ($srv.hostname) { $wdsHost = $srv.hostname }
} catch { }

$configUrl = "http://$wdsHost/imageStaging/imageStaging.json"
$Index = 1

function Get-EsdUrl([string]$Name) {
    if ($Name -match '^Win\d') { return "http://$wdsHost/esd/$Name.esd" }
    return "http://$wdsHost/esd/Win11_$Name.esd"
}

function ConvertTo-DeviceDate([string]$DateStr) {
    if ([string]::IsNullOrWhiteSpace($DateStr)) { return $null }
    foreach ($fmt in @('dd-MM-yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd')) {
        try { return [datetime]::ParseExact($DateStr, $fmt, $null) } catch { }
    }
    return $null
}

Write-Host -ForegroundColor Yellow "Fetching device config from $configUrl ..."
$devices = @()
try {
    $response = Invoke-WebRequest -Uri $configUrl -UseBasicParsing -ErrorAction Stop
    $raw = $response.Content
    if ($raw[0] -eq [char]0xFEFF) { $raw = $raw.Substring(1) }
    if ($raw.StartsWith([string][char]0xEF + [char]0xBB + [char]0xBF)) { $raw = $raw.Substring(3) }
    $raw = $raw.Trim()
    $config = $raw | ConvertFrom-Json
    $devices = @($config.devices | Where-Object { $_.enabled -eq $true -or $_.enabled -eq 'true' -or $_.enabled -eq 'True' })
    Write-Host -ForegroundColor Green "Loaded $($devices.Count) enabled device(s)."
} catch {
    Write-Host -ForegroundColor Red "Could not fetch device config: $_"
    Write-Host ""
    $manual = Read-Host "Enter ESD URL manually (or press Enter to exit)"
    if ([string]::IsNullOrWhiteSpace($manual)) { exit }
    $CustomImageFile = $manual
}

function Get-DeviceMfg($dev) {
    if ($dev.manufacturer) { return $dev.manufacturer }
    return "Other"
}

$randomName = (65..90 | ForEach-Object { [char][byte]$_ } | Get-Random -Count 10) -join ""

$guiSuccess = $false
$script:devices = $devices

if ($devices.Count -gt 0) {
    $manufacturers = @($devices | ForEach-Object { Get-DeviceMfg $_ } | Select-Object -Unique | Sort-Object)

    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        Add-Type -AssemblyName PresentationCore -ErrorAction Stop
        Add-Type -AssemblyName WindowsBase -ErrorAction Stop

        [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ekco MSP - Image Selection" Height="620" Width="560"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1e1e2e">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="b" Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="b" Property="Opacity" Value="0.82"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="b" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <ControlTemplate x:Key="ComboToggle" TargetType="ToggleButton">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition/>
                    <ColumnDefinition Width="32"/>
                </Grid.ColumnDefinitions>
                <Border x:Name="bg" Grid.ColumnSpan="2" Background="#313244" BorderBrush="#45475a"
                        BorderThickness="1" CornerRadius="6"/>
                <Path x:Name="arrow" Grid.Column="1" Data="M0,0 L5,5 10,0" Stroke="#cdd6f4" StrokeThickness="1.5"
                      HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Grid>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="bg" Property="BorderBrush" Value="#585b70"/>
                </Trigger>
                <Trigger Property="IsChecked" Value="True">
                    <Setter TargetName="bg" Property="BorderBrush" Value="#89b4fa"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="#cdd6f4"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Template="{StaticResource ComboToggle}"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                                          Focusable="False" ClickMode="Press"/>
                            <ContentPresenter IsHitTestVisible="False" Margin="14,10,32,10"
                                              Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              VerticalAlignment="Center"/>
                            <Popup IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom"
                                   AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                                <Border Background="#313244" BorderBrush="#45475a" BorderThickness="1"
                                        CornerRadius="6" Margin="0,2,0,0" Padding="0,4"
                                        MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource AncestorType=ComboBox}}">
                                    <ScrollViewer MaxHeight="220" VerticalScrollBarVisibility="Auto">
                                        <StackPanel IsItemsHost="True"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="#cdd6f4"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#45475a"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#45475a"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ListBoxItem">
            <Setter Property="Foreground" Value="#cdd6f4"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="Margin" Value="0,1"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListBoxItem">
                        <Border x:Name="bd" Background="#1e1e2e" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#313244"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#89b4fa"/>
                                <Setter TargetName="bd" Property="BorderThickness" Value="1"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#262637"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="DarkThumb" TargetType="Thumb">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border x:Name="tb" Background="#45475a" CornerRadius="4"/>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="tb" Property="Background" Value="#585b70"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Border Background="#11111b" CornerRadius="4">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource DarkThumb}"/>
                                </Track.Thumb>
                            </Track>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="28,24,28,20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="Ekco MSP - Image Selection"
                       Foreground="#89b4fa" FontSize="20" FontWeight="Bold" VerticalAlignment="Center"/>
            <Button Name="RefreshBtn" Content="&#x21BB; Refresh" HorizontalAlignment="Right"
                    Padding="12,6" FontSize="12"
                    Background="#45475a" Foreground="#cdd6f4" Cursor="Hand"/>
        </Grid>

        <TextBlock Grid.Row="1" Text="Manufacturer" Foreground="#a6adc8" FontSize="12" Margin="0,0,0,6"/>
        <ComboBox Name="MfgCombo" Grid.Row="2" Margin="0,0,0,14"/>

        <ListBox Name="DeviceList" Grid.Row="3" Background="#11111b" BorderBrush="#313244"
                 BorderThickness="1" Padding="4"
                 ScrollViewer.HorizontalScrollBarVisibility="Disabled"/>

        <Grid Grid.Row="4" Margin="0,14,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="Computer Name" Foreground="#a6adc8" FontSize="12"
                       VerticalAlignment="Center" Margin="0,0,12,0"/>
            <TextBox Name="CompNameBox" Grid.Column="1" FontSize="14" Padding="10,8"
                     Background="#313244" Foreground="#cdd6f4" BorderBrush="#45475a"
                     CaretBrush="#cdd6f4" CharacterCasing="Upper" MaxLength="15"/>
        </Grid>

        <TextBlock Name="SummaryText" Grid.Row="5" Foreground="#585b70" FontSize="11"
                   Margin="0,10,0,0" TextWrapping="Wrap"/>

        <Button Name="SelectBtn" Grid.Row="6" Content="Select Image and Continue"
                Height="44" Margin="0,14,0,0" FontSize="15" FontWeight="SemiBold"
                Background="#a6e3a1" Foreground="#1e1e2e" Cursor="Hand" IsEnabled="False"/>
    </Grid>
</Window>
"@

        $reader = New-Object System.Xml.XmlNodeReader $xaml
        $win = [Windows.Markup.XamlReader]::Load($reader)

        $mfgCombo    = $win.FindName("MfgCombo")
        $deviceList  = $win.FindName("DeviceList")
        $compNameBox = $win.FindName("CompNameBox")
        $summaryText = $win.FindName("SummaryText")
        $selectBtn   = $win.FindName("SelectBtn")
        $refreshBtn  = $win.FindName("RefreshBtn")

        foreach ($m in $manufacturers) { $mfgCombo.Items.Add($m) | Out-Null }

        $compNameBox.Text = $randomName

        $script:guiDevices = @()
        $script:guiChosen  = $null
        $script:guiCompName = ""

        $updateSelectBtn = {
            $devOk  = ($deviceList.SelectedIndex -ge 0)
            $nameOk = ($compNameBox.Text.Trim().Length -gt 0)
            $selectBtn.IsEnabled = ($devOk -and $nameOk)
        }

        $mfgCombo.Add_SelectionChanged({
            $deviceList.Items.Clear()
            $selMfg = $mfgCombo.SelectedItem
            if ($null -eq $selMfg) { return }

            $script:guiDevices = @($script:devices | Where-Object { (Get-DeviceMfg $_) -eq $selMfg })

            foreach ($d in $script:guiDevices) {
                $model = $d.name
                if ($d.model) { $model = $d.model }
                elseif ($d.friendlyName) { $model = $d.friendlyName }

                $imgVer = "--"
                if ($d.imageVersion) { $imgVer = $d.imageVersion }
                $drvDate = "--"
                if ($d.captureDate -and $d.captureDate -ne '') { $drvDate = $d.captureDate }

                $drvBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#a6e3a1")
                if ($drvDate -eq "--") {
                    $drvBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#585b70")
                } else {
                    $parsed = ConvertTo-DeviceDate $d.captureDate
                    if ($null -eq $parsed) {
                        $drvBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#f9e2af")
                    } elseif (((Get-Date) - $parsed).TotalDays -gt 90) {
                        $drvBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#f38ba8")
                    }
                }

                $sp = New-Object System.Windows.Controls.StackPanel
                $sp.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)

                $modelTb = New-Object System.Windows.Controls.TextBlock
                $modelTb.Text = $model
                $modelTb.FontSize = 14
                $modelTb.FontWeight = [System.Windows.FontWeights]::SemiBold
                $modelTb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#cdd6f4")
                $sp.Children.Add($modelTb) | Out-Null

                $detailSp = New-Object System.Windows.Controls.StackPanel
                $detailSp.Orientation = [System.Windows.Controls.Orientation]::Horizontal
                $detailSp.Margin = [System.Windows.Thickness]::new(0, 3, 0, 0)

                $imgLabel = New-Object System.Windows.Controls.TextBlock
                $imgLabel.Text = "Image: "
                $imgLabel.FontSize = 11
                $imgLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#585b70")
                $detailSp.Children.Add($imgLabel) | Out-Null

                $imgVal = New-Object System.Windows.Controls.TextBlock
                $imgVal.Text = $imgVer
                $imgVal.FontSize = 11
                $imgVal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#89b4fa")
                $imgVal.Margin = [System.Windows.Thickness]::new(0, 0, 16, 0)
                $detailSp.Children.Add($imgVal) | Out-Null

                $drvLabel = New-Object System.Windows.Controls.TextBlock
                $drvLabel.Text = "Drivers: "
                $drvLabel.FontSize = 11
                $drvLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#585b70")
                $detailSp.Children.Add($drvLabel) | Out-Null

                $drvVal = New-Object System.Windows.Controls.TextBlock
                $drvVal.Text = $drvDate
                $drvVal.FontSize = 11
                $drvVal.Foreground = $drvBrush
                $detailSp.Children.Add($drvVal) | Out-Null

                $sp.Children.Add($detailSp) | Out-Null

                $deviceList.Items.Add($sp) | Out-Null
            }

            & $updateSelectBtn
        })

        $deviceList.Add_SelectionChanged({
            $idx = $deviceList.SelectedIndex
            if ($idx -ge 0 -and $idx -lt $script:guiDevices.Count) {
                $d = $script:guiDevices[$idx]
                $summaryText.Text = "ESD: $(Get-EsdUrl $d.name)"
            } else {
                $summaryText.Text = ""
            }
            & $updateSelectBtn
        })

        $compNameBox.Add_TextChanged({ & $updateSelectBtn })

        $selectBtn.Add_Click({
            $idx = $deviceList.SelectedIndex
            if ($idx -ge 0 -and $idx -lt $script:guiDevices.Count) {
                $script:guiChosen = $script:guiDevices[$idx]
                $script:guiCompName = $compNameBox.Text.Trim()
                $win.DialogResult = $true
            }
        })

        $refreshBtn.Add_Click({
            $refreshBtn.IsEnabled = $false
            $refreshBtn.Content = "Refreshing..."
            try {
                $resp = Invoke-WebRequest -Uri $configUrl -UseBasicParsing -ErrorAction Stop
                $rawJson = $resp.Content
                if ($rawJson[0] -eq [char]0xFEFF) { $rawJson = $rawJson.Substring(1) }
                if ($rawJson.StartsWith([string][char]0xEF + [char]0xBB + [char]0xBF)) { $rawJson = $rawJson.Substring(3) }
                $rawJson = $rawJson.Trim()
                $cfg = $rawJson | ConvertFrom-Json

                $script:devices = @($cfg.devices | Where-Object { $_.enabled -eq $true -or $_.enabled -eq 'true' -or $_.enabled -eq 'True' })
                $newMfgs = @()
                foreach ($d in $script:devices) {
                    $m = Get-DeviceMfg $d
                    if ($m -and $newMfgs -notcontains $m) { $newMfgs += $m }
                }
                $newMfgs = @($newMfgs | Sort-Object)

                $previousMfg = $mfgCombo.SelectedItem
                $mfgCombo.Items.Clear()
                foreach ($m in $newMfgs) { $mfgCombo.Items.Add($m) | Out-Null }

                if ($previousMfg -and $newMfgs -contains $previousMfg) {
                    $mfgCombo.SelectedItem = $previousMfg
                } elseif ($newMfgs.Count -eq 1) {
                    $mfgCombo.SelectedIndex = 0
                }

                $summaryText.Text = "Refreshed — $($script:devices.Count) enabled device(s) loaded."
            } catch {
                $summaryText.Text = "Refresh failed: $_"
            }
            $refreshBtn.Content = "$([char]0x21BB) Refresh"
            $refreshBtn.IsEnabled = $true
        })

        if ($manufacturers.Count -eq 1) { $mfgCombo.SelectedIndex = 0 }

        $win.Add_ContentRendered({ $mfgCombo.Focus() })
        $result = $win.ShowDialog()

        if ($result -eq $true -and $null -ne $script:guiChosen) {
            $chosenName = $script:guiChosen.name
            if ($script:guiChosen.friendlyName) { $chosenName = $script:guiChosen.friendlyName }
            $CustomImageFile = Get-EsdUrl $script:guiChosen.name
            $ComputerName = $script:guiCompName
            $guiSuccess = $true
            Write-Host ""
            Write-Host -ForegroundColor Green "Selected: $chosenName"
            Write-Host -ForegroundColor Green "ESD:      $CustomImageFile"
            Write-Host -ForegroundColor Green "Name:     $ComputerName"
        }

    } catch {
        Write-Host -ForegroundColor Yellow "GUI unavailable ($_), falling back to console menu..."
    }

    if (-not $guiSuccess) {
        $chosen = $null
        while ($null -eq $chosen) {
            Clear-Host
            Write-Host "==================== Ekco MSP - Image Selection ====================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host " Select a manufacturer:" -ForegroundColor DarkGray
            Write-Host (" " + ("-" * 40)) -ForegroundColor DarkGray
            for ($i = 0; $i -lt $manufacturers.Count; $i++) {
                $mfg = $manufacturers[$i]
                $count = @($script:devices | Where-Object { (Get-DeviceMfg $_) -eq $mfg }).Count
                $suffix = "s"
                if ($count -eq 1) { $suffix = "" }
                Write-Host (" {0,3}  {1}  " -f ($i + 1), $mfg) -NoNewline -ForegroundColor White
                Write-Host "($count device$suffix)" -ForegroundColor DarkGray
            }
            Write-Host ""

            $mfgSel = Read-Host "Select manufacturer (1-$($manufacturers.Count))"
            $mfgNum = 0
            if (-not ([int]::TryParse($mfgSel, [ref]$mfgNum)) -or $mfgNum -lt 1 -or $mfgNum -gt $manufacturers.Count) {
                Write-Host -ForegroundColor Red "Invalid selection, try again."
                Start-Sleep -Seconds 1
                continue
            }

            $selMfg = $manufacturers[$mfgNum - 1]
            $mfgDevices = @($script:devices | Where-Object { (Get-DeviceMfg $_) -eq $selMfg })

            $pickingDevice = $true
            while ($pickingDevice) {
                Clear-Host
                Write-Host "==================== Ekco MSP - Image Selection ====================" -ForegroundColor Cyan
                Write-Host ""
                Write-Host " $selMfg devices:" -ForegroundColor Cyan
                Write-Host (" {0,3}  {1,-38} {2,-18} {3}" -f "#", "Model", "Image Version", "Drivers") -ForegroundColor DarkGray
                Write-Host (" " + ("-" * 80)) -ForegroundColor DarkGray
                for ($j = 0; $j -lt $mfgDevices.Count; $j++) {
                    $d = $mfgDevices[$j]
                    $dName = $d.name
                    if ($d.model) { $dName = $d.model }
                    elseif ($d.friendlyName) { $dName = $d.friendlyName }
                    $img = "--"
                    if ($d.imageVersion) { $img = $d.imageVersion }
                    $drv = "--"
                    if ($d.captureDate -and $d.captureDate -ne '') { $drv = $d.captureDate }
                    $drvColor = "Green"
                    if ($drv -eq "--") { $drvColor = "DarkGray" }
                    else {
                        $parsed = ConvertTo-DeviceDate $d.captureDate
                        if ($null -eq $parsed) { $drvColor = "Yellow" }
                        elseif (((Get-Date) - $parsed).TotalDays -gt 90) { $drvColor = "Red" }
                    }
                    Write-Host (" {0,3}  " -f ($j + 1)) -NoNewline -ForegroundColor White
                    Write-Host ("{0,-38} " -f $dName) -NoNewline
                    Write-Host ("{0,-18} " -f $img) -NoNewline -ForegroundColor Cyan
                    Write-Host $drv -ForegroundColor $drvColor
                }
                Write-Host ""
                Write-Host "   B  " -NoNewline -ForegroundColor Yellow
                Write-Host "Back to manufacturers" -ForegroundColor DarkGray
                Write-Host ""

                $devSel = Read-Host "Select a device (1-$($mfgDevices.Count)) or B to go back"
                if ($devSel -eq 'b' -or $devSel -eq 'B') {
                    $pickingDevice = $false
                    continue
                }
                $devNum = 0
                if ([int]::TryParse($devSel, [ref]$devNum) -and $devNum -ge 1 -and $devNum -le $mfgDevices.Count) {
                    $chosen = $mfgDevices[$devNum - 1]
                    $pickingDevice = $false
                } else {
                    Write-Host -ForegroundColor Red "Invalid selection, try again."
                    Start-Sleep -Seconds 1
                }
            }
        }

        $chosenName = $chosen.name
        if ($chosen.friendlyName) { $chosenName = $chosen.friendlyName }
        $CustomImageFile = Get-EsdUrl $chosen.name
        Write-Host ""
        Write-Host -ForegroundColor Green "Selected: $chosenName"
        Write-Host -ForegroundColor Green "ESD:      $CustomImageFile"

        $ComputerName = Read-Host "Enter computer name (default: $randomName)"
        if ([string]::IsNullOrWhiteSpace($ComputerName)) { $ComputerName = $randomName }
    }
}

if ([string]::IsNullOrWhiteSpace($CustomImageFile)) {
    Write-Host ""
    Write-Host -ForegroundColor Red "========================================="
    Write-Host -ForegroundColor Red " ERROR: No image was selected!"
    Write-Host -ForegroundColor Red "========================================="
    Write-Host -ForegroundColor Yellow "Devices found: $($script:devices.Count)"
    Write-Host -ForegroundColor Yellow "Config URL: $configUrl"
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

Write-Host ""
Write-Host -ForegroundColor Green "Image URL: $CustomImageFile"
Write-Host ""
Write-Host "Computer will be renamed to $ComputerName once complete"
Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"

Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine

if ((Get-MyComputerModel) -match 'Virtual') {

Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"

Set-DisRes 1600

}

#Make sure I have the latest OSD Content

#Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"

#Install-Module OSD -RequiredVersion 22.5.10.1 -Force #Get specific version
#Install-Module OSD -Force

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"

#Import-Module OSD -RequiredVersion 22.5.10.1 -Force #Import specific version
Import-Module OSD

######################
# Build variables
######################
    #=======================================================================
    # Create Hashtable
    #=======================================================================
    $Global:StartOSDCloud = $null
    $Global:StartOSDCloud = [ordered]@{
        DriverPackUrl = $null
        DriverPackName = "None"
        DriverPackOffline = $null
        DriverPackSource = $null
        Function = $MyInvocation.MyCommand.Name
        GetDiskFixed = $null
        GetFeatureUpdate = $null
        GetMyDriverPack = $null
        ImageFileOffline = $null
        ImageFileName = $null
        ImageFileSource = $null
        ImageFileTarget = $null
        ImageFileUrl = $CustomImageFile
        IsOnBattery = Get-OSDGather -Property IsOnBattery
        Manufacturer = $Manufacturer
        OSBuild = $OSBuild
        OSBuildMenu = $null
        OSBuildNames = $null
        OSEdition = $OSEdition
        OSEditionId = $null
        OSEditionMenu = $null
        OSEditionNames = $null
        OSLanguage = $OSLanguage
        OSLanguageMenu = $null
        OSLanguageNames = $null
        OSLicense = $null
        OSImageIndex = $Index
        Product = "none"
        Screenshot = $null
        SkipAutopilot = $SkipAutopilot
        SkipODT = $true
        TimeStart = Get-Date
        updateFirmware = $false
        ZTI = $true
    }


#Start OSDCloud ZTI the RIGHT way

Write-Host -ForegroundColor Green "Start OSDCloud"

#Start-OSDCloud -OSLanguage en-gb -OSBuild 21H2 -OSEdition Pro -ZTI -SkipAutopilot 
#Start-OSDCloud -ImageFileUrl $CustomImageFile -ImageIndex $Index -ZTI -firmware -SkipAutopilot -SkipODT
#Start-OSDCloud -ImageFileUrl $CustomImageFile -ImageIndex $Index -firmware -SkipAutopilot -SkipODT

Invoke-OSDCloud

#Restart from WinPE
Write-Host "Savings computer name to file"
Set-Content -Path "C:\osdcloud\computername.txt" -Value $ComputerName

# Output name to C:\temp
if (-not (Test-Path -Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp"
}
Set-Content -Path "C:\temp\computername.txt" -Value $ComputerName

Write-Host -ForegroundColor Green "Restarting in 20 seconds!"

Start-Sleep -Seconds 20

wpeutil reboot
