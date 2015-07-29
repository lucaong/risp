require "rltk/lexer"

module Risp
  class Lexer < RLTK::Lexer
    rule(/"[^"]*"/)    { |t| [:STRING, t[1...-1]] }
    rule(/\d+\.\d+/)   { |t| [:FLOAT, t.to_f] }
    rule(/\d+/)        { |t| [:INTEGER, t.to_i] }
    rule(/true|false/) { |b| [:BOOLEAN, b == 'true'] }
    rule(/nil|\(\)/)   { :NIL }
    rule(/\(/)         { :LPAREN }
    rule(/\)/)         { :RPAREN }
    rule(/\[/)         { :LSQBRACK }
    rule(/\]/)         { :RSQBRACK }
    rule(/\{/)         { :LBRACE }
    rule(/\}/)         { :RBRACE }
    rule(/\./)         { :DOT }
    rule(/#/)          { :POUND }
    rule(/'/)          { :QUOTE }
    rule(/~/)          { :UNQUOTE }
    rule(/&/)          { :AMPERSAND }
    rule(/:[^&'~\(\)\{\}\[\]\.#\s,]+/i) { |t| [:KEYWORD, t] }
    rule(/[^:&'~\(\)\{\}\[\]\.#\s,]+/i) { |t| [:SYMBOL, t] }
    rule(/[\s,]/)     # ignore whitespaces and commas
  end
end
