require 'active_support/core_ext/hash/indifferent_access'
require 'action_controller'

module ActionController
  class ParameterMissing < IndexError
    attr_reader :param

    def initialize(param)
      @param = param
      super("key not found: #{param}")
    end
  end

  class UnpermittedParameters < IndexError
    attr_reader :params

    def initialize(params)
      @params = params
      super("found unpermitted parameters: #{params.join(", ")}")
    end
  end

  class Parameters < HashWithIndifferentAccess
    attr_accessor :permitted
    alias :permitted? :permitted

    cattr_accessor :action_on_unpermitted_parameters, :instance_accessor => false

    # Never raise an UnpermittedParameters exception because of these params
    # are present. They are added by Rails and it's of no concern.
    NEVER_UNPERMITTED_PARAMS = %w( controller action )

    def initialize(attributes = nil)
      super(attributes)
      @permitted = false
    end

    def permit!
      each_pair do |key, value|
        convert_hashes_to_parameters(key, value)
        self[key].permit! if self[key].respond_to? :permit!
      end

      @permitted = true
      self
    end

    def require(key)
      self[key].presence || raise(ActionController::ParameterMissing.new(key))
    end

    alias :required :require

    def permit(*filters)
      params = self.class.new

      filters.each do |filter|
        case filter
        when Symbol, String then
          params[filter] = self[filter] if has_key?(filter)
          keys.grep(/\A#{Regexp.escape(filter.to_s)}\(\d+[if]?\)\z/).each { |key| params[key] = self[key] }
        when Hash then
          self.slice(*filter.keys).each do |key, value|
            return unless value

            key = key.to_sym

            params[key] = each_element(value) do |value|
              # filters are a Hash, so we expect value to be a Hash too
              next if filter.is_a?(Hash) && !value.is_a?(Hash)

              value = self.class.new(value) if !value.respond_to?(:permit)

              value.permit(*Array.wrap(filter[key]))
            end
          end
        end
      end

      unpermitted_parameters!(params) if self.class.action_on_unpermitted_parameters

      params.permit!
    end

    def [](key)
      convert_hashes_to_parameters(key, super)
    end

    def fetch(key, *args)
      convert_hashes_to_parameters(key, super)
    rescue KeyError, IndexError
      raise ActionController::ParameterMissing.new(key)
    end

    def slice(*keys)
      self.class.new(super).tap do |new_instance|
        new_instance.instance_variable_set :@permitted, @permitted
      end
    end

    def dup
      duplicate = Parameters.new(self)
      duplicate.instance_variable_set :@permitted, @permitted
      duplicate
    end

    protected
      def convert_value(value)
        if value.class == Hash
          self.class.new(value)
        elsif value.is_a?(Array)
          value.dup.replace(value.map { |e| convert_value(e) })
        else
          value
        end
      end

    private
      def convert_hashes_to_parameters(key, value)
        if value.is_a?(Parameters) || !value.is_a?(Hash)
          value
        else
          # Convert to Parameters on first access
          self[key] = self.class.new(value)
        end
      end

      def each_element(object)
        if object.is_a?(Array)
          object.map { |el| yield el }.compact
        # fields_for on an array of records uses numeric hash keys
        elsif object.is_a?(Hash) && object.keys.all? { |k| k =~ /\A-?\d+\z/ }
          hash = object.class.new
          object.each { |k,v| hash[k] = yield v }
          hash
        else
          yield object
        end
      end

      def unpermitted_parameters!(params)
        return unless self.class.action_on_unpermitted_parameters

        unpermitted_keys = unpermitted_keys(params)

        if unpermitted_keys.any?
          case self.class.action_on_unpermitted_parameters
          when :log
            ActionController::Base.logger.debug "Unpermitted parameters: #{unpermitted_keys.join(", ")}"
          when :raise
            raise ActionController::UnpermittedParameters.new(unpermitted_keys)
          end
        end
      end

      def unpermitted_keys(params)
        self.keys - params.keys - NEVER_UNPERMITTED_PARAMS
      end
  end
end

ActionController::Base
module ActionController
  Base.class_eval do
    rescue_from ActionController::ParameterMissing do |parameter_missing_exception|
      render :text => "Required parameter missing: #{parameter_missing_exception.param}", :status => :bad_request
    end

    def params
      if @_params.is_a?(Parameters)
        @_params
      else
        @_params = Parameters.new(request.parameters)
      end
    end

    def params=(val)
      @_params = val.is_a?(Hash) ? Parameters.new(val) : val
    end
  end
end
