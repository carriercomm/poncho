module Poncho
  class Resource
    include Params
    include Validations

    attr_reader :record

    def initialize(record)
      @record = record
    end

    # Params

    def param(name)
      param = self.class.params[name]
      raise Error, "Undefined param #{name}" unless param
      param.convert(param_before_type_cast(name))
    end

    def param_before_type_cast(name)
      record.send(name) if record.respond_to?(name)
    end

    alias :param? :param_before_type_cast

    # Serialization

    def each
      [to_json]
    end

    def to_json(options = nil)
      as_json.to_json
    end

    def as_json(options = nil)
      validate!
      to_hash
    end

    def to_hash
      self.class.params.keys.inject({}) do |hash, key|
        hash[key] = send(key)
        hash
      end
    end

    # Validation

    alias :read_attribute_for_validation :send

    def validate!
      raise ResourceError, errors.to_s unless valid?
    end

    def method_missing(method_symbol, *arguments) #:nodoc:
      if method_symbol.to_s =~ /(=|\?)$/
        case $1
        when "?"
          param?($`)
        end
      else
        if self.class.params.keys.include?(method_symbol)
          return param(method_symbol)
        end

        super
      end
    end
  end
end