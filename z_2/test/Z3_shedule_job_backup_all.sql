EXEC msdb.dbo.sp_add_job
   @job_name = N'MakeDailyJob',
   @enabled = 1,
   @description = N'Procedure execution every day' ;

 EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'MakeDailyJob',
    @step_name = N'Run Procedure',
    @subsystem = N'TSQL',
    @command = N'EXEC master.dbo.DB_BACKUP_ALL @path =  "/var/opt/mssql/backups/"';

 EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Everyday schedule',
    @freq_type = 4,  -- daily start
    @freq_interval = 1,
    @active_start_time = '120000' ;   -- start time 12:00:00

 EXEC msdb.dbo.sp_attach_schedule
   @job_name = N'MakeDailyJob',
   @schedule_name = N'Everyday schedule' ;

 EXEC msdb.dbo.sp_add_jobserver
   @job_name = N'MakeDailyJob',
   @server_name = @@servername ;