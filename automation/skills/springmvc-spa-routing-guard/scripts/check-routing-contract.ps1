param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$NoFail
)

$files = @{
  Dispatcher = Join-Path $ProjectRoot 'src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml'
  SpaController = Join-Path $ProjectRoot 'src/main/java/com/rays/app/web/SpaForwardController.java'
  ViewController = Join-Path $ProjectRoot 'src/main/java/com/rays/app/view/controller/ViewController.java'
}

$checks = @(
  @{ Name='dispatcher has /ui resources'; File='Dispatcher'; Pattern='<mvc:resources\s+mapping="/ui/\*\*"' },
  @{ Name='dispatcher has default servlet handler'; File='Dispatcher'; Pattern='<mvc:default-servlet-handler\s*/?>' },
  @{ Name='dispatcher /ui redirect view'; File='Dispatcher'; Pattern='path="/ui"\s+view-name="redirect:/ui/"' },
  @{ Name='dispatcher /ui/ forward view'; File='Dispatcher'; Pattern='path="/ui/"\s+view-name="forward:/ui/index\.html"' },
  @{ Name='spa controller includes /ui redirect'; File='SpaController'; Pattern='redirect:/ui/' },
  @{ Name='spa controller includes /ui index forward'; File='SpaController'; Pattern='forward:/ui/index\.html' },
  @{ Name='spa deep route mapping exists'; File='SpaController'; Pattern='/ui/\*\*' },
  @{ Name='legacy controller excludes ui path'; File='ViewController'; Pattern='\{path:\^\(\?!ui\$\)\.\+\}' }
)

$rows = foreach ($c in $checks) {
  $filePath = $files[$c.File]
  $exists = Test-Path $filePath
  $pass = $false
  if ($exists) {
    $pass = Select-String -Path $filePath -Pattern $c.Pattern -Quiet
  }
  [pscustomobject]@{
    Check = $c.Name
    File = $filePath
    Pass = $pass
  }
}

$rows | Format-Table -AutoSize

$failed = @($rows | Where-Object { -not $_.Pass })
if ($failed.Count -gt 0) {
  Write-Host "FAILED CHECKS: $($failed.Count)"
  if (-not $NoFail) { exit 1 }
}
