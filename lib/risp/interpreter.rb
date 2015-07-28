require "risp/lexer"
require "risp/parser"

module Risp
  class Interpreter
    attr_reader :binding, :lexer, :parser

    SPECIAL_FORMS = {
      'def' => -> (binding, elems) {
        symbol, value = elems
        binding[symbol.name] = value.eval(binding)
      },
      'let' => -> (binding, elems) {
        assigns, body = elems
        locals = assigns.elems.each_slice(2).reduce(binding.dup) do |locals, (s, v)|
          locals[s.name] = v.eval(locals)
          locals
        end
        body.eval(locals)
      },
      'fn' => -> (binding, elems) {
        as, *body  = elems
        arg_names = as.elems.map(&:name)
        -> (*args) do
          binding = binding.merge(arg_names.zip(args).to_h)
          body.map { |el| el.eval(binding) }.last
        end
      },
      'defn' => -> (binding, elems) {
        symbol, as, body = elems
        arg_names = as.elems.map(&:name)
        binding[symbol.name] = -> (*args) do
          binding = binding.merge(arg_names.zip(args).to_h)
          body.eval(binding)
        end
      },
      'do' => -> (binding, elems) {
        elems.map { |el| el.eval(binding) }.last
      },
      'if' => -> (binding, elems) {
        condition, _then, _else = elems
        if condition.eval(binding)
          _then.eval(binding)
        else
          _else.eval(binding)
        end
      }
    }

    def initialize(binding = global, special_forms = SPECIAL_FORMS)
      @binding = binding
      @lexer   = Risp::Lexer.new
      @parser  = Risp::Parser.new
    end

    def eval(code)
      parser.parse(lexer.lex(code)).map { |x| x.eval(binding) }
    end

    def global
      arithmetics = %w[+ * / -].map do |op|
        [op, -> (*xs) { xs.reduce(&:"#{op}") }]
      end

      comparisons = %w[> < >= <= =].map do |op|
        method = if op == '=' then :== else op.to_sym end
        [op, -> (*xs) { xs.each_cons(2).all? { |x, y| x.send(method, y) } }]
      end

      (arithmetics + comparisons).to_h
    end
  end
end

