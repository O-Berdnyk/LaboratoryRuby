require 'logger'
require 'fileutils'

module MyApplicationBerdnyk
  class LoggerManager
    class << self
      attr_reader :logger

      def initialize_logger(config)
        FileUtils.mkdir_p(directory) unless Dir.exist?(config["directory"])
        
        @logger = Logger.new(File.join(config["directory"], config["files"]["application_log"]))
        @logger.level = Logger.const_get(config["level"].upcase)
      end

      def log_processed_file(file_name)
        @logger.info("Processed file: #{file_name}")
      end

      def log_error(error_message)
        @logger.error("Error: #{error_message}")
      end
    end
  end
end
