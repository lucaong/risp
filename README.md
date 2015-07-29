# Risp

`Risp` is a LISP implementation written in Ruby (because why not?). The syntax
is reminescent of Clojure, and it support calling Ruby methods.

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

```lisp
(defn dec [n]
  (- n 1))

(defn fact [n]
  (if (<= n 1)
    1
    (* n (fact (dec n)))))

(fact 10)
```

## Macro support

```lisp
(defmacro defn- [name args body]
  '(def ~name (fn ~args ~body)))

(defn- sum [a b]
  (+ a b))

(sum 4 5)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/risp.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

