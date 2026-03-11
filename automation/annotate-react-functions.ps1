param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$TargetRoot = 'src/main/frontend/src'
)

$ErrorActionPreference = 'Stop'

function Decode-JsonUnicode([string]$escaped) {
  return (ConvertFrom-Json ('"' + $escaped + '"'))
}

$PhraseLegacy = Decode-JsonUnicode '\ub9c8\uc774\uadf8\ub808\uc774\uc158\ub41c React \ud750\ub984\uc744 \ucc98\ub9ac\ud569\ub2c8\ub2e4.'
$PhraseParse = Decode-JsonUnicode '\uc785\ub825 \ub370\uc774\ud130\ub97c \ud30c\uc2f1\ud569\ub2c8\ub2e4.'
$PhraseDecode = Decode-JsonUnicode '\uc778\ucf54\ub529\ub41c \uac12\uc744 \ub514\ucf54\ub529\ud569\ub2c8\ub2e4.'
$PhraseEncode = Decode-JsonUnicode '\uac12\uc744 \uc778\ucf54\ub529\ud569\ub2c8\ub2e4.'
$PhraseRead = Decode-JsonUnicode '\ud544\uc694\ud55c \ub370\uc774\ud130\ub97c \uc870\ud68c\ud569\ub2c8\ub2e4.'
$PhraseMap = Decode-JsonUnicode '\ud45c\uc2dc/\ucc98\ub9ac\uc6a9 \ub370\uc774\ud130 \ud615\ud0dc\ub85c \ubcc0\ud658\ud569\ub2c8\ub2e4.'
$PhraseBuild = Decode-JsonUnicode '\uc694\uccad/\ud45c\uc2dc\uc6a9 \ub370\uc774\ud130\ub97c \uc0dd\uc131\ud569\ub2c8\ub2e4.'
$PhraseUiControl = Decode-JsonUnicode '\ud654\uba74 \uc0c1\ud0dc \ub610\ub294 \ud31d\uc5c5 \ub3d9\uc791\uc744 \uc81c\uc5b4\ud569\ub2c8\ub2e4.'
$PhraseEvent = Decode-JsonUnicode '\uc0ac\uc6a9\uc790 \uc774\ubca4\ud2b8\ub97c \ucc98\ub9ac\ud569\ub2c8\ub2e4.'
$PhraseState = Decode-JsonUnicode '\uc0c1\ud0dc\uac12\uc744 \uac31\uc2e0\ud558\uac70\ub098 \ubaa9\ub85d\uc744 \uc870\uc815\ud569\ub2c8\ub2e4.'
$PhraseCondition = Decode-JsonUnicode '\uc870\uac74 \ucda9\uc871 \uc5ec\ubd80\ub97c \ud310\ubcc4\ud569\ub2c8\ub2e4.'
$PhraseValidate = Decode-JsonUnicode '\uc2e4\ud589 \uc870\uac74 \ub610\ub294 \uc720\ud6a8\uc131\uc744 \uc810\uac80\ud569\ub2c8\ub2e4.'
$PhraseDefault = Decode-JsonUnicode '\ud574\ub2f9 \ud654\uba74\uc758 \ud575\uc2ec \ub85c\uc9c1\uc744 \uc218\ud589\ud569\ub2c8\ub2e4.'

$resolvedTargetRoot = Join-Path $ProjectRoot $TargetRoot
if (-not (Test-Path $resolvedTargetRoot)) {
  throw "Target root not found: $resolvedTargetRoot"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$files = Get-ChildItem -Path $resolvedTargetRoot -Recurse -File -Include *.js |
  Where-Object { $_.FullName -notmatch '\\node_modules\\|\\build\\|\\dist\\|\.min\.js$|\.bak(\.|$)' }

$totalFilesChanged = 0
$totalCommentsAdded = 0

function Has-FunctionComment([string[]]$lines, [int]$index) {
  for ($i = $index - 1; $i -ge 0; $i--) {
    $candidate = $lines[$i]
    if ($null -eq $candidate) { continue }
    $trim = $candidate.Trim()
    if ($trim -eq '') { continue }
    if ($trim.StartsWith('//') -or $trim.StartsWith('/*') -or $trim.StartsWith('*')) {
      return $true
    }
    return $false
  }
  return $false
}

function Is-GeneratedComment([string]$line) {
  if ($null -eq $line) { return $false }
  $trim = $line.Trim()
  if ($trim -notmatch '^//\s*[A-Za-z_][A-Za-z0-9_]*:\s+(.+)$') { return $false }
  $suffix = $matches[1].Trim()
  if ($suffix -eq 'handles migrated React flow logic.') { return $true }
  if ($suffix -eq $PhraseLegacy) { return $true }
  if ($suffix -in @(
      $PhraseParse, $PhraseDecode, $PhraseEncode, $PhraseRead, $PhraseMap,
      $PhraseBuild, $PhraseUiControl, $PhraseEvent, $PhraseState, $PhraseCondition,
      $PhraseValidate, $PhraseDefault
    )) { return $true }
  # Remove old mojibake comments that still include React keyword.
  if ($suffix -match 'React') { return $true }
  return $false
}

function Get-TopLevelFunctionName([string]$line, [int]$braceDepth) {
  if ($braceDepth -ne 0) { return $null }
  if ($line -match '^\s+') { return $null }

  if ($line -match '^(?:export\s+)?function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(') {
    return $matches[1]
  }
  if ($line -match '^(?:export\s+)?const\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:async\s+)?\([^)]*\)\s*=>') {
    return $matches[1]
  }
  if ($line -match '^(?:export\s+)?const\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:async\s+)?function\s*\(') {
    return $matches[1]
  }
  return $null
}

function Get-CommentSuffix([string]$funcName) {
  $lower = [string]$funcName
  $lower = $lower.ToLowerInvariant()

  if ($lower -match '^parse') { return $PhraseParse }
  if ($lower -match '^decode') { return $PhraseDecode }
  if ($lower -match '^encode') { return $PhraseEncode }
  if ($lower -match '^(load|fetch|get|select)') { return $PhraseRead }
  if ($lower -match '^(map|normalize|format|to)') { return $PhraseMap }
  if ($lower -match '^(build|create)') { return $PhraseBuild }
  if ($lower -match '^(open|close|toggle)') { return $PhraseUiControl }
  if ($lower -match '^(onclick|onsubmit|onchange|onsearch|onprocess|oncreate|on|handle)') { return $PhraseEvent }
  if ($lower -match '^(set|update|apply|move|remove|add)') { return $PhraseState }
  if ($lower -match '^(is|has|can|should)') { return $PhraseCondition }
  if ($lower -match '^(wait|check|verify|validate)') { return $PhraseValidate }
  return $PhraseDefault
}

foreach ($file in $files) {
  $original = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
  $newline = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
  $lines = $original -split "`r?`n"
  $output = New-Object System.Collections.Generic.List[string]
  $addedInFile = 0
  $braceDepth = 0

  foreach ($line in $lines) {
    if (Is-GeneratedComment -line $line) {
      continue
    }

    $funcName = Get-TopLevelFunctionName -line $line -braceDepth $braceDepth
    if ($funcName) {
      $indexBeforeInsert = $output.Count
      if (-not (Has-FunctionComment -lines $output.ToArray() -index $indexBeforeInsert)) {
        $commentSuffix = Get-CommentSuffix -funcName $funcName
        $output.Add("// ${funcName}: $commentSuffix")
        $addedInFile += 1
      }
    }

    $output.Add($line)

    $openCount = ([regex]::Matches($line, '\{')).Count
    $closeCount = ([regex]::Matches($line, '\}')).Count
    $braceDepth += ($openCount - $closeCount)
    if ($braceDepth -lt 0) {
      $braceDepth = 0
    }
  }

  $rewritten = [string]::Join($newline, $output)
  if ($original.EndsWith("`n")) {
    $rewritten = $rewritten + $newline
  }

  if ($rewritten -ne $original) {
    [System.IO.File]::WriteAllText($file.FullName, $rewritten, $utf8NoBom)
    $totalFilesChanged += 1
    $totalCommentsAdded += $addedInFile
  }
}

Write-Host "ANNOTATE_FILES_CHANGED=$totalFilesChanged"
Write-Host "ANNOTATE_COMMENTS_ADDED=$totalCommentsAdded"
