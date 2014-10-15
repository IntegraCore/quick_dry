## What is QuickDry?

Have you ever went to the console to run a rails scaffold and wondered why 20 new files are required for every 1 new model?  If you have then, this Engine just might be fore you.  QuickDry is built on the assumption that you want to display your tables through a web interface, and that you want to interact with them all in the same way.  It takes and consolidates 14 of the 20 files produced with a scaffold into the QuickDry Engine.  So you only have to create a model and the controller and view is already taken care of in a much DRYer way.  This library is ideal for the developer that has an app dealing heavily with displaying data from their models and wants just the default rails views and controller methods.

## Getting started

QuickDry 0.0.1 works with Rails 4.0 onwards. You can add it to your Gemfile with:

```ruby
gem 'quick_dry'
```

Run the bundle command to install it.

```console
bundle install
```
Add the following to your routes.rb file (put it at the top if you want QuickDry to handle all your models, or put it at the bottom to catch all requests not otherwise specified above it):

```ruby
mount RequestRefinery::Engine, at:'/'
```