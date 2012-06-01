# The purpose of this class is to make configuration of third-party dependencies
# more in tune with the 12 factor app (http://12factor.net). Specifically, that
# configuration should be in the environment.
# Heroku uses the environment by default, but that makes configuring locally less
# easy than with dotfiles. So, QuickConfig will load the appropriate dotfile if
# present, and depend on the environment otherwise.

# Use like this:
# QuickConfig.config(:spreedly, 'SPREEDLY_CORE_LOGIN', 'SPREEDLY_CORE_SECRET') do
#   SpreedlyCore.configure(ENV['SPREEDLY_CORE_LOGIN'],
#                          ENV['SPREEDLY_CORE_SECRET'],
#                          SPREEDLY_CORE[Rails.env]['token'])
# end
#
# or
#
# QuickConfig.config(:janrain, 'JANRAIN_API_KEY')
#
# Looks for a file in the project root, e.g. .spreedly, or .janrain in the
# above cases, and loads it to optionally set env vars for local development
#
# e.g.:
#   ENV['SPREEDLY_CORE_LOGIN']  = 'asdfasdf'
#   ENV['SPREEDLY_CORE_SECRET'] = 'fdsafdsa'
#
# Otherwise just defaults to using environment variables. Set your variables
# in your Heroku config to keep them out of your code.

class QuickConfig
  class << self
    # Public: Configure a list of environment variables either by passing
    # through the existing environment variables, or falling back on a dotfile
    # by the name of .#{name}. If the environment variables are not configured
    # after the optional block is passed, print a warning message.
    #
    # name - The name of this configuration.
    # vars - The names of environment variables to configure and require.
    # yield - A block given the chance to fill out the variables and/or
    # perform any resulting framework config.
    def config(name, *vars, &block)
      self.config!(name, *vars, &block)
    rescue => exception
      $stderr.puts exception.message
    end

    # Public: Same as config, but crash if the configuration contract
    # is not fulfilled.
    #
    # name - The name of this configuration.
    # vars - The names of environment variables to configure and require.
    # yield - A block given the chance to fill out the variables and/or
    # perform any resulting framework config.
    def config!(name, *vars)
      Rails.root.join(".#{name}").tap do |local_config|
        load local_config if File.exist?(local_config)
      end

      yield if block_given?

      unless vars.all?{|var|ENV[var].present?}
        message = <<-WARNING
    You must configure your #{name.to_s.titleize} credentials in the following environment variables:
      #{vars.join("\n      ")}
        WARNING
        raise message
      end
    end

    def api(name, *vars)
      $stderr.puts "DEPRECATED. Please call QuickConfig.config"
      QuickConfig.config(name, *vars)
    end

    def mimic_heroku_app(app, *vars)
      config = self.config_for_heroku_app(app)
      vars.each do |key|
        ENV[key] = config[key]
      end
    end

    def config_for_heroku_app(app)
      lines = `heroku config --list -s --app #{app}`.lines
      Hash[lines.map do |line|
        line.chomp.split(/=/, 2)
      end]
    end
  end
end
