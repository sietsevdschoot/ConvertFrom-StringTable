# ConvertFrom-StringTable

A PowerShell module designed to effortlessly convert various types of string tables into objects.

`ConvertFrom-StringTable` simplifies the process of extracting structured data from command line outputs, enabling seamless integration with PowerShell scripts and automation pipelines.

This module supports parsing of parsing table output from major applications like Docker, Kubernetes, MySQL, PostgreSQL, SQLite, AWS CLI, and more.

## Installation

You can install `ConvertFrom-StringTable` directly from the PowerShell Gallery using the following command:
```powershell
Install-Module -Name ConvertFrom-StringTable
```

Then import the module before use:

```powershell
Import-Module ConvertFrom-StringTable
```

## Usage

To convert a simple string table into PowerShell objects, you can use the following syntax:

```powershell
<Your command> | ConvertFrom-StringTable [-ColumnSeperators] <string> [-RowSeperators] <string> 
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
Status      : Up 5 minutes
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

## Parsing formatted tables.

`ConvertFrom-StringTable` can parse table in various layouts.

### DoubleLineTableRenderer:

```powershell
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
  ($commandOutput -split "`n") | ConvertFrom-StringTable -TableSeparators "╠╬╣═╚╩╝╔╦╗ " -ColumnSeparators "║"
```


### SQLite
```powershell
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
```

### MinimalTableRenderer
```powershell
  $commandOutput = @"

  Product Quantity Price
  Laptop  2        € 1200
  Phone   5        € 500
"@

  $actual = ($commandOutput -split "`n") | ConvertFrom-StringTable
```

## Known Issues

- For correct parsing, a table must contain at least one line (header or row) with all column values separated by two or more spaces.

## Contributing

Contributions are welcome! If you encounter any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request on GitHub.

## License

This project is licensed under the MIT License. See the [LICENSE](https://raw.githubusercontent.com/sietsevdschoot/ConvertFrom-StringTable/main/LICENSE) file for details.

## Acknowledgments

Special thanks to:  
https://github.com/RobThree/TextTableBuilder

This project inspired several testcases and challenges on how to parse tables in rendered with different layouts.

The source for the testcases for these renderers, and examples used in this documentation can be found in the [documentation](https://github.com/RobThree/TextTableBuilder?ab=readme-ov-file#examples) of `TextTableBuilder`.