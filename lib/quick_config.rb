# Use like this:
# QuickConfig.api(:spreedly, 'SPREEDLY_CORE_LOGIN', 'SPREEDLY_CORE_SECRET') do
#   SpreedlyCore.configure(ENV['SPREEDLY_CORE_LOGIN'],
#                          ENV['SPREEDLY_CORE_SECRET'],
#                          SPREEDLY_CORE[Rails.env]['token'])
# end
#
# or
#
# QuickConfig.api(:janrain, 'JANRAIN_API_KEY')
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
  def self.api(name, *vars)
    Rails.root.join(".#{name}").tap do |local_config|
      load local_config if File.exist?(local_config)
    end

    if vars.all?{|var|ENV[var].present?}
      yield if block_given?
    else
      Rails.logger.warn <<-WARNING
  You must configure your #{name.to_s.titleize} credentials in the following environment variables:
    #{vars.join("\n  ")}
      WARNING
    end
  end
end

