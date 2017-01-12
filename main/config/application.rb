require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'active_job'
require 'mongoid'
#Mongoid.load!(File.expand_path('mongoid.yml', './config'))

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Main
  class Application < Rails::Application
    config.middleware.use Rack::Deflater
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
#    config.time_zone = 'UTC'
    config.time_zone = 'Beijing'
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false

    Time::DATE_FORMATS[:default] = lambda { |date| I18n.l(date) }

    # ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
    #   "#{html_tag}".html_safe
    # end


    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :zh
    # config/application.rb
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}')]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    config.generators do |g|
      g.orm :active_record
    end

    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}')]

    # Plugin
    config.autoload_paths += Dir[Rails.root.join('lib', 'plugins', '{**}')]
    
    # API
    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', 'api', '**', '*')]

    # 
    config.assets.compile = true

    # The default matcher for compiling files includes application.js, application.css and all non-JS/CSS files
    # (this will include all image assets automatically) from app/assets folders including your gems:
    #config.assets.precompile = [/^[a-z0-9\/]*[a-z0-9]\w+.(css|js)$/]
    #config.assets.precompile = %w( *.css *.css.scss *.js )
    #config.assets.precompile = %w( *.png *.gif *.jpg *.jpeg  )

    #config.cache_store = :null_store
    #config.perform_caching = false

#    config.cache_store = :redis_store, 'redis://localhost:7000'
    
    ActiveJob::Base.queue_adapter = :sidekiq
    config.active_job.queue_adapter = :sidekiq
    config.active_record.raise_in_transactional_callbacks = true

    config.filter_parameters += [:password, :password_confirmation]

  end
end
