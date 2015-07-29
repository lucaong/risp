require 'spec_helper'

describe Risp::Interpreter do
  let(:i) { Risp::Interpreter.new }

  describe :eval do
    it 'correctly evaluates code' do
      lisp = <<-LISP
        (def ten 10)

        (defn dec [n]
          (- n 1))

        (defn fact [n]
          (if (<= n 1)
            1
            (let [m (fact (dec n))]
              (* n m))))

        (fact ten)
      LISP
      expect(i.eval lisp).to eq(3628800)
    end

    it 'supports quoting and unquoting' do
      lisp = <<-LISP
        '(1 2 ~(+ 1 2))
      LISP
      expect(i.eval lisp).to eq([1, 2, 3])
    end

    it 'interoperates with Ruby' do
      expect(i.eval '(.first [1 2 3])').to eq(1)
      expect(i.eval '(.new Set [1 2 3])').to eq(Set.new([1, 2, 3]))
      expect(i.eval '(.reduce [1 2 3 4] +)').to eq(10)
    end

    it 'supports macros' do
      lisp = <<-LISP
        (defmacro defn- [name args body]
          '(def ~name (fn ~args ~body)))

        (defn- sum [a b]
          (+ a b))

        (sum 4 5)
      LISP
      expect(i.eval lisp).to eq(9)
    end
  end
end
