require "risp/lexer"
require "risp/parser"
require "hamster"

module Risp
  class Interpreter
    attr_reader :binding, :macros, :lexer, :parser

    SPECIAL_FORMS = {
      def: -> (elems, binding, locals, macros) {
        symbol, value = elems
        binding[symbol.name] = eval(value, binding, locals, macros)
      },
      let: -> (elems, binding, locals, macros) {
        (_, *assigns), body = elems
        locals = assigns.each_slice(2).reduce(locals.dup) do |locals, (s, v)|
          locals[s.name] = eval(v, binding, locals, macros)
          locals
        end
        eval(body, binding, locals, macros)
      },
      fn: -> (elems, binding, locals, macros) {
        (_, *as), body = elems
        -> (*args) do
          locals = locals.merge(assign_args(as, args))
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
        symbol, (_, *as), body = elems
        macros[symbol.name] = -> (*args) do
          locals = locals.merge(assign_args(as, args))
          eval(body, binding, locals, macros)
        end
      },
      apply: -> (elems, binding, locals, macros) {
        fn, args = elems.map { |x| eval(x, binding, locals, macros) }
        fn.call(*args)
      }
    }

    def initialize()
      @binding = {}
      @macros  = {}
      @lexer   = Risp::Lexer.new
      @parser  = Risp::Parser.new
      corelib  = File.read(File.expand_path('core.risp', File.dirname(__FILE__)))
      eval(corelib)
    end

    def eval(code)
      parser.parse(lexer.lex(code)).map { |x| self.class.eval(x, binding, {}, macros) }.last
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
          if args.last.is_a?(Proc) && receiver.method(first.name).arity < args.size
            *args, block = args
            receiver.send(first.name, *args, &block)
          else
            receiver.send(first.name, *args)
          end
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
        first, second = expr
        if first.is_a?(Risp::Symbol) && first.name == :unquote
          eval(second, binding, locals, macros)
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
      else
        begin
          symbol.to_s.split('/').reduce(Object) do |c, p|
            c.const_get(p)
          end
        rescue NameError => e
          raise "cannot resolve #{symbol}"
        end
      end
    end

    def self.assign_args(symbols, values)
      assigns = {}
      if symbols.last.is_a?(Risp::Splat)
        *symbols, splat = symbols
        assigns[splat.name] = values.drop(symbols.size)
      end
      symbols.zip(values) do |s, v|
        if s.is_a?(Enumerable) && !s.is_a?(Risp::Symbol) && v.is_a?(Enumerable)
          assigns.merge!(assign_args(s.drop(1), v))
        else
          assigns[s.name] = v
        end
      end
      assigns
    end
  end
end

