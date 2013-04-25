module Keymaker
  module Node
    module Validations
      extend ActiveSupport::Concern
      include ActiveModel::Validations

    end
  end
end

require "keymaker/validations/uniqueness"