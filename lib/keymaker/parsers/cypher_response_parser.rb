module Keymaker
  class CypherResponseParser

    def self.parse(response_body)
      response_body.data.map do |result|
        if response_body.columns.one? && result.first.kind_of?(Hashie::Mash)
          thing_id = result.first.self.split('/').slice(-2,2)
          result.first.data.merge({thing_id[0] + '_id' => thing_id[1].to_i})
        else
          translate_response(response_body, result)
        end
      end
      
    end

    def self.translate_response(response_body, result)
      Hashie::Mash.new(Hash[sanitized_column_names(response_body).zip(result)])
    end

    def self.sanitized_column_names(response_body)
      response_body.columns.map do |column|
        column[/[^\.]+$/]
      end
    end

  end
end
