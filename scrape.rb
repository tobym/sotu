require 'nokogiri'
require 'open-uri'
require 'readability' # need tobym's fork to work with Ruby 1.9.1

index = URI.parse("http://www.c-span.org/Executive/State-of-the-Union.aspx")
doc = Nokogiri::HTML(open(index.to_s))

links = []
doc.css('div.links td a').each do |link|
  next unless link.content.strip == "Transcript"
  links << link
end

threads = []
links.each do |link|
  threads << Thread.new do
    href = link.attr("href")
    next if href.strip.match(/pdf$/) # Nixon's 5 speeches are in PDF scans, unfortunately
    uri = URI.parse(href)
    uri.scheme, uri.host = index.scheme, index.host
    source = open(uri.to_s).read
    html_content = Readability::Document.new(source).content
    filename = uri.path.split('/').last.sub(/.aspx?/,".html")
    File.open(File.join("content",filename),"w") {|file| file.write(html_content)}
  end
end

threads.each{|t| t.join}
