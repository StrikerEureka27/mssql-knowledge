--Prerrequisitos para Cifrado de Copias de Seguridad de SQL Server
/*
Antes de realizar un cifrado de copia de seguridad verifique si hay una Clave Maestra de Servicio 
y una Clave Maestra de Base de Datos en la base de datos maestra. Como una Clave Maestra de Servicio 
es generada automáticamente durante la instalación de SQL Server, debería ya estar contenida 
en la base de datos maestra. La presencia de SMK y DMK es revisada consultando 
la vista de catálogo master.sys.symmetric_keys y buscando la fila ##MS_DatabaseMasterKey## en los resultados:*/

SELECT * FROM master.sys.symmetric_keys 
--Si la fila ##MS_DatabaseMasterKey## no existe, use la siguiente consulta para crearla:
Select * from sys.certificates


--DROP MASTER KEY
--DROP  CERTIFICATE CERTIFICADOSEGURIDAD
CREATE MASTER KEY ENCRYPTION BY PASSWORD=''
--A continuación, necesitamos crear un certificado:
USE master
GO
CREATE CERTIFICATE CERTIFICADOSEGURIDAD
WITH SUBJECT = 'SQL Server 2016 CERTIFICADO DE SEGURIDAD';
GO

/*
Para respaldar un certificado y las claves maestras use las siguientes consultas:
Respaldar la Clave Maestra de Servicio:*/

-- Backup the Service Master Key
USE master
GO
BACKUP SERVICE MASTER KEY
TO FILE = 'E:\BKSQLSERVER\SECURITY_SQLSERVER\SQL2016_CMS.key'
ENCRYPTION BY PASSWORD = '';
GO
--Respaldar la Clave Maestra de Base de Datos:
-- Backup the Database Master Key

BACKUP MASTER KEY
TO FILE = 'E:\BKSQLSERVER\SECURITY_SQLSERVER\SQL2016_CMB.key'
ENCRYPTION BY PASSWORD = '';
GO
--Respaldar el Certificado:
BACKUP CERTIFICATE CERTIFICADOSEGURIDAD
TO FILE = 'E:\BKSQLSERVER\SECURITY_SQLSERVER\SQL2016_CERTIFICADODERESPALDO.cer'
WITH PRIVATE KEY
        (	        
		     FILE = 'E:\BKSQLSERVER\SECURITY_SQLSERVER\SQL2016_LC.key'
            , ENCRYPTION BY PASSWORD = ''
        );
GO





--USE [TestDB]
--GO
--CREATE DATABASE ENCRYPTION KEY
--WITH ALGORITHM = AES_256
--ENCRYPTION BY SERVER CERTIFICATE CERTIFICADOSEGURIDAD;

--ALTER DATABASE [TestDB]
--SET ENCRYPTION ON;
--GO