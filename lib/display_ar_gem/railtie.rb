require 'rails/railtie'
require 'display_ar_gem/window'
require 'display_ar_gem/model_fetcher'

module DisplayArGem
	class Railtie < Rails::Railtie
		rake_tasks do
			load 'tasks/display_ar_gem_tasks.rake'
		end
	end
end
