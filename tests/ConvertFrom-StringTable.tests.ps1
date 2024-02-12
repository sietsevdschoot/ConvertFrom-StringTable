#requires -Modules Pester

Describe "Convert-FromStringTable" {

  BeforeAll {

    Import-Module $PSScriptRoot\Extensions\PesterExtensions.psm1 -Force
    Import-Module $PSScriptRoot\..\src\ConvertFrom-StringTable.psm1 -Force

    Add-ShouldOperator -Name BeEquivalentTo -Test $function:BeEquivalentTo -SupportsArrayInput
    Add-ShouldOperator -Name ContainEquivalentOf -Test $function:ContainEquivalentOf -SupportsArrayInput
  }
    
  It "Can convert simple string table" {

    $cmdOutput = '

      CONTAINER ID   IMAGE              COMMAND        CREATED         STATUS          PORTS     NAMES
      a1b2c3d4e5f6   nginx:latest       "nginx -g.."   5 minutes ago   Up 5 minutes    80/tcp    webserver
      b6c7d8e9f0a1   redis:latest       "redis-s..."   10 minutes ago  Up 10 minutes   6379/tcp  redis-server
    '

    # docker ps -a | ConvertFrom-StringTable
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("ContainerId", "Image", "Command", "Created", "Status", "Ports", "Names") 

    $actual.Count | Should -Be 2
  } 

  It "Can detect header in string table" {
 
    $cmdOutput = '

      Active Connections
      
          Proto  Local Address          Foreign Address        State
          TCP    127.0.0.1:101          127.0.0.1:104          ESTABLISHED
          TCP    127.0.0.1:102          127.0.0.1:105          ESTABLISHED
          TCP    127.0.0.1:103          127.0.0.1:106          TIME_WAIT
    '

    # $actual = netstat -n | ConvertFrom-StringTable
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("Proto", "LocalAddress", "ForeignAddress", "State") 

    $actual.Count | Should -Be 3
  }

  It "Can parse actual command output " {
 
    $actual = netstat -aon | Select-Object -First 20 | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("Proto", "LocalAddress", "ForeignAddress", "State", "PID") 

    $actual.Count | Should -Be 16
  }

  It "Can parse PostgreSQL output" {

    $cmdOutput = '
      id   |  name   |   email
      -----+---------+---------------
      1    | John    | john@example.com
      2    | Jane    | jane@example.com
    '

    # $actual = psql -c "SELECT * FROM users" | ConvertFrom-StringTable
    $actual = $cmdOutput | ConvertFrom-StringTable

    $actual | Should -BeEquivalentTo @(
      ([PsCustomObject]@{ id = "1"; name = "John"; email = "john@example.com"; })
      ([PsCustomObject]@{ id = "2"; name = "Jane"; email = "jane@example.com"; })
    )
  } 

  It "Can parse WinGet output" {

    $cmdOutput = '
    Name                                               Id                                         Version              Match       Source
    --------------------------------------------------------------------------------------------------------------------------------------
    Waf DotNetPad                                      9PB8D09261JR                               Unknown                          msstore
    IronPython 2                                       Microsoft.IronPython.2                     2.7.12.1000          Tag: dotnet winget
    Microsoft .NET SDK 8.0 Preview                     Microsoft.DotNet.SDK.Preview               8.0.100-rc.2.23502.2 Tag: dotnet winget
    Microsoft ASP.NET Core Hosting Bundle 8.0 Preview  Microsoft.DotNet.HostingBundle.Preview     8.0.0-rc.2.23480.2   Tag: dotnet winget
    Microsoft .NET Windows Desktop Runtime 6.0         Microsoft.DotNet.DesktopRuntime.6          6.0.26               Tag: dotnet winget
    Microsoft .NET Windows Desktop Runtime 5.0         Microsoft.DotNet.DesktopRuntime.5          5.0.17               Tag: dotnet winget    
    '

    # $actual = winget search dotnet | ConvertFrom-StringTable
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("Name", "Id", "Version", "Match", "Source") 

    $actual | Should -ContainEquivalentOf ([PsCustomObject]@{ 
      Name = "Microsoft ASP.NET Core Hosting Bundle 8.0 Preview"; 
      Id = "Microsoft.DotNet.HostingBundle.Preview"; 
      Version = "8.0.0-rc.2.23480.2"; 
      Match = "Tag: dotnet"; 
      Source = "winget"; 
    })

    $actual.Count | Should -Be 6
  } 

  It "Can parse MySQL output" {

    $cmdOutput = '
      +----+-------+-------------------+
      | id | name  | email             |
      +----+-------+-------------------+
      | 1  | John  | john@example.com  |
      | 2  | Jane  | jane@example.com  |
      +----+-------+-------------------+
    '

    # $actual = mysql -e "SELECT * FROM users" | ConvertFrom-StringTable
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("id", "name", "email") 

    $actual | Select-Object -exp Name | Should -Be @("John", "Jane")

    $actual.Count | Should -Be 2
  } 

  It "Can parse SQLite output" {

    $cmdOutput = '
      id   name  email
      ---  ----  ---------------
      1    John  john@example.com
      2    Jane  jane@example.com
    '

    # $actual = sqlite3 test.db ".headers on" ".mode column" "SELECT * FROM users;" | ConvertFrom-StringTable
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("id", "name", "email") 

    $actual.Count | Should -Be 2
  } 

  It "Can parse AWS CLI output" {
       
    $cmdOutput = '
      INSTANCE_ID     INSTANCE_TYPE    STATE      PUBLIC_IP      PRIVATE_IP     LAUNCH_TIME
      i-1a2b3c4d5e6   t2.micro         running    54.123.456.78  10.0.0.1       2021-05-01T12:34:56
      i-6d5e4c3b2a1   t3.small         running    12.345.678.90  10.0.0.2       2021-04-15T09:23:45
    '

    # $actual = aws ec2 describe-instances | ConvertFrom-StringTable
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("InstanceId", "InstanceType", "State", "PublicIp", "PrivateIp", "LaunchTime") 

    $actual.Count | Should -Be 2
  }
    
  # https://github.com/RobThree/TextTableBuilder
  # https://www.nuget.org/packages/TextTableBuilder
  It "Can parse TextTableBuilder DoubleLineTableRenderer output" {
       
    $cmdOutput = '
      ╔════╦═════════════════╦═══════════════════╦════════════════╗
      ║ No ║ Name            ║ Position          ║         Salary ║
      ╠════╬═════════════════╬═══════════════════╬════════════════╣
      ║ 1  ║ Bill Gates      ║ Founder Microsoft ║    $ 10,000.00 ║
      ║ 2  ║ Steve Jobs      ║ Founder Apple     ║ $ 1,200,000.00 ║
      ║ 3  ║ Larry Page      ║ Founder Google    ║ $ 1,100,000.00 ║
      ║ 4  ║ Mark Zuckerberg ║ Founder Facebook  ║ $ 1,300,000.00 ║
      ╚════╩═════════════════╩═══════════════════╩════════════════╝
    '

    $actual = $cmdOutput | ConvertFrom-StringTable -TableSeparators "╔╦╗╠╬╣╚╩╝═ " -ColumnSeparators "║"

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("No", "Name", "Position", "Salary") 

    $actual.Count | Should -Be 4
  }

  # https://github.com/RobThree/TextTableBuilder
  It "Can parse TextTableBuilder SingleLineTableRenderer output" {
       
    $cmdOutput = '
      ┌────┬─────────────────┬───────────────────┬────────────────┐
      │ No │ Name            │ Position          │         Salary │
      ├────┼─────────────────┼───────────────────┼────────────────┤
      │ 1  │ Bill Gates      │ Founder Microsoft │    $ 10,000.00 │
      │ 2  │ Steve Jobs      │ Founder Apple     │ $ 1,200,000.00 │
      │ 3  │ Larry Page      │ Founder Google    │ $ 1,100,000.00 │
      │ 4  │ Mark Zuckerberg │ Founder Facebook  │ $ 1,300,000.00 │
      └────┴─────────────────┴───────────────────┴────────────────┘
    '

    $actual = $cmdOutput | ConvertFrom-StringTable -TableSeparators "┌┬┐├┼┤└┴┘─ " -ColumnSeparators "│"

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("No", "Name", "Position", "Salary") 

    $actual.Count | Should -Be 4
  }

  # https://github.com/RobThree/TextTableBuilder
  It "Can parse TextTableBuilder MSDOSTableRenderer output" {
       
    $cmdOutput = '
      No ║ Name            ║ Position          ║         Salary 
     ════║═════════════════║═══════════════════║════════════════
      1  ║ Bill Gates      ║ Founder Microsoft ║    $ 10,000.00 
      2  ║ Steve Jobs      ║ Founder Apple     ║ $ 1,200,000.00 
      3  ║ Larry Page      ║ Founder Google    ║ $ 1,100,000.00 
      4  ║ Mark Zuckerberg ║ Founder Facebook  ║ $ 1,300,000.00 
    '

    $actual = $cmdOutput | ConvertFrom-StringTable -TableSeparators "═║═ " -ColumnSeparators "║"

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("No", "Name", "Position", "Salary") 

    $actual.Count | Should -Be 4
  }

  # https://github.com/RobThree/TextTableBuilder
  It "Can parse TextTableBuilder DotsTableRenderer output" {
       
    $cmdOutput = '
      .............................................................
      : No : Name            : Position          :         Salary :
      :....:.................:...................:................:
      : 1  : Bill Gates      : Founder Microsoft :    $ 10,000.00 :
      : 2  : Steve Jobs      : Founder Apple     : $ 1,200,000.00 :
      : 3  : Larry Page      : Founder Google    : $ 1,100,000.00 :
      : 4  : Mark Zuckerberg : Founder Facebook  : $ 1,300,000.00 :
      .............................................................
    '

    $actual = $cmdOutput | ConvertFrom-StringTable -TableSeparators ".: " -ColumnSeparators ":"

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("No", "Name", "Position", "Salary") 

    $actual.Count | Should -Be 4
  }

  # https://github.com/RobThree/TextTableBuilder
  It "Can parse TextTableBuilder MinimalTableRenderer output" {
       
    $cmdOutput = '
      No Name            Position                  Salary
      1  Bill Gates      Founder Microsoft $ 1,200,000.00
      2  Steve Jobs      Founder Apple        $ 10,000.00
      3  Larry Page      Founder Google    $ 1,100,000.00
      4  Mark Zuckerberg Founder Facebook  $ 1,300,000.00
    '

    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("No", "Name", "Position", "Salary") 

    $actual.Count | Should -Be 4

    $actual[0] | Should -BeEquivalentTo ([PsCustomObject]@{ No = "1"; Name = "Bill Gates"; Position = "Founder Microsoft"; Salary = "$ 1,200,000.00" })
  }

  It "Can convert docker container output with powershell error" {

    $cmdOutput = '
      failed to get console mode for stdout: The handle is invalid.
      CONTAINER ID   IMAGE              COMMAND        CREATED         STATUS          PORTS     NAMES
      a1b2c3d4e5f6   nginx:latest       "nginx -g.."   5 minutes ago   Up 5 minutes    80/tcp    webserver
      b6c7d8e9f0a1   redis:latest       "redis-s..."   10 minutes ago  Up 10 minutes   6379/tcp  redis-server
    '
    
    # Docker for Windows issue: https://github.com/docker/for-win/issues/13891
    # $actual = docker ps -a | ConvertFrom-StringTable
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("ContainerId", "Image", "Command", "Created", "Status", "Ports", "Names") 

    $actual.Count | Should -Be 2
  }

  It "Can parse output containing multiple newlines" {

    $cmdOutput = '


      Product Quantity Price
      Laptop  2        € 1200
      Phone   5        € 500
  
    '
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("Product", "Quantity", "Price") 

    $actual.Count | Should -Be 2
  }

  It "Can parse output with empty cell values" {

    $cmdOutput = '
      No Name            Position                  Salary
      1  Bill Gates      Founder Microsoft    $ 10,000.00
      2  Steve Jobs      Founder Apple     $ 1,200,000.00
      3  Reid Hoffman    Founder LinkedIn    $ 900,000.00
      4  Larry Page      Founder Google
      5  Mark Zuckerberg                   $ 1,300,000.00
    '
    
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("No", "Name", "Position", "Salary") 

    $actual.Count | Should -Be 5

    $actual[1] | Should -BeEquivalentTo ([PsCustomObject]@{ No = "2"; Name = "Steve Jobs"; Position = "Founder Apple"; Salary = "$ 1,200,000.00" })
    $actual[3] | Should -BeEquivalentTo ([PsCustomObject]@{ No = "4"; Name = "Larry Page"; Position = "Founder Google"; Salary = "" })
    $actual[4] | Should -BeEquivalentTo ([PsCustomObject]@{ No = "5"; Name = "Mark Zuckerberg"; Position = ""; Salary = "$ 1,300,000.00" })
  }

  It "Can parse output with lots of missing data" {

    $cmdOutput = '
      No  Name            Position                  Salary
      1   Bill Gates
      2   Steve Jobs
      3   Reid Hoffman
      4   Larry Page
    '
    $actual = $cmdOutput | ConvertFrom-StringTable

    $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
    $properties | Should -BeEquivalentTo @("No", "Name", "Position", "Salary") 

    $actual.Count | Should -Be 4

    $actual[0] | Should -BeEquivalentTo ([PsCustomObject]@{ No = "1"; Name = "Bill Gates"; Position = ""; Salary = "" })
    $actual[3] | Should -BeEquivalentTo ([PsCustomObject]@{ No = "4"; Name = "Larry Page"; Position = ""; Salary = "" })
  }

  It "Can parse output without headers" {

    $cmdOutput = 1..5 | ForEach-Object { (("a".."f" -join ""), ("A".."F" -join ""), (0..5 -join "")) -join "  " }  

    $actual = $cmdOutput | ConvertFrom-StringTable -NoHeader

    $actual[0] | Should -BeEquivalentTo ([PsCustomObject]@{ Property01 = "abcdef"; Property02 = "ABCDEF"; Property03 = "012345"; })
  }
}