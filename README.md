# SimpleApiTester

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_api_tester'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_api_tester

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/simple_api_tester/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


    location /player {
      server_name_in_redirect off;
      # выкусить префикс player перед редиректом
      # rewrite ^/player/(.*)$ /$1 break;
      # и отправить запрос в апстрим.
      proxy_pass http://player_server;
      proxy_set_header Host <%= @player_server %>;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_redirect     off;
    }

  upstream player_server {
    server <%= @player_server %>;
  }

player_server:    node[:nginx][:book_player_host].split('://').last,
