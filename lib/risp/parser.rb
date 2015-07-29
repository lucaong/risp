require 'rltk/parser'

module Risp
  class Parser < RLTK::Parser
    build_list_production(:expressions, :expression)

    production(:expression) do
      clause('atom') do |atom|
        atom
      end
      clause('list') do |list|
        list
      end
      clause('QUOTE expression') do |_, expr|
        [Risp::Symbol.new(:quote), expr]
      end
      clause('UNQUOTE expression') do |_, expr|
        [Risp::Symbol.new(:unquote), expr]
      end
    end

    production(:list) do
      clause('LPAREN expressions RPAREN') do |_, elems, _|
        elems
      end
    end

    production(:atom) do
      clause('literal') do |l|
        l
      end
      clause('SYMBOL') do |name|
        Risp::Symbol.new(name.to_sym)
      end
      clause('DOT SYMBOL') do |_, name|
        Risp::Method.new(name.to_sym)
      end
      clause('AMPERSAND SYMBOL') do |_, name|
        Risp::Splat.new(name.to_sym)
      end
    end

    production(:literal) do
      clause('INTEGER') do |n|
        n
      end
      clause('FLOAT') do |f|
        f
      end
      clause('STRING') do |s|
        s
      end
      clause('BOOLEAN') do |b|
        b
      end
      clause('KEYWORD') do |k|
        k[1..-1].to_sym
      end
      clause('LSQBRACK expressions RSQBRACK') do |_, exprs, _|
        [Risp::Symbol.new(:quote), exprs.map { |x| [Risp::Symbol.new(:unquote), x] }]
      end
      clause('POUND LBRACE expressions RBRACE') do |_, _, exprs, _|
        [Risp::Symbol.new(:set)] + exprs
      end
      clause('LBRACE expressions RBRACE') do |_, keyvals, _|
        [Risp::Symbol.new(:"hash-map")] + keyvals
      end
      clause('NIL') do |_|
        nil
      end
    end

    finalize
  end
end
