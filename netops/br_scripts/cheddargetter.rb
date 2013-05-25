#!/usr/local/bin/ruby

# ---
#BR_description: Synchronize account/billing data between provisioning and cheddargetter
#BR_startup: disabled____foreach_provisioning=always
#BR__END: 
# ---

require 'rubygems'
require 'mysql'
require 'cheddargetter_client_ruby'

# configuration line from prime (SQL) -- for reference
#INSERT INTO `systems` VALUES (7,'CheddarGetter Gateway',NOW(),NOW(),'disabled,user=user@domain.bad,pass=XXXX','','cheddargetter',NULL);

# ---
STDOUT.sync = true

# ---
rdsn=dbruser=dbrpass=system_id=cheddargetter_plancode=nil
ENV['BR_PARAMETERS'].split(',').each do |kv|
    next unless kv =~ /^([^=]*)=(.*)$/
    rdsn = $2 if $1.eql?'dsn';
    dbruser = $2 if $1.eql?'dbuser';
    dbrpass = $2 if $1.eql?'dbpass';
    system_id = $2 if $1.eql?'system_id';
    cheddargetter_plancode = $2 if $1.eql?'cheddargetter_plancode';
end

# ---
product_code = ENV['BR_ENVIRONMENT'].tr('a-z','A-Z') + ':' + system_id.to_s;

# ---
def open_db(dsn,user,pass)
    dbh = nil
    # --- break up dsn
    # ref: rdsn='dbi:mysql:go3_development:127.0.0.1:3306'
    _,_,db,host,port=dsn.split(':')
    begin
        # ref: def real_connect(host=nil, user=nil, passwd=nil, db=nil, port=nil, socket=nil, flag=nil)
        dbh = Mysql.new(host,user,pass,db,port);
        $stdout.puts "Connected to MySQL version: " + dbh.get_server_info
#    rescue e
#    rescue Mysql::Error => e -- doesn't work so well
    rescue
        # well so much for that!
        $stderr.puts "Could not connect to dsn [#{dsn}]\n";
#        $stderr.puts "Error code: #{e.errno}"
#        $stderr.puts "Error message: #{e.error}"
#        $stderr.puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
        exit -1
#    ensure
#    dbh.close if dbh
    end
    return dbh
end

def open_client(code)
    # --- open local db handle
    dbh = open_db(ENV['BR_DSN'], ENV['BR_DBUSER'], ENV['BR_DBPASS']);
    exit -1 if dbh.nil?

    # --- read config
    vars = {}
    begin
        res = dbh.query("SELECT id, name, system_type, access FROM systems WHERE system_type = 'cheddargetter'");
        res.each do |row|
            access = row[3]
            next if access.nil?
            access.split(',').each do |kv|
                vars[$1] = $2 if kv=~/^([^=]*)=(.*)$/ or kv=~/^(.*)()$/
            end
            if not vars['disabled'].nil?
                vars = {}
                next
            end
            puts "found 1 cheddargetter config: " << vars.inspect
        end
        res.free
    rescue
        $stderr.puts "Error reading DB row\n"
        exit -1
    end
    dbh.close 

    # --- 
    return nil if vars['user'].nil?

    # ---
    puts "connecting with: " << vars.inspect
    client = CheddarGetter::Client.new(
        :product_code => code,
        :username => vars['user'],
        :password => vars['pass'])
    if client.nil?
        $stderr.puts "Error connnecting to ChedderGetter\n"
        exit -1
    end
    return client
end

# ---
dbh = open_db(rdsn,dbruser,dbrpass)
lives = 30
while lives>0
    did_something = false
    new_customer = nil
    if not cheddargetter_plancode.nil?
        begin
            res = dbh.query("SELECT a.id, u.name, u.last_name, u.email_address FROM accounts a, users u WHERE a.owner_id=u.id AND a.transcription_options IS NULL LIMIT 1");
            if (res.num_rows==1)
                # ref: res.each_hash(...)
                res.each do |row|
                    new_customer = {
                        :code => row[0],
                        :firstName => row[1],
                        :lastName => row[2],
                        :email => row[3],
                        :subscription => {
                            :planCode => cheddargetter_plancode
                            }
                        }
                    new_customer[:firstName] = '[none]' if new_customer[:firstName].nil?
                    new_customer[:firstName] = new_customer[:firstName][0,20]
                    new_customer[:lastName] = '[none]' if new_customer[:lastName].nil?
                    new_customer[:email] = 'spam@cheddargetter.com'
                    puts 'new_customer=' << new_customer.inspect
                end
            else
                puts "#{res.num_rows} new customers"
            end
            res.free
        rescue
            $stderr.puts "Error reading DB row\n"
            exit -1
        end
    end
    if not new_customer.nil? and not (client = open_client(product_code)).nil?
        puts 'opened client=' << client.inspect
        response = client.new_customer(new_customer)
#response = client.delete_all_customers
#puts 'deleted old' 
#exit 0;
        if response.valid?
            puts 'created record in billing: ' << new_customer.inspect
            begin
                dbh.query("UPDATE accounts SET transcription_options='1' WHERE id=#{new_customer[:code]}");
                puts "#{dbh.affected_rows} row(s) updated"
                did_something = true
            rescue
                $stderr.puts "Error updating new customer record DB row\n"
                exit -1
            end
        else
            puts "\tERROR: #{response.error_messages.inspect}"
            $stderr.puts "\tERROR: #{response.error_messages.inspect}"
            exit -1
        end
    end
    next if did_something
    sleep Integer(ENV['BR_SLEEP_LONG'])
    lives = lives-1
end

# ---
dbh.close if dbh

