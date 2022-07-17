/*
	By: StrikerEureka27
*/

-- Event variables
DECLARE	@event_time VARCHAR(255)
DECLARE @session_name VARCHAR(50)
DECLARE @dbname VARCHAR(50)
DECLARE @obj_name VARCHAR(150)
DECLARE @stmnt VARCHAR(255)
DECLARE @hostname VARCHAR(150)
DECLARE @trans_id VARCHAR(50)
DECLARE @succeeded BIT
-- Operators variables
DECLARE @count_event INTEGER
DECLARE @count_temp INTEGER
DECLARE @last_count_event INTEGER
DECLARE @current_event_time VARCHAR(255)
DECLARE @last_event_time DATETIME2(7)
DECLARE @current_count_event INTEGER
-- SMTP template
DECLARE @encabezado VARCHAR(MAX)

-- Initialize variables
SET @count_temp = 1
SET @count_event = (SELECT COUNT(event_time) FROM sys.fn_get_audit_file('E:\BKSQLSERVER\AUDIT\Auditoria*',default, default))
USE DBAudit
SET @last_event_time = (SELECT last_event FROM audit_events WHERE id=1)
SET @last_count_event = (SELECT event_number FROM audit_events);
SET @current_event_time = (SELECT TOP 1 event_time FROM sys.fn_get_audit_file('E:\BKSQLSERVER\AUDIT\Auditoria*',default, default) ORDER BY event_time DESC)
SET @current_count_event = (SELECT COUNT(event_time) 
FROM sys.fn_get_audit_file('E:\BKSQLSERVER\AUDIT\Auditoria*',default, default) ec
WHERE CAST(ec.event_time AS datetime2(7)) BETWEEN DATEADD(MILLISECOND,1, CAST(@last_event_time AS datetime2(7))) AND CAST(@current_event_time AS datetime2(7)))

-- Declare cursor
DECLARE db_cursor CURSOR FOR 
SELECT ec.event_time, ec.session_server_principal_name, ec.database_name, ec.object_name, ec.statement, ec.host_name, ec.transaction_id, ec.succeeded 
FROM sys.fn_get_audit_file('E:\BKSQLSERVER\AUDIT\Auditoria*',default, default) ec
WHERE CAST(ec.event_time AS datetime2(7)) BETWEEN DATEADD(SECOND,1,CAST(@last_event_time AS datetime2(7))) AND CAST(@current_event_time AS datetime2(7)) 
ORDER BY event_time DESC;

PRINT ' --- Date operations ---'
PRINT 'last_event_time: ' + CAST(CAST(@last_event_time AS datetime2(7)) AS VARCHAR)
PRINT 'last_event_time: +' + CAST(DATEADD(SECOND,1,CAST(@last_event_time AS datetime2(7))) AS VARCHAR)
PRINT 'current_event_time: ' + CAST(CAST(@current_event_time AS datetime2(7)) AS VARCHAR)
PRINT '-----------------------'


SET @encabezado  = '<html><head>' + '<style>' +
	
-- Open cursor
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @event_time, @session_name, @dbname, @obj_name, @stmnt, @hostname, @trans_id, @succeeded

-- Operations core
IF (@count_event > @last_count_event)
BEGIN
	USE DBAudit
	UPDATE audit_events SET last_event = CAST(@current_event_time AS datetime2(7)), event_number = @count_event  WHERE id=1;
	WHILE (@count_temp <= @current_count_event)
	BEGIN
		PRINT @event_time + ' ' + @stmnt
		SET @count_temp = @count_temp + 1;
		FETCH NEXT FROM db_cursor INTO @event_time, @session_name, @dbname, @obj_name, @stmnt, @hostname, @trans_id, @succeeded
	END
	SET @count_temp = 0
END
ELSE
	PRINT 'There are not new events'

CLOSE db_cursor
DEALLOCATE db_cursor
GO

