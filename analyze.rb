require 'nokogiri'
require 'redis'
require 'stemmer'

# Given a file, return words. This will:
#   * strip HTML tags
#   * tokenize based on word characters,
#     - preserving apostrophes (e.g. "I've" is a word token)
#   * not return empty tokens
#   * downcase all string
def tokenize(file)
  doc = Nokogiri::HTML(open(file))
  doc.content.split(/[^'\w]/).reject{|token| token == ""}.map{|token| token.downcase}
end

redis = Redis.new
redis.flushdb

files = File.join("content", "*.html")
Dir.glob(files).each do |file|
  doc_name = file.downcase.sub(/content.(.*).html/,'\1')
  redis.sadd 'doc_names', doc_name
  doc_wordcount_key = doc_name + '_words'
  doc_stemcount_key = doc_name + '_stems'
  tokenize(file).each do |word|
    stem = word.stem
    redis.sadd 'stems', stem # track all stems in entire corpus
    redis.zincrby stem, 1, word # track most common word for a given stem
    redis.zincrby doc_wordcount_key, 1, word # track word frequency in this document
    redis.zincrby doc_stemcount_key, 1, stem # track stem frequency in this document
  end
end

