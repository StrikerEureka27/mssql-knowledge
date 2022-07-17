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
DECLARE @headers VARCHAR(MAX)
DECLARE @footer VARCHAR(MAX)
DECLARE @Table VARCHAR(MAX)
DECLARE @table_rows VARCHAR(MAX)
DECLARE @row VARCHAR(MAX)
DECLARE @table_header VARCHAR(MAX)
DECLARE @mail VARCHAR(MAX)

-- Initialize variables
SET @count_temp = 1
SET @table_rows = ''
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


SET @headers  = ('<html> <style> *{ border: 0; padding: 0; font-family: "Trebuchet MS", "Lucida Sans Unicode", "Lucida Grande", "Lucida Sans", Arial, sans-serif; } table, th, td { border: 1px solid black; } th{ color: white; background-color: black; } td { min-width: 200px; } </style><head>'
 + '<h1>Registro de actividades sobre SQL server</h1>' 
 + '<h3>Host: <span>' + @@Servername + '</span></h3>' 
 + '<h3>Date: <span> ' + CAST(CURRENT_TIMESTAMP AS VARCHAR) + '</span></h3>'
 + '</head><body>') 


 SET @table_header = ('<table style="border: 1px solid black;">' 
		+'<tr>'
		+ '<th style="color: white; background-color: black;" >event_time</th>'
		+ '<th style="color: white; background-color: black;" >session_name</th>'
		+ '<th style="color: white; background-color: black;" >db_name</th>'
		+ '<th style="color: white; background-color: black;" >obj_name</th>'
		+ '<th style="color: white; background-color: black;" >statements</th>'
		+ '<th style="color: white; background-color: black;" >hostname</th>'
		+ '<th style="color: white; background-color: black;" >trans_id</th>'
		+ '<th style="color: white; background-color: black;" >sucessed</th>'
		+'</tr>')


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
	SET @row = ('<tr>'+
		+ '<td style="min-width: 200px;" >' + @event_time + '</td>' 
		+ '<td style="min-width: 200px;" >' + @session_name + '</td>'
		+ '<td style="min-width: 55px;" >' + @dbname + '</td>' 
		+ '<td style="min-width: 55px;" >' + @obj_name + '</td>' 
		+ '<td style="min-width: 200px;" >' + @stmnt + ' </td>' 
		+ '<td style="min-width: 100px;" >' + @hostname + ' </td>' 
		+ '<td style="min-width: 60px;" >' + @trans_id + ' </td>' 
		+ '<td style="min-width: 5px;" >' + CAST(@succeeded AS VARCHAR) + ' </td>' 
		+'</tr>')
		PRINT @event_time + ' ' + @stmnt
		SET @count_temp = @count_temp + 1;
		SET @table_rows = @table_rows + @row;
		FETCH NEXT FROM db_cursor INTO @event_time, @session_name, @dbname, @obj_name, @stmnt, @hostname, @trans_id, @succeeded
	END
	SET @footer = '</table></body></html>'
	SET @mail = @headers + @table_header + @table_rows + @footer
	PRINT @mail
	EXEC msdb.dbo.sp_send_dbmail
		@profile_name='DBA_profile',
		@recipients='interserverapp2@gmail.com',
		@subject='Informe de eventos',
		@Body=@Mail,
		@Body_format='HTML';
END
ELSE
	PRINT 'There are not new events'

CLOSE db_cursor
DEALLOCATE db_cursor
GO


