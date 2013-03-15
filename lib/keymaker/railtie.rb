require 'rails'

class Railtie < Rails::Railtie
  initializer 'Rails logger' do
    Keymaker.logger = Rails.logger
  end
  rake_tasks do
    load "keymaker/rails_tasks.rb"
  end
end
