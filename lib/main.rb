require_relative 'config'
require_relative 'logger'

# Ініціалізація екземпляра AppConfigLoader
config_loader = AppConfigLoader.new

# Автоматичне підключення системних та локальних бібліотек
system_libs = ['date', 'json'] # Додаємо необхідні системні бібліотеки
libs_dir = File.dirname(__FILE__) # Директорія з локальними бібліотеками
config_loader.load_libs(system_libs, libs_dir)

main_config_file = 'config/default_config.yaml' # Шлях до основного конфігураційного файлу
additional_configs_dir = 'config/additional_configs' # Директорія з додатковими конфігураціями

config_loader.config(main_config_file, additional_configs_dir)

# Перевірка завантаження конфігурацій - виведення у форматі JSON
config_loader.pretty_print_config_data

logging_config = config_loader.load_logging_config('config/additional_configs/logging_config.yaml')

# Ініціалізуємо логер
MyApplicationBerdnyk::LoggerManager.initialize_logger(logging_config)

# Логування подій
MyApplicationBerdnyk::LoggerManager.log_processed_file('example.txt')
MyApplicationBerdnyk::LoggerManager.log_error('An error occurred')

