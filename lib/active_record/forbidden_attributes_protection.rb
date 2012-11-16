require 'active_record'

module ActiveRecord
  class ForbiddenAttributes < StandardError
  end

  module ForbiddenAttributesProtection
    private

    def assign_attributes_with_permitted(attributes)
      if !attributes.respond_to?(:permitted?) || attributes.permitted?
        assign_attributes_without_permitted(attributes)
      else
        raise ActiveRecord::ForbiddenAttributes
      end
    end

    def self.included(base)
      base.alias_method_chain :assign_attributes, :permitted
    end
  end
end
