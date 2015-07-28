require "risp/version"
require "risp/interpreter"

module Risp
  class Symbol < Struct.new(:name)
    def eval(binding)
      binding[name] || (Object.const_get(name) if Object.const_defined?(name))
    end

    def inspect
      name.to_s
    end
  end

  class Method < Struct.new(:name)
    def eval(binding)
      name.to_sym
    end

    def inspect
      name.to_s
    end
  end
end
