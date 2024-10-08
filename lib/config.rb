require 'yaml'
require 'erb'

class AppConfigLoader
  attr_reader :config_data, :loaded_libs

  def initialize
    @config_data = {}
    @loaded_libs = []
  end

  # Метод для завантаження конфігураційних даних з YAML-файлів
  def config(main_config_file, additional_configs_dir)
    load_default_config(main_config_file)
    load_config(additional_configs_dir)

    # Якщо передано блок, обробляємо дані
    yield @config_data if block_given?
    
    @config_data
  end

  def load_logging_config(logging_file)
    if File.exist?(logging_file)
      config = YAML.load_file(logging_file)
      config['logging'] || raise("Logging configuration not found in #{logging_file}")
      
    else
      puts "Logging config file not found: #{logging_file}"
      nil
    end
  end
  
  # Метод для виведення даних конфігурації у форматі JSON для зручного перегляду
  def pretty_print_config_data
    puts JSON.pretty_generate(@config_data)
  end

  # Метод для автоматичного підключення бібліотек
  def load_libs(system_libs = [], libs_dir = 'libs')
    # Підключаємо системні бібліотеки
    system_libs.each do |lib|
      require lib
      @loaded_libs << lib unless @loaded_libs.include?(lib)
    end

    # Підключаємо локальні бібліотеки з директорії
    Dir.glob(File.join(libs_dir, '**', '*.rb')).each do |file|
      # Підключаємо лише непідключені файли
      unless @loaded_libs.include?(file)
        require_relative file
        @loaded_libs << file
      end
    end
  end

  private

  # Метод для завантаження основного конфігураційного файлу
  def load_default_config(file)
    config_content = File.read(file)
    erb_result = ERB.new(config_content).result
    @config_data.merge!(YAML.safe_load(erb_result, permitted_classes: [Symbol]))
  end

  # Метод для завантаження всіх YAML-файлів із вказаної директорії
  def load_config(dir)
    Dir.glob(File.join(dir, '*.yaml')).each do |file|
      config_content = File.read(file)
      erb_result = ERB.new(config_content).result
      @config_data.merge!(YAML.safe_load(erb_result, permitted_classes: [Symbol]))
    end
  end
end
