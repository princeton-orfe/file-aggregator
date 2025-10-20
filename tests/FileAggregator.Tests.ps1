# Requires Pester
Describe "File Aggregator basic behavior" {
    BeforeAll {
        $tempRoot = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ("FileAggTest_" + ([guid]::NewGuid().ToString()))
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        $src = Join-Path $tempRoot 'src'
        $dest = Join-Path $tempRoot 'dest'
        New-Item -ItemType Directory -Path $src -Force | Out-Null
        New-Item -ItemType Directory -Path $dest -Force | Out-Null

        # create test files
        Set-Content -Path (Join-Path $src 'a.txt') -Value 'hello'
        Set-Content -Path (Join-Path $src 'b.log') -Value 'log'
        Set-Content -Path (Join-Path $src 'image.jpg') -Value ''

    # Leave script resolution to each test to avoid Pester discovery-time issues
    $global:scriptPath = $null
        $global:src = $src
        $global:dest = $dest
    }

    AfterAll {
        Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "reports txt files to CSV including LastAccessTime" {
    # locate script from repo root (current working directory) to avoid discovery-time variables
    $scriptFile = Get-ChildItem -Path (Get-Location).Path -Filter 'file-aggregator.ps1' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    $scriptFile | Should -Not -BeNullOrEmpty
    $reportPath = Join-Path $tempRoot 'report.csv'
    pwsh -File $scriptFile.FullName -SearchBase $global:src -Report -ReportPath $reportPath -FileTypes txt
        Test-Path $reportPath | Should -BeTrue
        $csv = Import-Csv -Path $reportPath
        $csv.Count | Should -Be 1
        $csv[0].Name | Should -Be 'a.txt'
        try {
            [datetime]::Parse($csv[0].LastAccessTime) | Out-Null
            $true | Should -BeTrue
        } catch {
            Throw "LastAccessTime is not a valid datetime: $($_)"
        }
    }

    It "dry-run copy shows would copy line for txt files" {
    $scriptFile = Get-ChildItem -Path (Get-Location).Path -Filter 'file-aggregator.ps1' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    $scriptFile | Should -Not -BeNullOrEmpty
    $output = pwsh -File $scriptFile.FullName -SearchBase $global:src -TargetFolder $global:dest -FileTypes txt -DryRun
        $output -match 'Dry Run: Would copy' | Should -BeTrue
    }

    It "-NoImageDimensionFilter includes image files when searching images" {
        $scriptFile = Get-ChildItem -Path (Get-Location).Path -Filter 'file-aggregator.ps1' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        $scriptFile | Should -Not -BeNullOrEmpty
        $output = pwsh -File $scriptFile.FullName -SearchBase $global:src -TargetFolder $global:dest -FileTypes jpg -DryRun -NoImageDimensionFilter
        # Should include image.jpg now
        $output -match 'image.jpg' | Should -BeTrue
    }

    It "-NoImageDimensionFilter does not affect non-image file types" {
        $scriptFile = Get-ChildItem -Path (Get-Location).Path -Filter 'file-aggregator.ps1' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        $scriptFile | Should -Not -BeNullOrEmpty
        $output1 = pwsh -File $scriptFile.FullName -SearchBase $global:src -TargetFolder $global:dest -FileTypes txt -DryRun
        $output2 = pwsh -File $scriptFile.FullName -SearchBase $global:src -TargetFolder $global:dest -FileTypes txt -DryRun -NoImageDimensionFilter
        $output1 | Should -Be $output2
    }
}
