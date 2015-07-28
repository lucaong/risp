require 'spec_helper'

describe Risp::Parser do
  let(:lexer)  { Risp::Lexer.new }
  let(:parser) { Risp::Parser.new }
  let(:source) {
    <<-EOS
      (foo bar (baz 123 "xxx"))
      42.5
      (map somefunction [1 2 3])
      (reduce somefunction {} [1 2 3])
      \#{a set of stuff}
    EOS
  }

  describe :parse do
    it 'parses correctly' do
      tokens = lexer.lex(source)
      ast    = parser.parse(tokens)
      expect( ast.first ).to be_a(Risp::AST::List)
      expect( ast.first.elems.first ).to be_a(Risp::AST::Symbol)
      expect( ast.first.elems.first.name ).to eq('foo')
      expect( ast.first.elems[2] ).to be_a(Risp::AST::List)
      expect( ast.first.elems[2].elems.last ).to be_a(Risp::AST::Literal)
    end
  end
end

