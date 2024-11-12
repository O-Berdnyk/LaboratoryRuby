require 'csv'

module MyApplicationBerdnyk
  class ItemCollection
    attr_accessor :items

    def initialize
      @items = []
      MyApplicationBerdnyk::LoggerManager.log_processed_file("ItemCollection initialized")
    end

    # Зберігає інформацію у текстовому файлі
    def save_to_file(file_path)
      File.open(file_path, 'w') do |file|
        file.puts items.map(&:to_s)
      end
      MyApplicationBerdnyk::LoggerManager.log_processed_file("Saved items to file: #{file_path}")
    end

    # Зберігає інформацію у форматі JSON
    def save_to_json(file_path)
      File.open(file_path, 'w') do |file|
        file.write(JSON.pretty_generate(items.map(&:to_h)))
      end
      MyApplicationBerdnyk::LoggerManager.log_processed_file("Saved items to JSON: #{file_path}")
    end

    # Зберігає інформацію у форматі CSV
    def save_to_csv(file_path)
      CSV.open(file_path, 'w') do |csv|
        csv << Item.new.to_h.keys  # Заголовки
        items.each { |item| csv << item.to_h.values }
      end
      MyApplicationBerdnyk::LoggerManager.log_processed_file("Saved items to CSV: #{file_path}")
    end

    # Зберігає інформацію у форматі YAML
    def save_to_yml(directory)
      FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
      items.each_with_index do |item, index|
        # Генерація порядкового номера для файлу
        file_name = "#{index + 1}.yml" # додаємо 1 до індексу, щоб номер починався з 1
        File.open("#{directory}/#{file_name}", 'w') do |file|
          file.write(item.to_h.to_yaml)
        end
        MyApplicationBerdnyk::LoggerManager.log_processed_file("Saved item to YAML: #{file_name}")
      end
    end

    # Додає товар до колекції
    def add_item(item)
      items << item
      MyApplicationBerdnyk::LoggerManager.log_processed_file("Added item: #{item.name}")
    end

    # Видаляє товар з колекції
    def remove_item(item)
      items.delete(item)
      MyApplicationBerdnyk::LoggerManager.log_processed_file("Removed item: #{item.name}")
    end

    # Видаляє всі товари з колекції
    def delete_items
      items.clear
      MyApplicationBerdnyk::LoggerManager.log_processed_file("Deleted all items")
    end

    # Генерація фіктивних товарів
    def generate_test_items(count)
      count.times { add_item(Item.generate_fake) }
      MyApplicationBerdnyk::LoggerManager.log_processed_file("#{count} test items generated")
    end

    # Ітерування по товарам
    include Enumerable

    def each(&block)
      items.each(&block)
    end

    # Метод для виводу всіх товарів
    def method_missing(method_name, *args, &block)
      if method_name == :show_all_items
        puts items.map(&:info).join("\n")
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name == :show_all_items || super
    end

    # Інформація про клас
    def self.class_info
      "Class: #{self}, Version: 1.0"
    end

    # Метод для підрахунку кількості об'єктів
    def self.object_count
      @object_count ||= 0
      @object_count += 1
      @object_count
    end
  end
end