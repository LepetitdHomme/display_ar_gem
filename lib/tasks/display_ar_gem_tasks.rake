namespace :display_ar_gem do
	desc "Display ActiveRecordModels"
	task show: :environment do
		require 'display_ar_gem/window'
		window = DisplayArGem::Window.new
		window.show
	end
end
