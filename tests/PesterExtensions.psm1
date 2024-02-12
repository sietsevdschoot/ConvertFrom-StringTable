#requires -Modules Functional 

Function BeEquivalentTo {
  param (
    [PSCustomObject] $ActualValue,
    [Parameter(ValueFromRemainingArguments)]
    [PsCustomObject] $Expected,
    [PsCustomObject] $CallerSessionState,
    [Switch] $Negate
  )
  
  $success = (-not $Negate) -eq (Test-IsEquavalentTo @($ActualValue, $Expected))
  
  if (!$success) {
  
    $failureMessage = $Negate `
      ? "Expected object not to be equivalent to:`n$(($Expected | ConvertTo-Json))" `
      : "Expected:`n$(($Expected | ConvertTo-Json))`nBut found: `n$(($ActualValue | ConvertTo-Json))"
  }
  
  [PsCustomObject]@{ Succeeded = $success; FailureMessage = $failureMessage }
}
  
Function ContainEquivalentOf {
  param (
    [PSCustomObject[]] $ActualValue,
    [Parameter(ValueFromRemainingArguments)]
    [PsCustomObject] $Expected,
    [PsCustomObject] $CallerSessionState,
    [Switch] $Negate
  )
  
  $isMatch = $false
    
  foreach ($item in $ActualValue) {
      
    if ((Test-IsEquavalentTo @($item, $Expected))) {
  
      $isMatch = $true
      break;
    }
  }
  
  $success = (-not $Negate) -eq $isMatch
  
  if (!$success) {
  
    $failureMessage = $Negate `
      ? "Expected collection not to contain:`n$(($Expected | ConvertTo-Json))" `
      : "Expected collection to contain:`n$(($Expected | ConvertTo-Json))`nBut found: `n$(($ActualValue | ConvertTo-Json))"
  }
  
  [PsCustomObject]@{ Succeeded = $success; FailureMessage = $failureMessage }
}

Function Test-IsEquavalentTo {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [object[]] $Objects
  )

  # Compare two arrays with valueTypes or strings, types which can be sorted. Sort
  # before comparing. Order is irrelevant in our tests.
  if ($Objects | ForEach-Object { $item = $_; Test-IsArrayOfValueTypes $item } | Test-All) {

    $Objects | ForEach-Object { ,($_ | Sort-Object) }  | Test-Equality
  }
  else {

    # One of the arguments is an array, the other is not. Some the times it is comparing an object 
    # with an array containing a single item. Flatten the arrays before use.
    if ($Objects | ForEach-Object { $_ -is [array] } | Reduce-Object { param($a, $b) $a -xor $b }) {

      $Objects | ForEach-Object { $_ } | Test-Equality
    }
    else {
    
      $Objects | Test-Equality
    }
  }
} 

Function Test-IsArrayOfValueTypes {
  param(
    [object] $Object 
  )

  $isArrayOfStringOrValueTypes = ($object -is [array] -and (@($object) | ForEach-Object { $_.GetType().IsValueType -or $_ -is [string] } | Test-All ))
  $null -ne $Object -and $isArrayOfStringOrValueTypes
}

Export-ModuleMember -Function BeEquivalentTo
Export-ModuleMember -Function ContainEquivalentOf