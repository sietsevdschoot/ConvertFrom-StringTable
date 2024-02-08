# ConvertFrom-StringTable

A PowerShell module designed to effortlessly convert various types of string tables into objects.

```ConvertFrom-StringTable``` simplifies the process of parsing table output from major applications like Docker, Kubernetes, MySQL, PostgreSQL, SQLite, AWS CLI, and more.

This module simplifies the process of extracting structured data from command line outputs, enabling seamless integration with PowerShell scripts and automation pipelines.

## Installation

You can install ConvertFrom-StringTable directly from the PowerShell Gallery using the following command:
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

### Real-World Examples

Kubernetes Ouput
```powershell
kubectl get pods | ConvertFrom-Stringtable
```

AWS CLI Output
```powershell
aws ec2 describe-instances | ConvertFrom-StringTable
```

PostgreSQL Output
```powershell
psql -c "SELECT * FROM users" | ConvertFrom-StringTable
```

## Parsing formatted tables.


## Known Issues

- For correct parsing, a table must contain at least one line (header or row) with all column values separated by two or more spaces.

## Contributing

Contributions are welcome! If you encounter any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request on GitHub.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

Special thanks to the maintainers of TextTableBuilder, which inspired the handling of different table renderers in this module.
