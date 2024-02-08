#requires -Modules Pester, Functional 

Describe "Convert-FromStringTable" {

    BeforeAll {

        Import-Module $PSScriptRoot\..\src\ConvertFrom-StringTable.psm1 -Force
    }
    
    It "Can convert simple string table" {

        $commandOutput = 
        @"
        CONTAINER ID   IMAGE              COMMAND        CREATED         STATUS          PORTS     NAMES
        a1b2c3d4e5f6   nginx:latest       "nginx -g.."   5 minutes ago   Up 5 minutes    80/tcp    webserver
        b6c7d8e9f0a1   redis:latest       "redis-s..."   10 minutes ago  Up 10 minutes   6379/tcp  redis-server
"@

        # $actual = docker ps -a | ConvertFrom-StringTable
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("ContainerId", "Image", "Command", "Created", "Status", "Ports", "Names" | Sort-Object) 

        $actual.Count | Should -Be 2
    } 

    It "Can detect header in string table" {
 
        $commandOutput = @"

        Active Connections
        
            Proto  Local Address          Foreign Address        State
            TCP    127.0.0.1:101          127.0.0.1:104          ESTABLISHED
            TCP    127.0.0.1:102          127.0.0.1:105          ESTABLISHED
            TCP    127.0.0.1:103          127.0.0.1:106          TIME_WAIT
"@

        # $actual = netstat -n | ConvertFrom-StringTable
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("Proto", "LocalAddress", "ForeignAddress", "State" | Sort-Object) 

        $actual.Count | Should -Be 3
    }

    It "Can parse actual command output " {
 
        $actual = netstat -aon | Select-Object -First 20 | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("Proto", "LocalAddress", "ForeignAddress", "State", "PID" | Sort-Object) 

        $actual.Count | Should -Be 16
    }

    It "Can parse PostgreSQL output" {

        $commandOutput = @"
        id   |  name   |   email
        -----+---------+---------------
        1    | John    | john@example.com
        2    | Jane    | jane@example.com
"@

        # $actual = psql -c "SELECT * FROM users" | ConvertFrom-StringTable
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("id", "name", "email" | Sort-Object) 

        $actual | Select-Object -exp Name | Should -Be @("John", "Jane")

        $actual.Count | Should -Be 2
    } 

    It "Can parse MySQL output" {

        $commandOutput = @"
        +----+-------+-------------------+
        | id | name  | email             |
        +----+-------+-------------------+
        | 1  | John  | john@example.com  |
        | 2  | Jane  | jane@example.com  |
        +----+-------+-------------------+
"@

        # $actual = mysql -e "SELECT * FROM users" | ConvertFrom-StringTable
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("id", "name", "email" | Sort-Object) 

        $actual | Select-Object -exp Name | Should -Be @("John", "Jane")

        $actual.Count | Should -Be 2
    } 

    It "Can parse SQLite output" {

        $commandOutput = @"
        id   name  email
        ---  ----  ---------------
        1    John  john@example.com
        2    Jane  jane@example.com
"@

        # $actual = sqlite3 test.db ".headers on" ".mode column" "SELECT * FROM users;" | ConvertFrom-StringTable
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("id", "name", "email" | Sort-Object) 

        $actual.Count | Should -Be 2
    } 

    It "Can parse AWS CLI output" {
       
        $commandOutput = @"
        INSTANCE_ID     INSTANCE_TYPE    STATE      PUBLIC_IP      PRIVATE_IP     LAUNCH_TIME
        i-1a2b3c4d5e6   t2.micro         running    54.123.456.78  10.0.0.1       2021-05-01T12:34:56
        i-6d5e4c3b2a1   t3.small         running    12.345.678.90  10.0.0.2       2021-04-15T09:23:45
"@

        # $actual = aws ec2 describe-instances | ConvertFrom-StringTable
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("InstanceId", "InstanceType", "State", "PublicIp", "PrivateIp", "LaunchTime" | Sort-Object) 

        $actual.Count | Should -Be 2
    }
    
    # https://github.com/RobThree/TextTableBuilder
    # https://www.nuget.org/packages/TextTableBuilder
    It "Can parse TextTableBuilder DoubleLineTableRenderer output" {
       
        $commandOutput = @"
        ╔════╦═════════════════╦═══════════════════╦════════════════╗
        ║ No ║ Name            ║ Position          ║         Salary ║
        ╠════╬═════════════════╬═══════════════════╬════════════════╣
        ║ 1  ║ Bill Gates      ║ Founder Microsoft ║    $ 10,000.00 ║
        ║ 2  ║ Steve Jobs      ║ Founder Apple     ║ $ 1,200,000.00 ║
        ║ 3  ║ Larry Page      ║ Founder Google    ║ $ 1,100,000.00 ║
        ║ 4  ║ Mark Zuckerberg ║ Founder Facebook  ║ $ 1,300,000.00 ║
        ╚════╩═════════════════╩═══════════════════╩════════════════╝
"@

        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable -TableSeparators "╠╬╣═╚╩╝╔╦╗ " -ColumnSeparators "║"

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("No", "Name", "Position", "Salary" | Sort-Object) 

        $actual.Count | Should -Be 4
    }

    # https://github.com/RobThree/TextTableBuilder
    It "Can parse TextTableBuilder MSDOSTableRenderer output" {
       
        $commandOutput = @"
         No ║ Name            ║ Position          ║         Salary 
        ════║═════════════════║═══════════════════║════════════════
         1  ║ Bill Gates      ║ Founder Microsoft ║    $ 10,000.00 
         2  ║ Steve Jobs      ║ Founder Apple     ║ $ 1,200,000.00 
         3  ║ Larry Page      ║ Founder Google    ║ $ 1,100,000.00 
         4  ║ Mark Zuckerberg ║ Founder Facebook  ║ $ 1,300,000.00 
"@

        $actual = ($commandOutput -split "`n" ) | ConvertFrom-StringTable -TableSeparators "═║═ " -ColumnSeparators "║"

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("No", "Name", "Position", "Salary" | Sort-Object) 

        $actual.Count | Should -Be 4
    }

    # https://github.com/RobThree/TextTableBuilder
    It "Can parse TextTableBuilder DotsTableRenderer output" {
       
        $commandOutput = @"
        .............................................................
        : No : Name            : Position          :         Salary :
        :....:.................:...................:................:
        : 1  : Bill Gates      : Founder Microsoft :    $ 10,000.00 :
        : 2  : Steve Jobs      : Founder Apple     : $ 1,200,000.00 :
        : 3  : Larry Page      : Founder Google    : $ 1,100,000.00 :
        : 4  : Mark Zuckerberg : Founder Facebook  : $ 1,300,000.00 :
        .............................................................
"@

        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable -TableSeparators ".: " -ColumnSeparators ":"

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("No", "Name", "Position", "Salary" | Sort-Object) 

        $actual.Count | Should -Be 4
    }

    # https://github.com/RobThree/TextTableBuilder
    It "Can parse TextTableBuilder MinimalTableRenderer output" {
       
        $commandOutput = @"
        No Name            Position                  Salary
        1  Bill Gates      Founder Microsoft    $ 10,000.00
        2  Steve Jobs      Founder Apple     $ 1,200,000.00
        3  Larry Page      Founder Google    $ 1,100,000.00
        4  Mark Zuckerberg Founder Facebookk $ 1,300,000.00
"@

        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("No", "Name", "Position", "Salary" | Sort-Object) 

        $actual.Count | Should -Be 4

        $actual[3], ([PsCustomObject]@{ No="4"; Name="Mark Zuckerberg"; Position="Founder Facebookk"; Salary="$ 1,300,000.00" }) | Test-Equality | Should -BeTrue -Because ($actual[3] | ConvertTo-Json)
    }

    It "Can convert docker container output with powershell error" {

        $commandOutput = @"
        failed to get console mode for stdout: The handle is invalid.
        CONTAINER ID   IMAGE              COMMAND        CREATED         STATUS          PORTS     NAMES
        a1b2c3d4e5f6   nginx:latest       "nginx -g.."   5 minutes ago   Up 5 minutes    80/tcp    webserver
        b6c7d8e9f0a1   redis:latest       "redis-s..."   10 minutes ago  Up 10 minutes   6379/tcp  redis-server
"@
        # Docker for Windows issue: https://github.com/docker/for-win/issues/13891
        # $actual = docker ps -a | ConvertFrom-StringTable
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("ContainerId", "Image", "Command", "Created", "Status", "Ports", "Names" | Sort-Object) 

        $actual.Count | Should -Be 2
    }

    It "Can parse output containing multiple newlines" {

        $commandOutput = @"


        Product Quantity Price
        Laptop  2        € 1200
        Phone   5        € 500
    
"@
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("Product", "Quantity", "Price" | Sort-Object) 

        $actual.Count | Should -Be 2
    }

    It "Can parse output with empty cell values" {

        $commandOutput = @"
        No Name            Position                  Salary
        1  Bill Gates      Founder Microsoft    $ 10,000.00
        2  Steve Jobs      Founder Apple     $ 1,200,000.00
        3  Reid Hoffman    Founder LinkedIn    $ 900,000.00
        4  Larry Page      Founder Google
        5  Mark Zuckerberg                   $ 1,300,000.00
"@
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("No", "Name", "Position", "Salary" | Sort-Object) 

        $actual.Count | Should -Be 5

        $actual[1], ([PsCustomObject]@{ No="2"; Name="Steve Jobs"; Position="Founder Apple"; Salary="$ 1,200,000.00" }) | Test-Equality | Should -BeTrue -Because ($actual[1] | ConvertTo-Json)
        $actual[3], ([PsCustomObject]@{ No="4"; Name="Larry Page"; Position="Founder Google"; Salary="" }) | Test-Equality | Should -BeTrue -Because ($actual[3] | ConvertTo-Json)
        $actual[4], ([PsCustomObject]@{ No="5"; Name="Mark Zuckerberg"; Position=""; Salary="$ 1,300,000.00" }) | Test-Equality | Should -BeTrue -Because ($actual[4] | ConvertTo-Json)
    }

    It "Can parse output with lots of missing data" {

        $commandOutput = @"
        No  Name            Position                  Salary
        1   Bill Gates
        2   Steve Jobs
        3   Reid Hoffman
        4   Larry Page
"@
        $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable

        $properties = $actual | Get-Member -MemberType NoteProperty | Select-Object -exp Name
        $properties | Sort-Object | Should -Be ("No", "Name", "Position", "Salary" | Sort-Object) 

        $actual.Count | Should -Be 4

        $actual[0], ([PsCustomObject]@{ No="1"; Name="Bill Gates"; Position=""; Salary="" }) | Test-Equality | Should -BeTrue -Because ($actual[0] | ConvertTo-Json)
        $actual[3], ([PsCustomObject]@{ No="4"; Name="Larry Page"; Position=""; Salary="" }) | Test-Equality | Should -BeTrue -Because ($actual[3] | ConvertTo-Json)
    }
}