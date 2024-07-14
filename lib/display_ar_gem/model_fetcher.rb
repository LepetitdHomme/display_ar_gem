module DisplayArGem
  class ModelFetcher
    def self.fetch
      # Load all models
      Rails.application.eager_load!

      # Specify the models you want to include
      models =  ActiveRecord::Base.descendants.reject(&:abstract_class?)

      associations = models.each_with_object({}) do |model, hash|
        # puts "Processing model: \n\t#{model.name}" # Debugging line
        hash[model.name] = model.reflect_on_all_associations.map do |assoc|
          # puts "Processing association: #{assoc.name} for model: #{model.name}" # Debugging line
          begin
            class_name = if assoc.is_a?(ActiveRecord::Reflection::ThroughReflection)
                           "Through (#{assoc.name})"
                         elsif assoc.polymorphic?
                           "Polymorphic (#{assoc.name})"
                         else
                           assoc.options[:class_name] || assoc.klass&.name || 'Unknown'
                         end
          rescue => e
            puts "Error while fetching association class_name: #{e.message}"
            class_name = 'Unknown'
          end

          {
            name: assoc.name,
            type: assoc.macro,
            class_name: class_name
          }
        end
      end
      # puts 'models:'
      # puts models
      # puts 'assoc:'
      # puts associations
      { models: models, associations: associations }
    end
  end
end
