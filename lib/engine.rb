require_relative 'logger'
require_relative 'item'
require_relative 'config'
require_relative 'item_collection'
require_relative 'website_parser'
require 'yaml'
require 'logger'
require 'sqlite3'
require 'mongo'
require 'sidekiq'
require 'pony'
require 'zip'

module MyApplicationBerdnyk
  class Engine
    attr_accessor :config, :methods_configurator, :logger, :parser, :sql_connector, :config_loader

    def initialize(configurator)
      load_config() 
      @methods_configurator = configurator
    end

    def initialize_logging(logging_config)
      LoggerManager.initialize_logger(logging_config)
      @logger = LoggerManager.logger
      @logger.info("Configuration loaded successfully.")
    end

    def load_config
      system_libs = ['date', 'json']
      libs_dir = File.dirname(__FILE__)
      @config_loader = AppConfigLoader.new
      @config_loader.load_libs(system_libs, libs_dir)

      main_config_file = 'config/default_config.yaml'
      additional_configs_dir = 'config/additional_configs'

      @config = @config_loader.config(main_config_file, additional_configs_dir)
      logging_config = @config_loader.load_logging_config("config/additional_configs/logging_config.yaml");
      initialize_logging(logging_config)
    rescue StandardError => e
      puts e.message
    end

    def run
      connect_to_database
      run_methods(@methods_configurator.config)
      disconnect_from_database
      archive_results
      # ArchiveSender.perform_async
    end

    def run_methods(config_params)
      config_params.each do |method_name, should_run|
        if should_run == 1
          begin
            puts "Attempting to run method: #{method_name}"
            send(method_name)  # Ensure that method_name is correct
            @logger.info("Executed method: #{method_name}")
          rescue NoMethodError
            @logger.error("Method not found: #{method_name}")
          rescue StandardError => e
            @logger.error("Error executing #{method_name}: #{e.message}")
          end
        else
          @logger.info("Skipping method: #{method_name} (not enabled)")
        end
      end
    end

    private

    def connect_to_database
      @sql_connector = DatabaseConnector.new(config)
      @sql_connector.connect_to_database
    rescue StandardError => e
      @logger.error("Failed to connect to database: #{e.message}")
    end

    def disconnect_from_database
      @sql_connector.close_connection
    rescue StandardError => e
      @logger.error("Error disconnecting from database: #{e.message}")
    end

    def run_website_parser
      @parser = SimpleWebsiteParser.new(@config)
      @parser.start_parse
      @logger.info("Website parsing executed")
    end

    def run_save_to_csv
      @parser.item_collection.save_to_csv("output/products.csv")
      @logger.info("Data saved to CSV")
    end

    def run_save_to_json
      @parser.item_collection.save_to_json("output/products.json")
      @logger.info("Data saved to JSON")
    end

    def run_save_to_yaml
      @parser.item_collection.save_to_yml("output/products.yml")
      @logger.info("Data saved to YAML")
    end

    def save_items_to_mongo
  # Перевіряємо, чи є колекція "products". Якщо немає, створюємо її
  @db_connector.db.create_collection(:products) unless @db_connector.db.collection(:products)

  # Додаємо кожен елемент з item_collection в MongoDB
  @parser.item_collection.items.each do |item|
    # Створюємо хеш для кожного елемента
    item_data = {
      name: item.name,
      price: item.price,
      category: item.category,
      image_path: item.image_path,
      description: item.description
    }
    
    # Вставляємо кожен елемент в колекцію products
    @db_connector.db[:products].insert_one(item_data)
  end
end



    def run_save_to_sqlite
      begin
        if @sql_connector.db.is_a?(SQLite3::Database)
          db = @sql_connector.db
    
          db.execute <<-SQL
            CREATE TABLE IF NOT EXISTS products (
              id INTEGER PRIMARY KEY,
              name TEXT,
              price TEXT,
              category TEXT,
              image_path TEXT,
              description TEXT
            );
          SQL
  
          @parser.item_collection.items.each do |item|
            db.execute "INSERT INTO products (name, price, category, image_path, description) VALUES (?, ?, ?, ?, ?)", 
                       [item.name, item.price, item.category, item.image_path, item.description]
          end
    
          MyApplicationBerdnyk::LoggerManager.log_processed_file("Data saved to SQLite")
        else
          raise "Not a valid SQLite connection"
        end
      rescue SQLite3::Exception => e
        MyApplicationBerdnyk::LoggerManager.log_processed_file("Error saving data to SQLite: #{e.message}")
      end
    end

    # Метод для збереження даних в MongoDB
    
    def archive_results
      zipfile_name = 'results.zip'
    
      # Перевірка, чи не порожні директорії
      media_files = Dir['media_dir/**/*'].select { |file| File.file?(file) }
      output_files = Dir['output/**/*'].select { |file| File.file?(file) }
    
      if media_files.empty? && output_files.empty?
        @logger.info("No files to archive in media_dir and output directories.")
        return
      end
    
      # Створення zip-архіву
      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        # Додавання файлів з `media_dir`
        media_files.each do |file|
          entry_name = file.sub('media_dir/', '')  # Створення відносного шляху в архіві
          zipfile.add(entry_name, file) unless zipfile.find_entry(entry_name)
        end
    
        # Додавання файлів з `output`
        output_files.each do |file|
          entry_name = file.sub('output/', '')  # Створення відносного шляху в архіві
          zipfile.add(entry_name, file) unless zipfile.find_entry(entry_name)
        end
      end
    
      @logger.info("Results archived to #{zipfile_name}")
    rescue StandardError => e
      @logger.error("Failed to archive results: #{e.message}")
    end
    

  end
end
