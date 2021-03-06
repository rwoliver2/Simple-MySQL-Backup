#!/usr/bin/env ruby

require "rubygems"
require "yaml"
require "mysql"

puts "Simple MySQL Backup Script Version 1.11"
puts "Copyright (C) 2009 OCS Solutions, Inc. - All Rights Reserved"
puts "This software is licensed under the GPL version 2."
puts

# Check for /etc/mysql-backup.yml
unless File.exists?("/etc/mysql-backup.yml")
  puts "/etc/mysql-backup.yml not found.  Please copy sample mysql-backup.yml to /etc and edit it."
  exit
end

# Read in the config file and setup config vars
yaml_config = YAML.load_file("/etc/mysql-backup.yml")
mysql_username = yaml_config["username"]
mysql_password = yaml_config["password"]
backup_location = yaml_config["location"]

begin
  # Try to connect to MySQL
  dbh = Mysql.real_connect("localhost", mysql_username, mysql_password, "mysql")
  puts "Connected to MySQL Server @ localhost version #{dbh.get_server_info}"
  puts "Obtaining list of databases..."
  begin
    result = dbh.query("SHOW DATABASES")
  rescue
    puts "Error: Could not obtain list of databases.  Are you trying to use a user other than root?"
    exit
  end
rescue Mysql::Error => e
  puts "Could not connect to MySQL using information in /etc/mysql-backup.yml!"
  puts "Error encountered: #{e.errno} - #{e.error}"
  exit
ensure
  dbh.close if dbh
end

# If we get to this point, result should have a list of the dbs
# Step through each db and make the backup
puts
while row = result.fetch_row do
  print "Backing up database [#{row}]"
  location_db = "#{backup_location}/#{row}.sql"
  `mysqldump -e --delayed-insert -u #{mysql_username} #{row} > #{location_db}`
  print ", now compressing dump file #{row}.sql"
  `rm -f #{location_db}.gz`
  `gzip #{location_db}`
  print " complete.\n"
end

puts
puts "Backup complete."

result.free
