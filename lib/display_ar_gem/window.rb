=begin

{
  "ActionText::RichText"=>[
    {:name=>:record, :type=>:belongs_to, :class_name=>"Polymorphic (record)"},
    {:name=>:embeds_attachments, :type=>:has_many, :class_name=>"ActiveStorage::Attachment"},
    {:name=>:embeds_blobs, :type=>:has_many, :class_name=>"Through (embeds_blobs)"}
  ],
  "ActionText::EncryptedRichText"=>[
    {:name=>:record, :type=>:belongs_to, :class_name=>"Polymorphic (record)"},
    {:name=>:embeds_attachments, :type=>:has_many, :class_name=>"ActiveStorage::Attachment"},
    {:name=>:embeds_blobs, :type=>:has_many, :class_name=>"Through (embeds_blobs)"}
  ],
  "ActiveStorage::VariantRecord"=>[
    {:name=>:blob, :type=>:belongs_to, :class_name=>"ActiveStorage::Blob"},
    {:name=>:image_attachment, :type=>:has_one, :class_name=>"ActiveStorage::Attachment"},
    {:name=>:image_blob, :type=>:has_one, :class_name=>"Through (image_blob)"}
  ],
  "ActiveStorage::Blob"=>[
    {:name=>:variant_records, :type=>:has_many, :class_name=>"ActiveStorage::VariantRecord"},
    {:name=>:preview_image_attachment, :type=>:has_one, :class_name=>"ActiveStorage::Attachment"},
    {:name=>:preview_image_blob, :type=>:has_one, :class_name=>"Through (preview_image_blob)"},
    {:name=>:attachments, :type=>:has_many, :class_name=>"ActiveStorage::Attachment"}
  ],
  "ActiveStorage::Attachment"=>[
    {:name=>:record, :type=>:belongs_to, :class_name=>"Polymorphic (record)"},
    {:name=>:blob, :type=>:belongs_to, :class_name=>"ActiveStorage::Blob"}
  ],
  "ActionMailbox::InboundEmail"=>[
    {:name=>:raw_email_attachment, :type=>:has_one, :class_name=>"ActiveStorage::Attachment"},
    {:name=>:raw_email_blob, :type=>:has_one, :class_name=>"Through (raw_email_blob)"}
  ],
  "TaskLabel"=>[
    {:name=>:task, :type=>:belongs_to, :class_name=>"Task"},
    {:name=>:label, :type=>:belongs_to, :class_name=>"Label"}
  ],
  "Task"=>[
    {:name=>:user, :type=>:belongs_to, :class_name=>"User"},
    {:name=>:task_labels, :type=>:has_many, :class_name=>"TaskLabel"},
    {:name=>:labels, :type=>:has_many, :class_name=>"Through (labels)"}
  ],
  "Label"=>[
    {:name=>:user, :type=>:belongs_to, :class_name=>"User"},
    {:name=>:task_labels, :type=>:has_many, :class_name=>"TaskLabel"},
    {:name=>:tasks, :type=>:has_many, :class_name=>"Through (tasks)"}
  ],
  "User"=>[
    {:name=>:tasks, :type=>:has_many, :class_name=>"Task"},
    {:name=>:labels, :type=>:has_many, :class_name=>"Label"}
  ]
}

=end


module DisplayArGem
  class Window < Gosu::Window
    def initialize
      super 800, 600
      self.caption = "Models and Associations"
      @background_color = Gosu::Color::WHITE
      @model_color = Gosu::Color::GRAY
      @text_color = Gosu::Color::BLACK
      @assoc_color = Gosu::Color::RED
      @highlight_color = Gosu::Color::YELLOW
      @font = Gosu::Font.new(20)
      @zoom_factor = 1.0
      @offset_x = 0
      @offset_y = 0
      @dragging = false
      @last_mouse_x = 0
      @last_mouse_y = 0

      @models_data = DisplayArGem::ModelFetcher.fetch
      @positions = calculate_positions(@models_data[:models])

      @selected_model = nil
    end

    def calculate_positions(models)
      positions = {}
      x, y = 50, 50
      spacing_x, spacing_y = 150, 70
      max_width = width - 100
      models.each do |model|
        if x > max_width
          x = 50
          y += spacing_y
        end
        positions[model.to_s] = { x: x, y: y }
        x += spacing_x
      end
      positions
    end

    def draw
      Gosu.draw_rect(0, 0, width, height, @background_color)
      draw_models
      draw_associations
    end

    def draw_models
      @positions.each do |model, pos|
        color = model == @selected_model ? @highlight_color : @model_color
        draw_model(model, pos[:x], pos[:y], color)
      end
    end

    def draw_model(model, x, y, color = @model_color)
      width = (100 * @zoom_factor).round
      height = (50 * @zoom_factor).round
      Gosu.draw_rect((x * @zoom_factor + @offset_x).round, (y * @zoom_factor + @offset_y).round, width, height, color)
      draw_text(model.to_s.split("::").last, (x * @zoom_factor + @offset_x + width / 2).round, (y * @zoom_factor + @offset_y + height / 2).round)
    end

    def draw_text(text, x, y)
      @font.draw_text(text, x - @font.text_width(text) / 2, y - 10, 1, 1.0, 1.0, @text_color)
    end

    def draw_associations
      @models_data[:associations].each do |model, associations|
        # binding.pry
        start_pos = @positions[model]
        associations.each do |assoc|
          class_name = assoc[:class_name].split(' ').first
          end_pos = @positions[class_name]
          if start_pos && end_pos
            color = (model == @selected_model || class_name == @selected_model) ? @highlight_color : @assoc_color
            draw_arrow(
              (start_pos[:x] * @zoom_factor + @offset_x + 50).round,
              (start_pos[:y] * @zoom_factor + @offset_y + 25).round,
              (end_pos[:x] * @zoom_factor + @offset_x + 50).round,
              (end_pos[:y] * @zoom_factor + @offset_y + 25).round,
              color
              )
            draw_association_label(assoc[:type], start_pos[:x], start_pos[:y], end_pos[:x], end_pos[:y])
          end
        end
      end
    end

    def button_down(id)
      if id == Gosu::MsLeft
        model_clicked = false
        @positions.each do |model, pos|
          if mouse_over_model?(mouse_x, mouse_y, pos[:x], pos[:y])
            @selected_model = model
            model_clicked = true
            break
          end
        end
        start_drag if model_clicked
      end
      handle_zoom(id)
    end

    def button_up(id)
      stop_drag if id == Gosu::MsLeft
    end

    def update
      if @dragging
        delta_x = mouse_x - @last_mouse_x
        delta_y = mouse_y - @last_mouse_y
        @offset_x += delta_x
        @offset_y += delta_y
      end
      @last_mouse_x = mouse_x
      @last_mouse_y = mouse_y
    end

    def start_drag
      @dragging = true
      @last_mouse_x = mouse_x
      @last_mouse_y = mouse_y
    end

    def stop_drag
      @dragging = false
    end

    def handle_zoom(id)
      case id
      when Gosu::KbUp
        @zoom_factor += 0.1
      when Gosu::KbDown
        @zoom_factor = [@zoom_factor - 0.1, 0.1].max
      end
    end

    def mouse_over_model?(mouse_x, mouse_y, model_x, model_y)
      x = (model_x * @zoom_factor + @offset_x).round
      y = (model_y * @zoom_factor + @offset_y).round
      width = (100 * @zoom_factor).round
      height = (50 * @zoom_factor).round

      mouse_x >= x && mouse_x <= (x + width) && mouse_y >= y && mouse_y <= (y + height)
    end

    def draw_association_label(type, x1, y1, x2, y2)
      label_x = ((x1 + x2) / 2) * @zoom_factor
      label_y = ((y1 + y2) / 2) * @zoom_factor
      draw_text(type.to_s, label_x, label_y)
    end

    def draw_arrow(x1, y1, x2, y2, color = @assoc_color)
      Gosu.draw_line(x1, y1, @assoc_color, x2, y2, color)
      draw_arrowhead(x1, y1, x2, y2, color)
    end

    def draw_arrowhead(x1, y1, x2, y2, color = @assoc_color)
      angle = Math.atan2(y2 - y1, x2 - x1)
      size = 10
      Gosu.draw_line(x2, y2, color, x2 - size * Math.cos(angle - Math::PI / 6), y2 - size * Math.sin(angle - Math::PI / 6), color)
      Gosu.draw_line(x2, y2, color, x2 - size * Math.cos(angle + Math::PI / 6), y2 - size * Math.sin(angle + Math::PI / 6), color)
    end
  end
end
