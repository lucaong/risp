require "risp/lexer"
require "risp/parser"

module Risp
  class Interpreter
    attr_reader :binding, :macros, :lexer, :parser

    SPECIAL_FORMS = {
      def: -> (elems, binding, locals, macros) {
        symbol, value = elems
        binding[symbol.name] = eval(value, binding, locals, macros)
      },
      let: -> (elems, binding, locals, macros) {
        (_, assigns), body = elems
        locals = assigns.each_slice(2).reduce(locals.dup) do |locals, (s, v)|
          locals[s.name] = eval(v, binding, locals, macros)
          locals
        end
        eval(body, binding, locals, macros)
      },
      fn: -> (elems, binding, locals, macros) {
        (_, as), *body  = elems
        arg_names = as.map(&:name)
        -> (*args) do
          locals = locals.merge(arg_names.zip(args).to_h)
          body.map { |el| eval(el, binding, locals, macros) }.last
        end
      },
      defn: -> (elems, binding, locals, macros) {
        symbol, (_, as), body = elems
        arg_names = as.map(&:name)
        binding[symbol.name] = -> (*args) do
          locals = locals.merge(arg_names.zip(args).to_h)
          eval(body, binding, locals, macros)
        end
      },
      do: -> (elems, binding, locals, macros) {
        elems.map { |el| eval(el, binding, locals, macros) }.last
      },
      if: -> (elems, binding, locals, macros) {
        condition, _then, _else = elems
        if eval(condition, binding, locals, macros)
          eval(_then, binding, locals, macros)
        else
          eval(_else, binding, locals, macros)
        end
      },
      quote: -> (elems, binding, locals, macros) {
        unquote(elems.first, binding, locals, macros)
      },
      defmacro: -> (elems, binding, locals, macros) {
        symbol, (_, as), body = elems
        arg_names = as.map(&:name)
        macros[symbol.name] = -> (*args) do
          locals = locals.merge(arg_names.zip(args).to_h)
          eval(body, binding, locals, macros)
        end
      }
    }

    def initialize()
      @binding = core
      @macros  = {}
      @lexer   = Risp::Lexer.new
      @parser  = Risp::Parser.new
    end

    def eval(code)
      parser.parse(lexer.lex(code)).map { |x| self.class.eval(x, binding, {}, macros) }.last
    end

    def core
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

    def self.eval(expr, binding, locals, macros)
      case expr
      when Array
        first = expr.first
        if special = first.is_a?(Risp::Symbol) && SPECIAL_FORMS[first.name]
          special.call(expr.drop(1), binding, locals, macros)
        elsif macro = first.is_a?(Risp::Symbol) && macros[first.name]
          _, *args = expr
          eval(macro.call(*args), binding, locals, macros)
        elsif first.is_a?(Risp::Method)
          receiver, *args = expr.drop(1).map { |x| eval(x, binding, locals, macros) }
          receiver.send(first.name, *args)
        else
          fn, *args = expr.map { |x| eval(x, binding, locals, macros) }
          fn.call(*args)
        end
      when Risp::Symbol
        symbol = expr.name
        resolve(symbol, binding, locals, macros)
      else
        expr
      end
    end

    def self.unquote(expr, binding, locals, macros)
      if expr.is_a?(Array) || expr.is_a?(Hash) || expr.is_a?(Set)
        first = expr.first
        if first.is_a?(Risp::Symbol) && first.name == :unquote
          eval(expr[1], binding, locals, macros)
        else
          expr.map { |x| unquote(x, binding, locals, macros) }
        end
      else
        expr
      end
    end

    def self.resolve(symbol, binding, locals, macros)
      if locals.has_key?(symbol)
        locals[symbol]
      elsif binding.has_key?(symbol)
        binding[symbol]
      elsif symbol.to_s.capitalize == symbol.to_s && Object.const_defined?(symbol)
        Object.const_get(symbol)
      else
        raise "cannot resolve #{symbol}"
      end
    end
  end
end

