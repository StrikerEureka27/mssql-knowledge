## Advance guideness for SQL server

### Enviroment configuration

To make this guide, we create a Windows Server 2016 virtual environment with the following servers:

- SRVCD2016
- SRVDB12016
- SRBDB22016

SRVD2016 this server serves as the domain controller, here we create and configure the network and we configure the active directory configurations. 

SRVDB12016 this is our principal database server so here we install and configure SQL server instance, we enable all the services except R service for this guide. First recommendation for the storage is to create a different partitions for all read/write activity that makes the instance of SQL server. This is going to help SQL server instance to help perform well write/read activities. The partition will be like:

- LDF: Log de transactions 
- TEMPDB: Temporal databases
- MDF: All database data
- BACKUP: To store automatic backups.
- SYSTEM: 

SRBDB22016 this is our disaster server, so we are going to use a mirroring arquitecture with SQL server tools. 

### SQL server installation  and configuration

#### sql characteristics

First in characteristic configurations we select all except R services, ¿What services do we need to activate? The best practice for installation of an SQL server is to select only the services that we are going to use depending on requierments and not of them. 

#### id instance 

If we are going to have multiple instances, the recommendation is to change the name to an explicit one, a server can manage a number up to 120 instances more or less. 

#### sql services

The SQL server creates anonymus user accounts service to run it, but the best practice is to have a user run this server. This user doesn't need to have login privileges, they can be services account user. 

####  database engine configurations

Here we create the *sa* user for administration, and we can add other users as needed. Then here we can the configure Data directory. Here we have to distribute the files that the database engine generates and that it needs to operate. 

- root data pad: (MDF)
- backup pad: we configure the backup partition (BACKUP)
- register pad: transactional log partition (LDF)
- database pad: all data of databases (MDF)
- tempdb pad: tempdb data (TEMPDB)

> FILESTREAM options if we want to store images on our data base and we can also active this option. 

### SQL configuration manager 

Here we can see a lot of information about our SQL server, we can see the status of the service and if we need to, we can change some properties. In this case we are going to assign all services to a services account that we have already created.

#### port configuration

default configuration 1433, new port 2109

#### open remote connection 

In network configurations we have to enable Named Pipes and in TCP/IP we have to enable IP2 and IP4

#### hide sql server instance

Hide SQL server instances in the from the Configuration Manager

```
Configuration Manager > Network configuration > Protocols > Properties > Hide > on
```

### ApexSQL installation 

Apex is an intelligent interpreter that helps us to create Querys faster. 

First of all, we need to disactivate IntelliSense from SQL server. This is the default interpreter, therefore we go to..

```
Tools > Options > Transact-SQL > IntelliSense > Disable
Tools > Options > Designers > Table an Database Designers > Prevent saving changes that requiere table-recreation
```

Then we have to enable Apex

```
ApexSQL > Enable
```

### SQL ToolBelt

This software make us more productivity when we are searching for objects, writing query's and using shortcuts also have a documentary element to generate Data dictionary. 

## Audit

We have the options in properties of the instance to enable C2 audit tracing, this with the objective to track all SQL statements that's run in the instance. 

```
InstaceSQL > Properties > Security > Enable C2 audit tracing
```

### SQL server audit log

Save a historic for changes that are related to permissions 

```
Security > Audits > New Audit
```

We can select the exit type for de audit, in this case I select File output, Then we create Server audits Specifications 

```
Security > Audits > Server Audit Specification
```

Here the most common audit Action type to select are:

```
DATA_ROLE_MEMBER_CHANGE_GROUP
SERVER_ROLE_MEMBER_CHANGE_GROUP
DATABASE_PERMISSION_CHANGE_GROUP
SERVER_OBJECT_PERMISSION_CHANGE_GROUP
DATABASE_PRINCIPAL_CHANGE_GROUP
SERVER_PRINCIPAL_CHANGE_GROUP
```







## Server properties configurations

Limit the memory, the recommendations is to have 20% of the total memory (RAM)

## Backup strategy

#### use case

If the server fails at 10:05 on Wednesday, our backup strategy is the next one...

```
	BACKUP_FULL + DIFE(MONDAY) + DIFE(TUESDAY) + TRANSLOG1 + TRANSLOG2
```

With this strategy we have only 5 minutes of data lost

#### backup planing

| TRANS   | TIME  | MONDAY      | TUESDAY   | WEDNESDAY | THURSDAY  | FRIDAY    | SATURDAY | SUNDAY |
| ------- | ----- | ----------- | --------- | --------- | --------- | --------- | -------- | ------ |
| 100     | 5:00  | FULL_BACKUP |           |           |           |           |          |        |
|         | 6:00  |             |           |           |           |           |          |        |
|         | 7:00  |             |           |           |           |           |          |        |
|         | 8:00  |             |           |           |           |           |          |        |
| 101-110 | 9:00  | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 110-120 | 10:00 | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 121-130 | 11:00 | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 131-140 | 12:00 | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 141-150 | 13:00 | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 151-200 | 14:00 | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 201-210 | 15:00 | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 211-220 | 16:00 | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 221-230 | 17:00 | TRANS_LOG   | TRANS_LOG | TRANS_LOG | TRANS_LOG | TRANS_LOG |          |        |
| 231-240 | 18:00 | DIFE        | DIFE      | DIFE      | DIFE      | DIFE      |          |        |
| 241-250 | 19:00 |             |           |           |           |           |          |        |

#### considerations

- To have this backup strategy our backup needs to have Recovery Model on FULL

- Compress backup data for reduce 70% of the total weight of the backup

#### recovery steps 

In case we want to recover a day of work

1. Restore FULL_BACKUP with NO RECOVERY MODE and disable tail-log option 
2. Restore DIF with RECOVERY MODE

In case we want to recover in an specific time of a day of work

1. Restore FULL_BACKUP with NO RECOVERY MODE and disable tail-log option 
2. Restore TRANS_LOG with NO RECOVERY MODE and disable tail-log option 
3. Loop in step 2 while all TRANS_LOG are restored. 
4. In the las TRANS_LOG recover change to RECOVERY MODE.

> Note: Remember that the formula is going to change depending of the case 

#### backups encryption

We have to create a private key from master table and a certificate, then we do a backup for this file and we storage in a safe place.

> Note: The SQL command for this operation is in this project with the name **backup-encryption**

## Databases

After restore a database that was created in a old version of SQL server we have to change compatibility this on...

```
Database > Properties > Options > Compatibility level
```

## SQL backup and FTP

We can use this software to make backups to the cloud

## Database Mail

```
Management > DatabaseMail > Configure Database Mail
```

1. Create a new profile
2. Write a description of the profile
3. Add SMTP account 
4. Create account
   - servername: smtp.gmail.com
   - port: 587
   - ssl connection 

> If smtp like google or outlook use 2FA this feature its not going to work

##  Operators and Alerts

We can create Operators that execute a SSIS package, Transact SQL script and CLR when SQL server instance generate a specific Alert this could be a Error number a warning an stuff like that. We can relation a alert to notify us at a gmail

There are tree types of alert

- SQL Server event alert
- SQL Server performance condition alert
- WMI event alert













