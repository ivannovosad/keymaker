require 'faraday'
require 'faraday_middleware'
require 'hashie'
require 'logger'
require 'active_model'
require 'active_model/validations'
require 'active_model/callbacks'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/conversions'
require 'active_support/hash_with_indifferent_access'

require 'keymaker/match_method'
require 'keymaker/errors'
require 'keymaker/response'
require 'keymaker/parsers/cypher_response_parser'
require 'keymaker/configuration'
require 'keymaker/service'

require 'keymaker/request'

require 'keymaker/requests/batch_request'
require 'keymaker/requests/batch_get_nodes_request'
require 'keymaker/requests/create_node_request'
require 'keymaker/requests/delete_node_request'
require 'keymaker/requests/get_node_request'
require 'keymaker/requests/add_node_to_index_request'
require 'keymaker/requests/remove_node_from_index_request'
require 'keymaker/requests/update_node_properties_request'
require 'keymaker/requests/create_relationship_request'
require 'keymaker/requests/delete_relationship_request'
require 'keymaker/requests/get_relationship_types_request'
require 'keymaker/requests/execute_cypher_request'
require 'keymaker/requests/execute_gremlin_request'
require 'keymaker/requests/traverse_path_request'
require 'keymaker/requests/service_root_request'

require 'keymaker/indexing'
require 'keymaker/serialization'
require 'keymaker/node'

require 'keymaker/railtie' if defined? Rails::Railtie

module Keymaker

  VERSION = "0.1.0"

  class << self
  
    attr_accessor :logger
    
    def service
      @service ||= Keymaker::Service.new(Keymaker::Configuration.new)
    end

    def configure
      @configuration = Keymaker::Configuration.new
      yield @configuration
      @service = Keymaker::Service.new(@configuration)
    end
  
    def configuration
      @configuration
    end
    
    def logger
      @logger ||= Logger.new(ENV['KEYMAKER_LOG'] ? ENV['KEYMAKER_LOG_FILE'] || $stdout : '/dev/null')
    end
    
  end
end
