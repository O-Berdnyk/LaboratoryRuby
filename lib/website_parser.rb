require 'httparty'
require 'mechanize'
require 'yaml'
require 'erb'
require 'fileutils'
require 'concurrent-ruby'
require 'uri'
require 'securerandom'

module MyApplicationBerdnyk
  class SimpleWebsiteParser
    attr_reader :config, :agent, :item_collection

    def initialize(config)
      @config = config
      @agent = Mechanize.new
      @item_collection = ItemCollection.new
    end

    def start_parse
      if check_url_response(@config['web_scraping']['start_page'])
        #LoggerManager.logger.info("Starting parsing from #{@config['web_scraping']['start_page']}")
        page = HTTParty.get(@config['web_scraping']['start_page'])
        parsed_page = Nokogiri::HTML(page.body)

        product_links = extract_products_links(parsed_page)
        #LoggerManager.logger.info("Found #{product_links.size} product links to process.")

        # Використовуємо багатопоточність для парсингу продуктів
        threads = product_links.map do |link|
          Concurrent::Promises.future do
            parse_product_page(link)
          end
        end
        
        # Очікуємо завершення всіх потоків
        threads.each(&:wait!)
      else
        LoggerManager.logger.error("Unable to access start page: #{@config['web_scraping']['start_page']}")
      end
    end

    def extract_products_links(page)
      links = []
      page.css(@config['web_scraping']['product_card_selector']).each do |product|
        relative_link = product['href']
        # Додаємо базову URL-адресу до відносного шляху
        full_url = URI.join(@config['web_scraping']['start_page'], relative_link).to_s
        links << full_url
      end
      links
    end

    def parse_product_page(product_link)
      if check_url_response(product_link)
        # LoggerManager.logger.info("Parsing product page: #{product_link}")
        product_page = HTTParty.get(product_link)
        parsed_product = Nokogiri::HTML(product_page.body)

        product_name = extract_product_name(parsed_product)
        product_category = extract_category_image(parsed_product)
        product_price = extract_product_price(parsed_product)
        product_description = extract_product_description(parsed_product)
        product_image = extract_product_image(parsed_product)

        product_image_name = SecureRandom.uuid
        # Зберігаємо дані про продукт в item_collection
        item = Item.new(name: product_name, category:product_category, price: product_price, description: product_description, image_path: "media_dir/products/"+product_image_name )
        @item_collection.add_item(item)

        # Збереження зображення
        save_product_image(product_image, product_image_name)
      else
        LoggerManager.logger.error("Product page not accessible: #{product_link}")
      end
    end

    def extract_product_name(product)
      product.css(@config['web_scraping']['product_name_selector']).text.strip
    end

    def extract_category_image(product)
      product.css(@config['web_scraping']['product_category_selector'])[1].text.strip
    end

    def extract_product_price(product)
      product.css(@config['web_scraping']['product_price_selector']).text.strip
    end

    def extract_product_description(product)
      product.css(@config['web_scraping']['product_description_selector']).text.strip
    end

    def extract_product_image(product)
      product.css(@config['web_scraping']['product_image_selector']).first['src']
    end

    def save_product_image(image_url, product_name)
      directory = File.join('media_dir', 'products')
      FileUtils.mkdir_p(directory)

      # Створюємо унікальне ім'я файлу для збереження зображення
      file_name = "#{directory}/#{sanitize_filename(product_name)}.jpg"
      File.open(file_name, 'wb') do |f|
        f.write(HTTParty.get(image_url).body)
      end

      # LoggerManager.logger.info("Saved product image: #{file_name}")
    end

    def check_url_response(url)
      begin
        response = HTTParty.get(url)
        response.code == 200
      rescue StandardError => e
        LoggerManager.logger.error("Error accessing URL #{url}: #{e.message}")
        false
      end
    end

    private

    def sanitize_filename(name)
      name.gsub(/[^0-9A-z.\-]/, '_')
    end
  end
end
