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
    [object[]] $Object
  )

  if ((Test-IsArrayOfValueTypes $Object | Test-All)) {

    $Object | ForEach-Object { (@($_) | Sort-Object) } | Test-Equality

  }
  else {
    $Object | Test-Equality
  }
} 

Function Test-IsArrayOfValueTypes {
  param(
    [object] $Object 
  )

  $object -is [array] -and (@($object) | ForEach-Object { $_.GetType().IsValueType } | Test-All )
}


Export-ModuleMember -Function BeEquivalentTo
Export-ModuleMember -Function ContainEquivalentOf