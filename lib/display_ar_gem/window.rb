require 'gosu'

module DisplayArGem
	class Window < Gosu::Window
		THROTTLE_INTERVAL = 3000

		def initialize
			super 800, 600
			self.caption = "ActiveRecord Models"

			@font = Gosu::Font.new(12)

			@models_data = DisplayArGem::ModelFetcher.fetch
			@last_draw_time = Gosu.milliseconds
			@text_buffer = Gosu.render(800, 600) do
				draw_text(0, 0, "Initializing...")
      end
		end

		def draw
			@text_buffer.draw(0, 0, 0)

			@models_data[:models].each_with_index do |model, model_index|
				draw_text(10, 20 + model_index * 20, model.name)

				@models_data[:associations][model.name].each_with_index do |assoc, assoc_index|
					draw_text(150, 20 + (model_index + assoc_index) * 20, "#{model} -> #{assoc[:name]} (#{assoc[:type]})")
				end
			end
		end

		def update
			current_time = Gosu.milliseconds
			if current_time - @last_draw_time >= THROTTLE_INTERVAL
				@last_draw_time = current_time
			end
		end

		def draw_text(x, y, text)
			@font.draw_text(text, x, y, 1)
		end

		def needs_cursor?
			true
		end
	end
end
