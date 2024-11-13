module MyApplicationBerdnyk
  class Configurator
    attr_reader :config

    def initialize
      # Ініціалізація конфігураційних параметрів за замовчуванням
      @config = {
        run_website_parser: 0,     # Запуск розбору сайту
        run_save_to_csv: 0,        # Збереження даних в CSV форматі
        run_save_to_json: 0,       # Збереження даних в JSON форматі
        run_save_to_yaml: 0,       # Збереження даних в YAML форматі
        run_save_to_sqlite: 0,     # Збереження даних в базі даних SQLite
        run_save_to_mongo: 0      # Збереження даних в базі даних MongoDB
      }
    end

    def configure(overrides)
      overrides.each do |key, value|
        if @config.key?(key)
          @config[key] = value
        else
          puts "Попередження: '#{key}' не є дійсним конфігураційним параметром."
        end
      end
    end

    def self.available_methods
      new.config.keys
    end
  end
end
