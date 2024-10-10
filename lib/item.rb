require 'logger'
require 'faker'

module MyApplicationBerdnyk
  class Item
    attr_accessor :name, :price, :description, :category, :image_path

    # Конструктор класу
    def initialize(params = {}, &block)
      # Встановлюємо значення атрибутів за замовчуванням
      @name = params.fetch(:name, "Unnamed Item")
      @price = params.fetch(:price, 0.0)
      @description = params.fetch(:description, "No description")
      @category = params.fetch(:category, "Uncategorized")
      @image_path = params.fetch(:image_path, "default_image.png")

      # Логуємо ініціалізацію об'єкта
      MyApplicationBerdnyk::LoggerManager.log_processed_file("Item initialized: #{@name}")

      # Якщо передано блок, обробляємо його
      yield self if block_given?
    rescue StandardError => e
      MyApplicationBerdnyk::LoggerManager.log_error("Initialization error: #{e.message}")
    end

    # Перетворення об'єкта на рядок
    def to_s
      attributes.map { |attr| "#{attr}: #{send(attr)}" }.join(", ")
    end

    # Перетворення об'єкта на хеш
    def to_h
      attributes.each_with_object({}) { |attr, hash| hash[attr] = send(attr) }
    end

    # Інспекція об'єкта
    def inspect
      "#<#{self.class}: #{to_s}>"
    end

    # Метод для зміни атрибутів через блок
    def update(&block)
      yield self if block_given?
    rescue StandardError => e
      MyApplicationBerdnyk::LoggerManager.log_error("Update error: #{e.message}")
    end

    # Псевдонім для методу to_s
    alias_method :info, :to_s

    # Генерація фіктивних даних
    def self.generate_fake
      new(
        name: Faker::Commerce.product_name,
        price: Faker::Commerce.price,
        description: Faker::Lorem.sentence,
        category: Faker::Commerce.department,
        image_path: Faker::Avatar.image
      )
    end

    # Реалізація модуля Comparable
    include Comparable

    def <=>(other)
      price <=> other.price
    end

    private

    # Список атрибутів
    def attributes
      [:name, :price, :description, :category, :image_path]
    end
  end
end
