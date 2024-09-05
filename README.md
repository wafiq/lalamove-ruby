# Lalamove API (V3) Ruby SDK

A Ruby SDK for the Lalamove V3 API, allowing you to easily integrate Lalamove's delivery services into your Ruby applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lalamove'
```

Then, run `bundle install`. Or install the gem directly from the command line:

```sh
gem install lalamove
```

## Usage

```ruby
require 'lalamove'

client = Lalamove::Client.new(
  api_key: 'your_api_key',
  api_secret: 'your_api_secret',
  market: 'my'
)

client.cities

client.get_quotation(quotation_details)

client.create_order(order_details)

client.get_order(order_id)

client.cancel_order(order_id)

client.get_driver_details(order_id, driver_id)

client.add_priority_fee(order_id, priority_fee)
```

Please refer to the [Lalamove API Documentation](https://developers.lalamove.com/#introduction) for more details on each endpoint and how to use them.

## Development

To install this gem onto your local machine, run `bundle install`. Copy the `.env.example` file to `.env` and set the correct environment variables. Run `bundle exec rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wafiq/lalamove-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/wafiq/lalamove-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lalamove Ruby SDK project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wafiq/lalamove-ruby/blob/main/CODE_OF_CONDUCT.md).
