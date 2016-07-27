module ActiveAdmin
  module Inputs
    module Filters
      class SelectInput < ::Formtastic::Inputs::SelectInput
        def searchable_method_name
          if searchable_has_many_through?
            "#{reflection.through_reflection.name}_#{reflection.foreign_key}"
          else
            polymorphic = reflection && reflection.macro == :belongs_to && reflection.options[:polymorphic]
            key = polymorphic ? nil : reflection.try(:association_primary_key)
            name = [method, key].compact.join('_')
          end
        end
      end
    end
  end
end
