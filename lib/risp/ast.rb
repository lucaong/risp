module Risp
  module AST
    class Literal < Struct.new(:value)
      def eval(_)
        value
      end
    end

    class Symbol < Struct.new(:name)
      def eval(binding)
        binding[name]
      end
    end

    class List < Struct.new(:elems)
      def eval(binding)
        return eval_special_form(binding) if special_form?(elems.first)
        first, *rest = elems.map { |el| el.eval(binding) }
        first.call(*rest)
      end

      def eval_special_form(binding)
        first, *rest = elems
        Risp::Interpreter::SPECIAL_FORMS[first.name].call(binding, rest)
      end

      def special_form?(symbol)
        return false unless symbol.is_a? Symbol
        Risp::Interpreter::SPECIAL_FORMS[symbol.name] != nil
      end
    end

    class VectorLiteral < Struct.new(:elems)
      def eval(binding)
        elems.map { |el| el.eval(binding) }
      end
    end

    class SetLiteral < Struct.new(:elems)
      def eval(binding)
        Set.new(elems.map { |el| el.eval(binding) })
      end
    end

    class MapLiteral < Struct.new(:elems)
      def eval(binding)
        elems.map { |el| el.eval(binding) }.to_h
      end
    end
  end
end
