require "risp/version"
require "risp/interpreter"

module Risp
  class Symbol < Struct.new(:name)
    def inspect
      name.to_s
    end
  end

  class Method < Struct.new(:name)
    def inspect
      name.to_s
    end
  end

  class Splat < Struct.new(:name)
    def inspect
      "&#{name.to_s}"
    end
  end
end
