require "risp/lexer"
require "risp/parser"

module Risp
  class Interpreter
    attr_reader :binding, :lexer, :parser
    MACROS = {}

    SPECIAL_FORMS = {
      def: -> (elems, binding, locals) {
        symbol, value = elems
        binding[symbol.name] = eval(value, binding, locals)
      },
      let: -> (elems, binding, locals) {
        (_, assigns), body = elems
        locals = assigns.each_slice(2).reduce(locals.dup) do |locals, (s, v)|
          locals[s.name] = eval(v, binding, locals)
          locals
        end
        eval(body, binding, locals)
      },
      fn: -> (elems, binding, locals) {
        (_, as), *body  = elems
        arg_names = as.map(&:name)
        -> (*args) do
          locals = locals.merge(arg_names.zip(args).to_h)
          body.map { |el| eval(el, binding, locals) }.last
        end
      },
      defn: -> (elems, binding, locals) {
        symbol, (_, as), body = elems
        arg_names = as.map(&:name)
        binding[symbol.name] = -> (*args) do
          locals = locals.merge(arg_names.zip(args).to_h)
          eval(body, binding, locals)
        end
      },
      do: -> (elems, binding, locals) {
        elems.map { |el| eval(el, binding, locals) }.last
      },
      if: -> (elems, binding, locals) {
        condition, _then, _else = elems
        if eval(condition, binding, locals)
          eval(_then, binding, locals)
        else
          eval(_else, binding, locals)
        end
      },
      quote: -> (elems, binding, locals) {
        unquote(elems.first, binding, locals)
      },
      defmacro: -> (elems, binding, locals) {
        symbol, (_, as), body = elems
        arg_names = as.map(&:name)
        MACROS[symbol.name] = -> (*args) do
          locals = locals.merge(arg_names.zip(args).to_h)
          eval(body, binding, locals)
        end
      }
    }

    def initialize(binding = global)
      @binding = binding
      @lexer   = Risp::Lexer.new
      @parser  = Risp::Parser.new
    end

    def eval(code)
      parser.parse(lexer.lex(code)).map { |x| self.class.eval(x, binding, {}) }.last
    end

    def global
      arithmetics = %i[+ * / -].map do |op|
        [op, -> (*xs) { xs.reduce(&op) }]
      end

      comparisons = %i[> < >= <= =].map do |op|
        method = if op == :'=' then :== else op end
        [op, -> (*xs) { xs.each_cons(2).all? { |x, y| x.send(method, y) } }]
      end

      data = [
        [:set, -> (*xs) { Set.new(xs) }],
        [:'hash-map', -> (*xs) { xs.each_slice(2).to_h }]
      ]

      (arithmetics + comparisons + data).to_h
    end

    def self.eval(expr, binding, locals)
      case expr
      when Array
        first = expr.first
        if special = first.is_a?(Risp::Symbol) && SPECIAL_FORMS[first.name]
          special.call(expr.drop(1), binding, locals)
        elsif macro = first.is_a?(Risp::Symbol) && MACROS[first.name]
          _, *args = expr
          eval(macro.call(*args), binding, locals)
        elsif first.is_a?(Risp::Method)
          receiver, *args = expr.drop(1).map { |x| eval(x, binding, locals) }
          receiver.send(first.name, *args)
        else
          fn, *args = expr.map { |x| eval(x, binding, locals) }
          fn.call(*args)
        end
      when Risp::Symbol
        symbol = expr.name
        resolve(symbol, binding, locals)
      else
        expr
      end
    end

    def self.unquote(expr, binding, locals)
      if expr.is_a?(Array) || expr.is_a?(Hash) || expr.is_a?(Set)
        first = expr.first
        if first.is_a?(Risp::Symbol) && first.name == :unquote
          eval(expr[1], binding, locals)
        else
          expr.map { |x| unquote(x, binding, locals) }
        end
      else
        expr
      end
    end

    def self.resolve(symbol, binding, locals)
      if locals.has_key?(symbol)
        locals[symbol]
      elsif binding.has_key?(symbol)
        binding[symbol]
      elsif Object.const_defined?(symbol)
        Object.const_get(symbol)
      else
        raise "cannot resolve #{symbol}"
      end
    end
  end
end

