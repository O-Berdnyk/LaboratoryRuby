require_relative 'configurator'
require_relative 'engine'

configurator = MyApplicationBerdnyk::Configurator.new

# Налаштування конфігураційних параметрів
configurator.configure(
  run_website_parser: 1,     # Запуск розбору сайту
  run_save_to_csv: 1,        # Збереження даних в CSV форматі
  run_save_to_json: 1,       # Збереження даних в JSON форматі
  run_save_to_yaml: 1,       # Збереження даних в YAML форматі
  run_save_to_sqlite: 1,     # Збереження даних в базі даних SQLite
  run_save_to_mongodb: 0      # Включити збереження даних в базі даних SQLite
)

# Вивід поточних конфігураційних параметрів
puts configurator.config

# Вивід доступних конфігураційних ключів
puts MyApplicationBerdnyk::Configurator.available_methods

engine = MyApplicationBerdnyk::Engine.new(configurator)
engine.run

