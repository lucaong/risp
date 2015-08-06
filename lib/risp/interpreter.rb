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
        (*assigns), *forms = elems
        locals = assigns.each_slice(2).reduce(locals.dup) do |locals, (s, v)|
          locals.merge assign_args([s], [eval(v, binding, locals, macros)])
        end
        forms.map { |form| eval(form, binding, locals, macros) }.last
      },
      fn: -> (elems, binding, locals, macros) {
        (*as), body = elems
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
        symbol, (*as), body = elems
        macros[symbol.name] = -> (*args) do
          locals = locals.merge(assign_args(as, args))
          eval(body, binding, locals, macros)
        end
      },
      apply: -> (elems, binding, locals, macros) {
        fn, args = elems.map { |x| eval(x, binding, locals, macros) }
        fn.call(*args)
      },
      require: -> (elems, binding, locals, macros) {
        elems.each do |lib|
          require lib
        end
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
      when Hamster::List
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
      when Enumerable
        expr.map { |x| eval(x, binding, locals, macros) }
      else
        expr
      end
    end

    def self.unquote(expr, binding, locals, macros)
      if expr.is_a?(Enumerable) && !expr.is_a?(Risp::Symbol)
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
      symbols.each_with_index.reduce({}) do |a, (s, i)|
        v = values[i]
        if s.is_a?(Hamster::Vector) && v.is_a?(Enumerable)
          a.merge(assign_args(s, v))
        elsif s.is_a?(Risp::Splat)
          a[s.name] = values.drop(i)
          a
        else
          a[s.name] = v
          a
        end
      end
    end
  end
end

