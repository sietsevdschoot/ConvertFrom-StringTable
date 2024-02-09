#Requires -PSEdition Core -Version 7

using namespace System.Collections.Generic
using namespace System.Text.RegularExpressions

# Fix diplaying special characters, for example '…' in 'docker ps -a' output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$columnFinderRegex = [Regex]::New("\S+(?:\s?\S+)*", [RegexOptions]::Compiled -bor [RegexOptions]::CultureInvariant)
$wordFinderRegex = [Regex]::New("[^\s]+", [RegexOptions]::Compiled -bor [RegexOptions]::CultureInvariant)

<#
.SYNOPSIS
    Converts a string table into objects.

.DESCRIPTION
    The ConvertFrom-StringTable function takes a formatted string table as input and converts it into PowerShell objects.
    The input string table is expected to have rows and columns, and each cell in the table is separated by specified
    column and table separators. The resulting objects can be used for further processing or analysis.

.PARAMETER Line
    Specifies the input string representing a single line of the formatted string table. This parameter is usually
    provided through pipeline input.

.PARAMETER TableSeparators
    Specifies the characters used to separate different columns in the string table. The default value is "-+| ".

.PARAMETER ColumnSeparators
    Specifies the characters used to separate the values within each column in the string table. The default value is "|".

.EXAMPLE

    $table = '

      Name | Age | City
      ------------------------
      John | 25  | New York
      Jane | 30  | Los Angeles
    '

    $table | ConvertFrom-StringTable

    This example converts the provided string table into PowerShell objects with properties 'Name', 'Age', and 'City'.

.EXAMPLE

    $table = '

      Product Quantity Price
      Laptop  2        $1200
      Phone   5        $500
    ' 
    
    $table = | ConvertFrom-StringTable

    This example demonstrates the conversion of a string table with properties 'Product', 'Quantity', and 'Price'.

.EXAMPLE

    $table = '

      Product ║ Quantity ║ Price
      ════════║══════════║══════
      Laptop  ║ 2        ║ $1200
      Phone   ║ 5        ║ $500
    '
    $table | ConvertFrom-StringTable -TableSeparators "═║═ " -ColumnSeparators "║"

    This example demonstrates the conversion of a string table with properties 'Product', 'Quantity', and 'Price'.

.EXAMPLE

    docker ps -a | ConverFrom-StringTable
    netstat -aon | ConverFrom-StringTable
  
    docker ps -a | convertFrom-StringTable | Format-Table
    docker ps -a | ConvertFrom-StringTable | ?{ $_.Status -like "*Running*" }

.NOTES
    File Name      : ConvertFrom-StringTable.psm1
    Author         : Sietse van der Schoot
    Prerequisite   : PowerShell Core 7
   
    Copyright 2023 - 2024. All rights reserved.
#>
Function ConvertFrom-StringTable {
  [CmdletBinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string] $Line,
    [string] $TableSeparators = "-+| ",
    [string] $ColumnSeparators = "|"
  )

  BEGIN {

    $lineEntries = [List[string]]::new()
  }

  PROCESS {

    $Line -split "`n" | ForEach-Object { $lineEntries.Add($_) }
  }

  END { 

    $headerAndRowLines = $lineEntries 
    | Get-LineEntry -TableSeparators $TableSeparators -ColumnSeparators $ColumnSeparators 
    | Search-HeaderAndRowsData
    
    $headers = $headerAndRowLines 
    | Select-Object -First 1 -exp Columns 
    | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase(($_.Trim().ToLower())) -replace "[^a-zA-Z0-9]" }

    $entities = $headerAndRowLines | Select-Object -Skip 1 | Build-Entity -Headers $headers

    $entities
  }
}

Function Get-LineEntry {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [string] $Line,
    [string] $TableSeparators,
    [string] $ColumnSeparators
  )

  BEGIN {

    $i = 0
    # Match empty lines and line separators
    $isLineSeparatorRegex = [Regex]::New("^$|^([$($TableSeparators.ToCharArray() -join "]|[")])+$")
    $columnSeparatorRegex = [Regex]::New("([$($ColumnSeparators.ToCharArray() -join "]|[")])")
  }

  PROCESS {

    $lineWithoutSeparators = $ColumnSeparatorRegex.Replace($Line, " ")
    $columnMatches = $columnFinderRegex.Matches($lineWithoutSeparators)
    
    [PsCustomObject]@{
      LineIndex             = $i
      Line                  = $Line;
      LineWithoutSeparators = $lineWithoutSeparators;
      ColumnMatches         = $columnMatches
      IsSeparatorLine       = $IsLineSeparatorRegex.IsMatch($Line.Trim())
      Columns               = $columnMatches | ForEach-Object { $_.Value };
    }

    $i++
  }
}

Function Search-HeaderAndRowsData {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [PsCustomObject] $LineEntry
  )

  BEGIN {

    $lineEntries = [List[PsCustomObject]]::new()
  }

  PROCESS {

    $lineEntries.Add($LineEntry)
  }

  END {

    $detectedColumnCount = $lineEntries 
    | Where-Object { !$_.IsSeparatorLine } 
    | ForEach-Object { $_.Columns.Count } 
    | Sort-Object -Desc 
    | Select-Object -First 1

    $rowEntries = $lineEntries | Where-Object { !$_.IsSeparatorLine -and $_.Columns.Count -eq $detectedColumnCount }
    $rowsWithDivergentColumnCount = $lineEntries | Where-Object { !$_.IsSeparatorLine -and $_.Columns.Count -ne $detectedColumnCount }  

    if ($rowsWithDivergentColumnCount) {

      $columnInfoEntries = $rowEntries | Get-ColumnWidthInformation -NrOfColumns $detectedColumnCount
      $fixedRowEntries = $rowsWithDivergentColumnCount | Get-CorrectedColumnsLineEntry -ColumnInfoEntries $columnInfoEntries

      $rowEntries = @($rowEntries) + @($fixedRowEntries) | Sort-Object -prop LineIndex
    }
    # Header is the first rowEntry which has detectedColumnCount
    $headerIndex = $rowEntries 
    | Where-Object { ($_.Columns | Where-Object{ $_ }).Count -eq $detectedColumnCount } 
    | Select-Object -First 1 -exp LineIndex

    $rowEntries = $rowEntries | Where-Object { $_.LineIndex -ge $headerIndex } 

    $rowEntries
  }
}

Function Get-ColumnWidthInformation {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [PsCustomObject] $LineEntry,
    [int] $NrOfColumns
  )

  BEGIN {

    $lineEntries = [List[PsCustomObject]]::new()
  }

  PROCESS {

    $lineEntries.Add($LineEntry)
  }

  END {

    for ($i = 0; $i -lt $nrOfColumns; $i++) {

      $columnMatches = $lineEntries | ForEach-Object { $_.ColumnMatches[$i] } 
      $indexes = $columnMatches | ForEach-Object { $_.Index, ($_.Index + $_.Length) } | ForEach-Object { $_ }

      $indexes | Measure-Object -Minimum -Maximum | Select-Object `
      @{ Name = "Index"; Expression = { $i } }, 
      @{ Name = "Begin"; Expression = { [int]$_.Minimum } },
      @{ Name = "End"; Expression = { [int]$_.Maximum } }
    }
  }
}

Function Get-CorrectedColumnsLineEntry {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [PsCustomObject] $LineEntry,
    [PsCustomObject[]] $ColumnInfoEntries 
  )

  PROCESS {

    $columns = [List[string]]::new()
    $usedWords = [List[Match]]::new()

    $allWords = $wordFinderRegex.Matches($LineEntry.LineWithoutSeparators)

    for ($i = 0; $i -lt $ColumnInfoEntries.Count; $i++) {
  
      $begin = $i -gt 0 ? $ColumnInfoEntries[$i-1].End + 1 : $null
      $end = $i -lt $ColumnInfoEntries.Count - 1 ? $ColumnInfoEntries[$i+1].Begin - 1 : $null  
      
      $wordMatches = $allWords | Where-Object { 
        $usedWords -notcontains $_ -and
        $_.Index -ge $begin ?? 0 -and 
        $_.Index + $_.Length -le $end ?? $LineEntry.Line.Length
      }  
        
      $columns.Add((($wordMatches | Select-Object -exp Value) -join " "))
      $wordMatches | ForEach-Object { $usedWords.Add($_) }
    }
  
    $LineEntry.Columns = $columns  
 
    $LineEntry
  }
}

Function Build-Entity {
  [CmdletBinding()]  
  param(
    [Parameter(ValueFromPipeline)]
    [PsCustomObject] $LineEntry,
    [string[]] $Headers
  )

  PROCESS {

    $entry = [PsCustomObject]@{}

    for ($i = 0; $i -lt $Headers.Count; $i++) {
  
      $entry | Add-Member -Name $Headers[$i] -Value $LineEntry.Columns[$i] -MemberType NoteProperty 
    }
      
    Write-Verbose "$($LineEntry.Line)`n$(($entry | ConvertTo-Json))"
    
    $entry
  }
}

Export-ModuleMember -Function ConvertFrom-StringTable