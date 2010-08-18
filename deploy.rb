# Scans your project for CSS and JS files and 
# runs them through the Yahoo Compression utility
# and then uploads the entire site to your web server via SCP.

# Configure your settings below and be sure
# to supply the proper path to the Yahoo compressor.  
# Set the COMPRESS flag to false to skip compression

COMPRESS = true
WORKING_DIR = "working"
REMOTE_USER = "ecruby"
REMOTE_HOST = "ecruby.org"
REMOTE_PORT = 22
REMOTE_DIR = "/home/#{REMOTE_USER}/#{REMOTE_HOST}/"
LOCAL_DIR = "site"
FILES = ["index.html",
         "jobs.html",
         'open_house.html',
         'cvrc2010.html',
         'chat.html',
         'contact.html',
         "presentations.html",  
         'getting_started_with_ruby.html',
         "resources.html",
         "meetings.html",
         "stylesheets",
         "images"
        ]

COMPRESSOR_CMD = 'java -jar ../bin/yuicompressor-2.4.2.jar'

# DONE CONFIGURING

require 'rubygems'
require 'net/scp'
require 'fileutils'

@errors = [] 
puts "Building page"
`staticmatic build .`
puts "Done building"

Dir.chdir(LOCAL_DIR)
FileUtils.rm_rf WORKING_DIR

puts "Copying working files"
FileUtils.mkdir WORKING_DIR
FILES.each do |f|
  if File.directory?(f)
    FileUtils.cp_r f, WORKING_DIR
  else
    FileUtils.cp f, WORKING_DIR
  end
end

# Upload files in our working directory to the server
def upload
  "*** UPDATING ***"
  system("rsync -avz --delete #{WORKING_DIR}/ #{REMOTE_USER}:#{REMOTE_DIR}")
end


# Minify all CSS and JS files found within the working
# directory
def minify(working_dir)
  files = Dir.glob("#{working_dir}/**/*.{css, js}")
  
  files.each do |file|
    type = File.extname(file) == ".css" ? "css" : "js"
    newfile = file.gsub(".#{type}", ".new.#{type}")
    puts "minifying #{file}"
    `#{COMPRESSOR_CMD} --type #{type} #{file} > #{newfile}`

    if File.size(newfile) > 0
      FileUtils.cp newfile, file
      FileUtils.rm newfile
    else
      @errors << "Unable to process #{file}."
    end
  
  end
end
  
if COMPRESS
  puts "Minifying CSS and JS files"
  minify(WORKING_DIR) 
end

if @errors.length == 0
  puts "Deploying"
  upload
else
  puts "Unable to deploy."
  @errors.each{|e| puts e}
end
