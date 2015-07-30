require 'spec_helper'

describe Risp::Parser do
  let(:lexer)  { Risp::Lexer.new }
  let(:parser) { Risp::Parser.new }
  let(:source) {
    <<-EOS
      (foo bar (baz 123 "xxx"))
      -42.5
      ; comments should be ignored
      (map somefunction [1 2 3])
      (reduce somefunction {:x 0} [1 2 3])
      \#{a set of stuff}
    EOS
  }

  def sym(x)
    Risp::Symbol.new(x)
  end

  describe :parse do
    it 'parses correctly' do
      tokens = lexer.lex(source)
      parsed = parser.parse(tokens)
      expect(parsed[0]).to eq(Hamster::List[sym(:foo), sym(:bar), Hamster::List[sym(:baz), 123, "xxx"]])
      expect(parsed[1]).to eq(-42.5)
      expect(parsed[2]).to eq(Hamster::List[sym(:map), sym(:somefunction), Hamster::List[sym(:vector), 1, 2, 3]])
      expect(parsed[3]).to eq(Hamster::List[sym(:reduce), sym(:somefunction),
                                            Hamster::List[sym(:"hash-map"), :x, 0],
                                            Hamster::List[sym(:vector), 1, 2, 3]])
      expect(parsed[4]).to eq(Hamster::List[:set, :a, :set, :of, :stuff].map { |x| sym(x) })
    end
  end
end

