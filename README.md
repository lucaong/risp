# Risp

`Risp` is a LISP implementation written in Ruby. The syntax is reminescent of
Clojure, and it interoperates with Ruby.


## Why?

Why not? :P

Mostly I did this to learn a bit more about programming language design. Or
maybe I was bored. And also I really like LISPs and I like the idea of writing
LISP leveraging on the Ruby ecosystem. But still this is mostly an experiment,
so if you use it you cannot blame me if it ends up eating your laundry or
setting your kitchen on fire.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'risp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install risp


## Usage

### Start a REPL

Just run `risp-repl`

### Execute a file

`risp my_program.risp`

### Inside Ruby

Instantiate an interpreter and evaluate code:

```ruby
require 'risp'
risp = Risp::Interpreter.new

risp.eval <<-CODE
(def double [x]
  (* 2 x))

(double 5)
CODE
```


## Syntax

The LISP syntax is very similar to Clojure:

```lisp
; Define a function
(defn dec [n]
  (- n 1))

; Define recursive factorial
(defn fact [n]
  (if (<= n 1)
    1
    (* n (fact (dec n)))))

(fact 10) ; => 3628800

; Rest argument
(defn foo [a b &more]
  [a b more])

(foo 1 2 3 4 5) ; => [1 2 [3 4 5]]

; Argument destructuring
(defn swap-pairs [[a b] [c d]]
  [[a c] [b d]])

(swap-pairs [1 2] [3 4]) ; => [[1 3] [2 4]]
```


## Macro support

Macros, quoting and unquoting are supported:

```lisp
(defmacro defn- [name args body]
  '(def ~name (fn ~args ~body)))

(defn- sum [a b]
  (+ a b))

(sum 4 5)
```


## Ruby interoperability

```lisp
; Ruby methods can be called the same way as LISP functions, just prepend a
; dot to the method name, pass the receiver as the first argument, followed
; by any other argument:

(.join ["highway" "to" "the" "danger" "zone"] " ")

; Ruby constants, modules and classes are available, just use Foo/Bar instead
; of Foo::Bar:

(defn circle-area [radius]
  (* 2 Math/PI radius))
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake rspec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/lucaong/risp.


## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

