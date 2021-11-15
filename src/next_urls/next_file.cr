class NextFile

  @filepath : String
  @urls : Array(String)

  # Construct a new IncludedInFile instance.
  # @param filepath [String] as path of file to store crawled URL
  def initialize(@filepath)
    # create file if not exists
    FileUtils.touch(@filepath) unless File.exists?(@filepath)
    @urls = File.read_lines(@filepath).map(&.strip)
  end

  # Add an item to the file & array of URL.
  def <<(v : String)
    @urls << v
    File.write(@filepath, "#{v}\r\n", mode: "a")
  end

  # True if the item is in the file.
  def includes?(v : String) : Bool
    @urls.includes? v
  end

  def [](key) : Array(String)
    chunk_urls = @urls.delete_at(key)
    File.write(@filepath, @urls.join("\r\n"), mode: "w")
    chunk_urls
  end

  def empty?
    @urls.empty?
  end
end
