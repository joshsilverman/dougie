
desc "backup to s3"
task :cron => :environment do
    HerokuS3Backup.backup
end