# ConvertFrom-StringTable

A PowerShell cmdlet designed to effortlessly convert text tables into objects.

## Features:

- Converts text based tables into powershell objects.
- Columns can be left- right or centered aligned.
- Can parse any table layout using the `-TableSeparators` and `-ColumnSeparators` parameters.
- Headers can be optionally omitted..

This module supports parsing table output from major applications, such as : 
- Docker
- Kubernetes 
- Winget
- MySQL
- PostgreSQL
- SQLite
- AWS CLI
- Plus many more...

Check out the [Pester testcases](https://github.com/sietsevdschoot/ConvertFrom-StringTable/blob/main/tests/ConvertFrom-StringTable.tests.ps1) for examples of how these text tables can be parsed.

## Installation

You can install `ConvertFrom-StringTable` directly from the PowerShell Gallery using the following command:
```powershell
Install-Module ConvertFrom-StringTable -Repository PSGallery
```

Then import the module before use:

```powershell
Import-Module ConvertFrom-StringTable
```

## Usage

To convert a simple string table into PowerShell objects, you can use the following syntax:

```powershell
<Your command> | ConvertFrom-StringTable [-ColumnSeperators] <string> [-RowSeperators] <string> [-NoHeader]
```

```
docker ps -a

CONTAINER ID   IMAGE              COMMAND        CREATED         STATUS          PORTS     NAMES
a1b2c3d4e5f6   nginx:latest       "nginx -g.."   5 minutes ago   Up 5 minutes    80/tcp    webserver
b6c7d8e9f0a1   redis:latest       "redis-s..."   10 minutes ago  Up 10 minutes   6379/tcp  redis-server

docker ps -a | ConvertFrom-StringTable

ContainerId : a1b2c3d4e5f6
Image       : nginx:latest
Command     : "nginx -g.."
Created     : 5 minutes ago
Status      : Up 5 minut\es
Ports       : 80/tcp
Names       : webserver

ContainerId : b6c7d8e9f0a1
Image       : redis:latest
Command     : "redis-s..."
Created     : 10 minutes ago
Status      : Up 10 minutes
Ports       : 6379/tcp
Names       : redis-server
```

These objects can then be queried / manipulated further using the Powershell pipeline.
```powershell
$container = docker ps -a | ConvertFrom-StringTable | ?{ $_.Names -eq "webserver" }
```

## Parsing formatted tables.

`ConvertFrom-StringTable` can parse tables in various layouts using the `-TableSeperators` and `-ColumnSeparators` parameters:

### Winget

```powershell
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

# winget search dotnet | ConvertFrom-StringTable
$cmdOutput | ConvertFrom-StringTable
```

### DoubleLineTableRenderer

```powershell
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

$cmdOutput | ConvertFrom-StringTable -TableSeparators "╠╬╣═╚╩╝╔╦╗ " -ColumnSeparators "║"
```

### SQLite
```powershell
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
```

### MinimalTableRenderer
```powershell
$cmdOutput = '

  Product Quantity Price
  Laptop  2        € 1200
  Phone   5        € 500
'

$actual = $cmdOutput | ConvertFrom-StringTable
```

## Known Issues

- For correct parsing, a table must contain at least one line (header or row) with all column values separated by two or more spaces.

## Acknowledgments

Special thanks to:  
https://github.com/RobThree/TextTableBuilder

This project inspired several testcases and challenges on how to parse tables in rendered with different layouts.

The source for the testcases for these renderers, and examples used in this documentation can be found in the [documentation](https://github.com/RobThree/TextTableBuilder?ab=readme-ov-file#examples) of TextTableBuilder.

[Functional](https://www.powershellgallery.com/packages/functional/0.0.4) is used in Pester extensions for object comparisons.

## Contributing

Contributions are welcome! If you encounter any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request on GitHub.

## License

This project is licensed under the MIT License. See the [LICENSE](https://raw.githubusercontent.com/sietsevdschoot/ConvertFrom-StringTable/main/LICENSE) file for details.
