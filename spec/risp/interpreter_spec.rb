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
          (if (= n 1)
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

    it 'supports variable arguments' do
      lisp = <<-LISP
        (defn first-and-rest [first second &rest]
          [first second rest])

        (first-and-rest 0 1 2 3)
      LISP
      expect(i.eval lisp).to eq([0, 1, [2, 3]])
    end

    it 'supports argument deconstruction' do
      lisp = <<-LISP
        (defn unwrap [first [a [b c]] &rest]
          [first a b c rest])

        (unwrap 0 [1 [2 3]] 4 5)
      LISP
      expect(i.eval lisp).to eq([0, 1, 2, 3, [4, 5]])

      lisp = <<-LISP
        (defn swap-pairs [[a b] [c d]]
          [[a c] [b d]])

        (swap-pairs [1 2] [3 4])
      LISP
      expect(i.eval lisp).to eq(Hamster.from([[1, 3], [2, 4]]))

      lisp = <<-LISP
        (defn swap-pairs [x y]
          (let [[a b] x
                [c d] y]
            [[a c] [b d]]))

        (swap-pairs [1 2] [3 4])
      LISP
      expect(i.eval lisp).to eq(Hamster.from([[1, 3], [2, 4]]))
    end

    it 'interoperates with Ruby' do
      expect(i.eval '(.first [1 2 3])').to eq(1)
      expect(i.eval '(.new Set [1 2 3])').to eq(Set.new([1, 2, 3]))
      expect(i.eval '(.reduce [1 2 3 4] +)').to eq(10)
      expect(i.eval '(.reduce [1 2 3 4] :*)').to eq(24)
      expect(i.eval '(.sqrt Math 4)').to eq(2)
      expect(i.eval '(.new Hamster/Set [1 2 3])').to eq(Hamster::Set.new([1, 2, 3]))
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

    it 'provides a threading-last macro' do
      lisp = <<-LISP
        (->> [1 2 3 4]
          (map (fn [x] (+ x 3)))
          (filter (fn [x] (.odd? x))))
      LISP
      expect(i.eval lisp).to eq([5, 7])
    end

    it 'provides a threading-first macro' do
      lisp = <<-LISP
        (-> [1 2 3 4]
          (.map (fn [x] (+ x 3)))
          (.select (fn [x] (.odd? x))))
      LISP
      expect(i.eval lisp).to eq([5, 7])
    end
  end
end
