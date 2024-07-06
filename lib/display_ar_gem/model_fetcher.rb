module DisplayArGem
  class ModelFetcher
    def self.fetch
      models = ActiveRecord::Base.descendants
      associations = models.each_with_object({}) do |model, hash|
        hash[model.name] = model.reflect_on_all_associations.map do |assoc|
          next unless assoc

          begin
            if assoc.is_a?(ActiveRecord::Reflection::ThroughReflection)
              class_name = "Through (#{assoc.name})"
            else
              class_name = if assoc.polymorphic?
                "Polymorphic (#{assoc.name})"
              else
                assoc.options[:class_name] || (assoc.klass.name if assoc.klass)
              end || 'Unknown'
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
        end.compact
      end
      { models: models, associations: associations }
    end
  end
end
