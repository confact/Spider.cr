require "lexbor"
require "uri"
require "./checked/**"
require "./next_urls/**"
class SpiderURLException < Exception; end

class Spider
  Log = ::Log.for("Spider")

  getter checked_urls : VisitedFile = VisitedFile.new("./checked_urls.csv")
  getter next_urls : NextFile = NextFile.new("./next_urls.csv")
  getter every_page_urls : Proc(URI, Nil)?
  getter every_page : Proc(Lexbor::Parser, URI, Nil)?

  setter amount_workers : Int32 = 20
  setter prefix_url : String?

  @channel = Channel({Lexbor::Parser, URI}).new

  @start_url : URI

  def self.start(start_url : String)
    Log.info { "RUNNING SPIDER ON #{Crystal.env.name}"}
    instance = new(URI.parse(start_url))
    yield instance
    instance.start!
  end

  def initialize(@start_url)
    add_link_to_visit(@start_url.to_s)
  end

  def add_link_to_visit(link : String)
    @next_urls << link unless @next_urls.includes?(link)
  end

  def add_link_to_visit(link : URI)
    add_link_to_visit(link.to_s)
  end

  def add_checked(link : URI)
    @checked_urls << link.to_s
  end

  def every_page=(callback : Proc(Lexbor::Parser, URI, Nil))
    @every_page = callback
  end

  def every_page_urls=(callback : Proc(URI, Nil))
    @every_page_urls = callback
  end

  def start!
    spawn_workers
    go_through_pages
  end

  private def spawn_workers
    return if every_page.nil?

    @amount_workers.times do
      spawn do
        until @channel.closed?
          data, url = @channel.receive
          every_page.try(&.call(data, url))
        end
      end
    end
  end

  private def go_through_pages
    while
      next_urls = @next_urls[0..5]
      next_urls.each do |uri|
        next if @checked_urls.includes?(uri)
        url = URI.parse(uri)
        response = get_http_client(url)
        raise SpiderURLException.new unless response
        raise SpiderURLException.new if response.try(&.status_code) >= 400
        raise SpiderURLException.new if response.try(&.body.empty?)
        data = Lexbor::Parser.new(response.body)
        call_page_commands(data, url)
        add_checked(url)
      rescue e : SpiderURLException
        Log.error(exception: e) { "Error" }
        next
      end
      break if @next_urls.empty? && @channel.closed?
    end
  end

  private def call_page_commands(data : Lexbor::Parser, url : URI)
    get_urls(data) do |link|
      next if link.nil?
      parsed_link = parse_url(link.not_nil!)
      every_page_urls.try(&.call(parsed_link)) unless link.nil?
    end unless every_page_urls.nil?

    @channel.send({data, url})

  rescue e : Exception
    Log.error(exception: e) { "command error" }
  end

  private def get_urls(data : Lexbor::Parser)
    data.nodes(:a).each do |link|
      yield link.attribute_by("href")
    end
  end

  private def parse_url(url)
    uri = URI.parse(url)
    return @start_url.resolve(url) if uri.relative?
    uri
  end

  def get_http_client(url : String)
    get_response(urler)
  end

  def get_response(url : String)
    urler = if @prefix_url
      "#{@prefix_url}#{url.to_s}"
    else
      url.to_s
    end
    uri = URI.parse(urler)
    p! uri
    client = HTTP::Client.new(uri)
    Log.debug { "client uri: #{uri}" }
    client.read_timeout = 30
    client.connect_timeout = 60
    client.get(uri.request_target)
  rescue e : Exception
    Log.error(exception: e) { "Error" }
    return nil
  end

  def get_http_client(url : URI)
    get_response(url.to_s)
  end


end
