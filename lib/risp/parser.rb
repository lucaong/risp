require 'rltk/parser'
require "risp/ast"

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
    end

    production(:list) do
      clause('LPAREN expressions RPAREN') do |_, elems, _|
        Risp::AST::List.new(elems)
      end
    end

    production(:atom) do
      clause('literal') do |l|
        l
      end
      clause('SYMBOL') do |name|
        Risp::AST::Symbol.new(name)
      end
      clause('DOT SYMBOL') do |_, name|
        Risp::AST::MethodSymbol.new(name)
      end
    end

    production(:literal) do
      clause('INTEGER') do |n|
        Risp::AST::Literal.new(n.to_i)
      end
      clause('FLOAT') do |f|
        Risp::AST::Literal.new(f.to_f)
      end
      clause('STRING') do |s|
        Risp::AST::Literal.new(s)
      end
      clause('LSQBRACK expressions RSQBRACK') do |_, exprs, _|
        Risp::AST::VectorLiteral.new(exprs)
      end
      clause('POUND LBRACE expressions RBRACE') do |_, _, exprs, _|
        Risp::AST::SetLiteral.new(exprs)
      end
      clause('LBRACE expressions RBRACE') do |_, keyvals, _|
        Risp::AST::MapLiteral.new(keyvals)
      end
      clause('NIL') do |_|
        Risp::AST::Literal.new(nil, NilClass)
      end
    end

    finalize
  end
end
