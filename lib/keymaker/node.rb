require 'forwardable'

module Keymaker

  module Node

    def self.included(base)

      base.class_eval do
        extend ActiveModel::Callbacks
        extend ActiveModel::Naming
        include ActiveModel::MassAssignmentSecurity
        include ActiveModel::Validations
        include ActiveModel::Validations::Callbacks
        include ActiveModel::Conversion
        

        include Keymaker::Indexing
        include Keymaker::Serialization
        include Keymaker::Node::Validations
        
        extend Keymaker::Node::ClassMethods
        include Keymaker::Node::InstanceMethods

        attr_accessor :new_node
        attr_accessor :node_id
        attr_protected :created_at, :updated_at

      end
      base.define_model_callbacks :create, :update
      
      base.after_save :update_indices
      base.after_create :add_node_type_index

      base.class_attribute :property_traits
      base.class_attribute :indices_traits

      base.property_traits = {}
      base.indices_traits = {}

      #base.property :active_record_id, Integer
      base.property :node_id, Integer
      base.property :created_at, DateTime
      base.property :updated_at, DateTime
      base.property :type, String

    end

    module ClassMethods
      extend Forwardable

      def_delegator :Keymaker, :service, :neo_service

      def properties
        property_traits.keys
      end

      def property(attribute,type=String, o={})
        property_traits[attribute] = type
        #Keymaker.logger.info "Keymaker::Node#property handling #{attribute}"
        attr_accessor attribute
      end
      
      def create(attributes)
        new(attributes).save
      end

      # find using the index, if index_name is not provided, the class pluralized is 
      # assumed (i.e. User model will search in Users index)
      # :index_name (optional) set the lucene index name (i.e. User), defaults to class name capitalized and pluralized (i.e. Users)
      # :attribute set the attribute you wish to have checked (i.e. 'email') and…
      # :value to find with (i.e. 'myemail@example.com'
      def find_by_index(o={})
        o[:index_name] = o[:index_name] ||= self.name.pluralize.downcase
        o[:attribute] = o[:attribute] ||= 'mustDefineAttribute'
        o[:value] = o[:value] ||= 'mustDefineValue'
        msg = ''
        result = nil
        begin
          result = self.find_by_cypher("START n=node:#{o[:index_name]}(#{o[:attribute]}='#{o[:value]}') RETURN n")
        rescue Exception => msg
          #Keymaker.logger.info "Node#find_by_index: not found, exception is: #{msg}"
          nil
        end
        result.blank? ? nil : result
      end
      
      def find_by_cypher(query, params={})
        find_all_by_cypher(query, params).first
      end

      def find_all_by_cypher(query, params={})
        results = neo_service.execute_cypher(query, params).map{ |node| wrap(node) }
        #Keymaker::logger.info("Keymaker::Node#find_all_by_cypher results: #{results}")
        results
      end

      def find!(node_id)
        node = neo_service.get_node(node_id)
        if node.present?
          new(node.slice(*properties)).tap do |neo_node|
            neo_node.node_id = node.neo4j_id
            neo_node.new_node = false
          end
        end
      end
      def find(node_id)
        begin
          self.find!(node_id)
        rescue Error
          nil
        end
      end
      
      def wrap(node_attrs)
        if node_attrs.present?
          if node_attrs.type.present?
            klass = node_attrs.type.constantize
          else
            klass = self     
          end
        end
        klass.new(node_attrs).tap do |node|
          node.new_node = false
          node.node_id = node_attrs.node_id
          node.process_attrs(node_attrs) if node_attrs.present?
        end
      end
      def first(conditions)
        
      end
      
      # for uniquness validation
      def abstract_class?
        false
      end
    end

    module InstanceMethods

      def initialize(attrs = {})
        self.new_node = true
        process_attrs(attrs) if attrs.present?
      end

      def new_node?
        new_node
      end

      def neo_service
        self.class.neo_service
      end

      def sanitize(attrs)
        #Keymaker::logger.info("Keymaker::Node#sanitize before: #{attrs.to_yaml}")
        serializable_hash(except: :node_id).merge(attrs.except('node_id')).reject {|k,v| v.blank?}
      end

      def save(options={})
        create_or_update(options)
      end

      def create_or_update(options={})
        if perform_validations(options)
          run_callbacks :save do
            new_node? ? create : update(attributes)
          end
        end
      end

      def create
        run_callbacks :create do
          neo_service.create_node(sanitize(attributes.merge(type: self.class.name))).on_success do |response|
            self.node_id = response.neo4j_id
            self.new_node = false
          end
          self
        end
      end

      # note that update_node_properties is destructive in that it will remove any attribute not
      # defined in attrs from the present node!
      def update(attrs)
        process_attrs(sanitize(attrs.merge(updated_at: Time.now.utc.to_i, type: self.class.name)))
        neo_service.update_node_properties(node_id, sanitize(attributes))
      end
      
      def update_attribute(attr, val)
        update({attr => val})
      end
      
      def add_node_type_index
        neo_service.add_node_to_index('nodes', 'node_type', self.class.model_name, node_id)
      end

      def persisted?
        node_id.present?
      end

      def to_key
        persisted? ? [node_id] : nil
      end
      
      def valid?(context = nil)
        context ||= (new_node? ? :create : :update)
        output = super(context)
        errors.empty? && output
      end
      
      def [](v)
        send("#{v}")
      end
      
      protected
      
      def perform_validations(options={})
        options[:validate] == false || valid?(options[:context])
      end
    end

  end

end
