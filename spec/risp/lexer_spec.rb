require 'spec_helper'

describe Risp::Lexer do
  let(:lexer) { Risp::Lexer.new }
  let(:source) {
    <<-EOS
    (def x 2)
    (defn [y] (+ x y))
    ; comments should be ignored
    (.foo bar)
    {123 23.45}
    \#{1 2}
    EOS
  }

  describe :lex do
    it 'lexes correctly' do
      tokens = lexer.lex(source)
      expected_types = %i[
      LPAREN SYMBOL SYMBOL INTEGER RPAREN
      LPAREN SYMBOL LSQBRACK SYMBOL RSQBRACK LPAREN SYMBOL SYMBOL SYMBOL RPAREN RPAREN
      LPAREN DOT SYMBOL SYMBOL RPAREN
      LBRACE INTEGER FLOAT RBRACE
      POUND LBRACE INTEGER INTEGER RBRACE
      EOS
      ]
      expect( tokens.map(&:type) ).to eq(expected_types)
    end
  end
end


