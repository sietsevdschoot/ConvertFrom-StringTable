#requires -Modules Functional 

Function BeEquivalentTo {
    param (
      [PSCustomObject] $ActualValue,
      [Parameter(ValueFromRemainingArguments)]
      [PsCustomObject] $Expected,
      [PsCustomObject] $CallerSessionState,
      [Switch] $Negate
    )
  
    $success = (-not $Negate) -eq ($ActualValue, $Expected | Test-Equality)
  
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
      
      if (($item, $Expected | Test-Equality)) {
  
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

Export-ModuleMember -Function BeEquivalentTo
Export-ModuleMember -Function ContainEquivalentOf