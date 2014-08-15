#VK-RUBY
[![Build Status](https://secure.travis-ci.org/zinenko/vk-ruby.png)](http://travis-ci.org/zinenko/vk-ruby)
[![Code Climate](https://codeclimate.com/github/zinenko/vk-ruby/badges/gpa.svg)](https://codeclimate.com/github/zinenko/vk-ruby)
[![Gem Version](https://badge.fury.io/rb/vk-ruby.svg)](http://badge.fury.io/rb/vk-ruby)
[![Dependency Status](https://gemnasium.com/zinenko/vk-ruby.svg)](https://gemnasium.com/zinenko/vk-ruby)

Ruby wrapper for vk.com API.

__VK-RUBY__ gives you full access to all API features.
Has several types of method naming and methods calling, optional authorization, file uploading, logging, irb integration, parallel method calling and any faraday-supported http adapter of your choice.

To get started working with vk.com API.
First of all, to [register](http://vk.com/editapp?act=create) your own application and obtain the keys.
Read [vk api documentation](http://vk.com/developers.php).

[vk-ruby documentation](http://rubydoc.info/github/zinenko/vk-ruby/master/frames)

## Installation

```.bash
gem install vk-ruby
```

## How to use

### Create new application

```.ruby
app = VK::Application.new(app_id: 1, version: '5.20', access_token: '[TOKEN]')
```

### API method calling

```.ruby
app.friends.getOnline uid: 1 # => Online friends
```
__or__

```.ruby
app.friends.get_online uid: 1 # => Online friends
```
__or__

```.ruby
app.vk_call 'friends.getOnline', {uid: 1} # => Online friends
```

### Parallel API method calling

__VK-RUBY__ also supports parallel execution of requests.
[More information about parallel requests](https://github.com/lostisland/faraday/wiki/Parallel-requests).


```.ruby
require 'typhoeus'
require 'typhoeus/adapters/faraday'

app.adapter = :typhoeus

manager = Typhoeus::Hydra.new(max_concurrency: 10) # (200 is default)
#manager.disable_memoization

uids = { 1 => {}, 2 => {}, 3 => {}}

app.in_parallel(manager) do 
  uids.each do |uid,_|
    app.users.get(user_ids: uid).each do |user|
      uids[user["id"]] = user
    end
  end
end

puts uids 
#=> {
#  1 => {"id"=>1, "first_name"=>"Павел", "last_name"=>"Дуров"}, 
#  2 => {"id"=>2, "first_name"=>"Александра", "last_name"=>"Владимирова", "hidden"=>1}, 
#  3 => {"id"=>3, "first_name"=>"DELETED", "last_name"=>"", "deactivated"=>"deleted"}
#}

```

### Uploading files

Uploading files to vk servers performed in 3 steps:

1. Getting url to download the file.
2. File download.
3. Save the file.

The first and third steps are produced by calls to certain API methods as described above.
Details downloading files, see the [relevant section of the documentation](https://vk.com/dev/upload_files).

When you call the upload also need to specify the mime type file.

```.ruby
app.upload(
  'http://example.vk.com/path',{
    file1: ['/path/to/file1.jpg', 'image/jpeg'],
    file2: [File.open('/path/to/file2.png'), 'image/png', '/path/to/file2.png'] 
})

```

or 

```.ruby
app.upload(
  'http://example.vk.com/path',[
    ['/path/to/file1.jpg', 'image/jpeg'],
    [File.open('/path/to/file2.png'), 'image/png', '/path/to/file2.png']
])

```

### Authorization

[VK](vk.com) has several types of applications and several types of authorization. 
They are different ways of authorization and access rights, more details refer to the [documentation](https://vk.com/dev/authentication).

#### Site

Site authorization process consists of 4 steps:

1. Opening the browser to authenticate the user on the site __VK__
2. Permit the user to access their data
3. Transfer site value code for the access key
4. Preparation of the application server access key `access_token` to access the API __VK__

For the first step you need to generate correct URL

```.ruby
app.authorization_url({
  type: :site,
  app_id: 123,
  settings: 'friends,audio',
  version: '5.20',
  redirect_uri: 'https://example.com/'
})

#=> "https://oauth.vk.com/authorize?client_id=123&scope=friends,audio&redirect_uri=https://example.com/&response_type=token&v=5.20"

```

Once user permit the to access their data, on specified `:redirect_url` come __GET__ request with `code` parameter, which is used to obtain an `access_token`.

```.ruby
app.site_auth(code: request_params[:code]) #=> { "access_token" : '[TOKEN]', "expires_in" : "100500"}
```

#### Server

To access the [administrative methods API](https://vk.com/dev/secure), which does not require user authentication, you need to get a special `access_token`. To obtain the key required when creating an application to specify the correct `:app_id` and `:app_secret` to the method `server_auth`.

```.ruby
app.server_auth(app_id: '[APP_ID]', app_secret: '[SECRET]') #=> { "access_token" : '[TOKEN]' }

```

#### Standalone (Client)

__VK__ have a client authentication method, it implies a use of using a browser on the client (for example, `UIWebView` component when creating applications for __iOS__). In __RUBY__ we can not afford it, and so we use the [Mechanize](https://rubygems.org/gems/mechanize). Most likely it is contrary to the rules of use API, so be careful ;-)

__VK__ implies that the authorization process will consist of three steps: 

- Opening the browser to authenticate the user on the site __VK__
- Permit the user to access their data
- Transfer to the application key `access_token` to access the API

But __VK-RUBY__ reduces this process in just a single method call

```.ruby
app.client_auth(login: '[LOGIN]', password: '[PASSWORD]') #=> { "access_token" : '[TOKEN]', "expires_in" : "100500"} }
```

### Configuration

|         Name        |     Description   |   Default  |
| :------------------ |:------------------| ----------:|
| :app_id             | Application ID | `nil` |
| :app_secret         | Application secret | `nil` |
| :version            | API version  | `'5.20'` |
| :redirect_uri       | Application redirect URL | `nil` |
| :settings           | Application settings | `'notify,friends,offline'` |
| :access_token       | Access token | `nil` |
| :verb               | HTTP verb | `:post` |
| :host               | API host | https://api.vk.com |
| :proxy              | Proxy settings | nil |
| :ssl                | SSL settings | ``` { verify: true, verify_mode: OpenSSL::SSL::VERIFY_NONE } ``` |
| :timeout            | Request timeout | `10` |
| :open_timeout       | Open connection timeout | `3` |
| :middlewares        | Faraday middlewares stack | [_see middlewares section_](#Middlewares) |
| :parallel_manager   | Parallel request manager  | `nil` |


More information on configuring ssl documentation [faraday](https://github.com/lostisland/faraday/wiki/Setting-up-SSL-certificates)

### Middlewares

__VK-RUBY__ based on [faraday](https://github.com/lostisland/faraday).

It is an __HTTP__ client lib that provides a common interface over many adapters (such as `Net::HTTP`) and embraces the concept of [Rack](https://github.com/rack/rack) middleware when processing the `request/response` cycle.

[Advanced middleware usage](https://github.com/lostisland/faraday#advanced-middleware-usage).

#### Default stack

This stack consists of standard `:multipart`,`:url_encoded`, `:json` middlewares, details of which are looking at [here] (https://github.com/lostisland/faraday#advanced-middleware-usage). 

Are also used: 

- `:vk_logger` performs logging of `requests` and `responses `
- `:http_errors` throws an exception if the __HTTP__ status header is different from the 200 
- `:api_errors` throws an exception if the server response contains the __API__ error

And here is set on the default HTTP adapter (`Net::HTTP`).

```.ruby
app.middlewares = proc do |faraday|
  faraday.request :multipart
  faraday.request :url_encoded

  faraday.response :vk_logger
  faraday.response :api_errors
  faraday.response :json, content_type: /\bjson$/
  faraday.response :http_errors

  faraday.adapter Faraday.default_adapter
end
```

#### Expanding stack

```.ruby
app.middlewares = proc do |faraday|
  faraday.request :multipart
  faraday.request :url_encoded
  faraday.request :retry, max: 5,
                          interval: 0.3,
                          interval_randomness: 0.5,
                          backoff_factor: 2,
                          exceptions: [VK::ApiException,
                                       VK::BadResponseException,
                                       Faraday::TimeoutError]

  faraday.response :api_errors
  faraday.response :json, content_type: /\bjson$/
  faraday.response :http_errors
  faraday.response :vk_logger, Logger.new('/path/to/file.log')

  faraday.adapter :net_http_persistent
end
```

In this example, additional used [:retry](https://github.com/lostisland/faraday/blob/master/lib/faraday/request/retry.rb) middleware. It allows you to conveniently handle certain exceptions specified number of times with a certain interval – very convenient ;-) Also defined here is not the default __HTTP__ adapter [(Net::HTTP::Persistent)](https://github.com/drbrain/net-http-persistent).

Read more [middleware usage](https://github.com/lostisland/faraday#advanced-middleware-usage).

## Contributing to vk-ruby

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.

## Copyright

Copyright (c) 2014 [Andrew Zinenko](http://izinenko.ru). 
See LICENSE.txt for further details.
