#!/usr/bin/ruby -w

require "rubygems"
require "mysql"
listfile =  ARGV[0]
# look up program group name

encoding_options = {
    :invalid           => :replace,  # Replace invalid byte sequences
    :undef             => :replace,  # Replace anything not defined in ASCII
    :replace           => '',        # Use a blank for those replacements
    :universal_newline => true       # Always break lines with \n
}
#non_ascii_string.encode(Encoding.find('ASCII'), encoding_options)

in_file = File.open(listfile)
while cur_phrase = in_file.gets
#  cur_phrase = cur_phrase.gsub(NON_ASCII, "")
#  cur_phrase = cur_phrase.gsub(ASCII_CONTROL, "")
  # puts cur_phrase.length
    #self.gsub(/[\x80-\xff]/,replacement)
    #cur_phrase  = cur_phrase.encode(Encoding.find('ASCII'), encoding_options)
#    puts cur_phrase
    cur_phrase = cur_phrase.split(',')
    cur_phrase[6] = cur_phrase[6].gsub("\n",'')
    #puts cur_phrase[6].length
    if cur_phrase[6].length ==  4   then 
        #puts "crap" 
        cur_phrase[6] = cur_phrase[6].prepend("0")
        #puts cur_phrase[6].length
    end
    if cur_phrase[6].length ==  5 then
      puts cur_phrase.join(',')
    end
end

