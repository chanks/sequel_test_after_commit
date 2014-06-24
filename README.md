# sequel_test_after_commit

A gem to make transactional tests work with after_commit and after_rollback hooks in Sequel.

```ruby
  DB = Sequel.connect(...)
  DB.extension :test_after_commit
```

## Installation

Add this line to your application's Gemfile:

    gem 'sequel_test_after_commit'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sequel_test_after_commit

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sequel_test_after_commit/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
