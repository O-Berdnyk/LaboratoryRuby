require 'sqlite3'
require 'mongo'
require 'yaml'
require 'logger'

module MyApplicationBerdnyk
  class DatabaseConnector
    attr_reader :db

    def initialize(config)
      @config = config
      @db = nil
    end

    # Метод для підключення до бази даних на основі конфігурації
    def connect_to_database
      case @config['database_config']['database_type']
      when 'sqlite'
        connect_to_sqlite
      when 'mongodb'
        connect_to_mongodb
      else
        raise "Unsupported database type: #{@config['database_config']['database_type']}"
      end
    end

    # Метод для закриття з'єднання з базою даних
    def close_connection
      if @db
        case @config['database_config']['database_type']
        when 'sqlite'
          @db.close
        when 'mongodb'
          # Для MongoDB з'єднання не потребує явного закриття.
        end
        @db = nil
      else
        puts "No active database connection to close."
      end
    end

    private

    # Підключення до SQLite
    def connect_to_sqlite
      puts "DBCONG"
      puts @config['database_config']

      db_file = @config['database_config']['sqlite_database']['db_file']
      timeout = @config['database_config']['sqlite_database']['timeout'] || 5000
      pool_size = @config['database_config']['sqlite_database']['pool_size'] || 5

      FileUtils.mkdir_p(File.dirname(db_file)) unless Dir.exist?(File.dirname(db_file))
      
      begin
        @db = SQLite3::Database.new(db_file)
        @db.busy_timeout = timeout
        puts "Connected to SQLite database at #{db_file} with timeout: #{timeout} and pool_size: #{pool_size}"
      rescue SQLite3::Exception => e
        puts "Error connecting to SQLite database: #{e.message}"
        raise e
      end
    end

    # Підключення до MongoDB
    def connect_to_mongodb
      uri = @config['database_config']['mongodb']['uri']
      db_name = @config['database_config']['mongodb']['db_name']

      begin
        client = Mongo::Client.new(uri)
        @db = client[db_name]
        puts "Connected to MongoDB at #{uri} with database: #{db_name}"
      rescue Mongo::Error => e
        puts "Error connecting to MongoDB: #{e.message}"
        raise e
      end
    end
  end
end
