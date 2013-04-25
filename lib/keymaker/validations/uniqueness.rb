module Keymaker
  module Node
    module Validations
      
      class UniquenessValidator < ActiveModel::EachValidator
        
        def initialize(options = {})
          if options[:conditions] && !options[:conditions].respond_to?(:call)
            raise ArgumentError, "#{options[:conditions]} was passed as :conditions but is not callable. " \
                                 "Pass a callable instead: `conditions: -> { where(approved: true) }`"
          end
          super({ case_sensitive: true }.merge!(options))     
        end
        
        def setup(klass)
          @klass = klass
        end
        
        def validate_each(record, attribute, value)
          Keymaker::logger.info("Keymaker:Uniqueness for #{attribute} with #{value}")
          finder_class = find_finder_class_for(record)
          value = finder_class.find_by_index({attribute: attribute, value: value})
          unless value.nil?
            error_options = options.except(:case_sensitive, :scope, :conditions)
            error_options[:value] = value
  
            record.errors.add(attribute, :taken, error_options)
          end  
        end
        
      protected
      
        def find_finder_class_for(record) #:nodoc:
          class_hierarchy = [record.class]
  
          while class_hierarchy.first != @klass
            class_hierarchy.unshift(class_hierarchy.first.superclass)
          end
  
          class_hierarchy.detect { |klass| !klass.abstract_class? }
        end
      end
      module ClassMethods
        def validates_uniqueness_of(*attr_names)
          validates_with UniquenessValidator, _merge_attributes(attr_names)
        end      
      end 
    end
  end
end