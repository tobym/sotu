require 'erb'
require 'json'
require 'redis'

# Extracts insights from the data prepared by analyze.rb

redis = Redis.new

num_terms = 15
top_stems = redis.zrevrange("all_stems", 0, num_terms - 1)

# most popular word that resolves to the given stem is used for the label
@labels = top_stems.map do |stem|
  redis.zrevrange(stem, 0, 0).first
end

# For sorting. name_to_val("sotu-1998-0101") # => 1998
def name_to_val(name)
  name.sub(/sotu-(\d\d\d\d).*/,'\1').to_i
end

doc_names = redis.smembers("doc_names").sort{|a,b| name_to_val(a) <=> name_to_val(b)}

# First dimension is time-series, second dimension is data points
@data = []

# doc_names are sorted in chronological order
doc_names.each do |doc_name|
  @data << top_stems.map do |stem|
    doc_stemcount_key = doc_name + '_stems'
    count = redis.zscore(doc_stemcount_key, stem).to_i
  end

  # redis.zrevrange(doc_stemcount_key, 0, 30).each do |stem|
  # end
end

sotu_data = ERB.new(File.read("sotu-data.js.erb")).result
File.open("public/js/sotu-data.js","w"){|file| file.write(sotu_data)}
