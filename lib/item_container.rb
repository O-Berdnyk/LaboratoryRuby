module MyApplicationBerdnyk
  module ItemContainer
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module ClassMethods
      def class_info
        "Class: #{self}, Version: 1.0"
      end

      def object_count
        @object_count ||= 0
        @object_count += 1
        @object_count
      end
    end

    module InstanceMethods
      def add_item(item)
        items << item
        MyApplicationBerdnyk::LoggerManager.log_processed_file("Added item: #{item.name}")
      end

      def remove_item(item)
        items.delete(item)
        MyApplicationBerdnyk::LoggerManager.log_processed_file("Removed item: #{item.name}")
      end

      def delete_items
        items.clear
        MyApplicationBerdnyk::LoggerManager.log_processed_file("Deleted all items")
      end

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
    end
  end
end
