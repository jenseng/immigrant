# Immigrant
[<img src="https://secure.travis-ci.org/jenseng/immigrant.png?rvm=1.9.3" />](http://travis-ci.org/jenseng/immigrant)

Immigrant gives Rails a foreign key migration generator so you can
effortlessly find and add missing keys. This is particularly helpful
when you decide to add keys to an established Rails app.

## Installation

Add the following to your Gemfile:

```ruby
gem 'immigrant'
```

If you're using a version of Rails prior to 4.2, you'll also need the
[Foreigner](https://github.com/matthuhiggins/foreigner) gem.

## Usage

```bash
rails generate immigration AddKeys
```

This will create a migration named AddKeys which will have `add_foreign_key`
statements for any missing foreign keys. Immigrant infers missing ones by
evaluating the associations in your models (e.g. `belongs_to`, `has_many`, etc.).
Only missing keys will be added; existing ones will never be altered or
removed.

### Rake Task

To help you remember to add keys in the future, there's a handy rake
task you can add to your CI setup.  Just run `rake immigrant:check_keys`,
and if anything is missing it will tell you about it and exit with a
non-zero status.

## Considerations

If the data in your tables is bad, then the migration will fail to run
(obviously). IOW, ensure you don't have orphaned records **before** you try to
add foreign keys.

## Known Issues

Immigrant currently only looks for foreign keys in `ActiveRecord::Base`'s
database. So if a model is using a different database connection and it has
foreign keys, Immigrant will incorrectly include them again in the generated
migration.

## [Changelog](CHANGELOG.md)

## License

Copyright (c) 2012-2015 Jon Jensen, released under the MIT license
