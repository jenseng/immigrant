# Changelog

## 0.3.2

* Add rake task that checks for missing keys

## 0.3.1

* Fix schema dumping regression in rails <= 4.1 (fixes #20)

## 0.3.0

* Rails 4.2+ `:on_update` / `:on_delete` fixes (fixes #18)
* Rails 5.0 compatibility fix
* Better invalid association detection (fixes #2, #16)
* Ignore view-backed models (fixes #17)

## 0.2.0

* Rails 4.2 support

## 0.1.8

* Fix gemspec issue (fixes #13)

## ~~0.1.7 broken~~

* Rails 4.1 HABTM fix (fixes #10)

## 0.1.6

* Fix :primary_key bug (fixes #9)
* Expand test matrix

## 0.1.5

* Rails 4 support
* Rails 3.1 fix (fixes #7)

## 0.1.4

* Fix HABTM/:join_table bug (fixes #6)

## 0.1.3

* Load all models in all namespaces (fixes #3)

## 0.1.2

* Properly handle unknown reflection types (fixes #1)
* Use Foreigner schema dumping code

## 0.1.1

* Travis integration

## 0.1.0

* Initial release
