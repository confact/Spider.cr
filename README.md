# Spider

An spider class built to go through pages on urls based on some rules. And then go through those pages on those urls.

This is heavily inspired by the ruby gem `spider`: https://github.com/johnnagro/spider

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     spider:
       github: confact/spider.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "spider"
```

And then set up the spider config like this:

```crystal
Spider.start("https://google.com") do |s|
  s.amount_workers = 30
  s.every_page_urls = ->(url : URI) {
    if /^https:\/\/news.ycombinator.com\/.*/ =~ url.to_s
      s.add_link_to_visit(url)
    end
    if /^https:\/\/indiehackers.com\/.*/ =~ url.to_s
      s.add_link_to_visit(url)
    end
  }

  s.every_page = ->(data : Lexbor::Parser, url : URI) {
    # run either the whole data process here or move it to another class and call it here,
    # we give you the Lexbor::Parser class directly so you can use it freely,
    # and the url to handling different process depending on url getting process.
  }
end
```

This will run the spider and it will block any code below it.

## Configuration

### prefix_url
If you have a proxy api you use, you can set it here.

it usually is a url and then set the url you want to go to as a  query parameter.

As example:

```crystal
s.prefix_url = "https://app.scrapingbee.com/api/v1/?api_key={api_key}&render_js=true&url="
```

### Storage of visited urls and queue urls
We plan to expand to different ways to store the visited urls and queue urls. Right now it is hardcoded to use the text files only.

Ideas of future storage:
* Redis
* Memcached
* Database
* some custom API

## Todo:
This is working and is doing pretty good on some production systems. But it could do some more things better:
* failure handling, have a custom way to handle them in the start block.
* More storage possibility, and a way to set it in start block.
* It is keeping up and running even if it is done. As the while check seems to not work fully.


## Contributing

Would love some contributions. As example the concurrency support, as I am new to that.

1. Fork it (<https://github.com/confact/spider/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Håkan Nylén](https://github.com/confact) - creator and maintainer
