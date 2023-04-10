require "listen"
require 'daemons'
require "net/http"
require "uri"
require "json"

# options:
@directory_to_watch = "/Users/dpeck/to-transcribe/"
@directory_to_write = "/Users/dpeck/obsidian/"
@append_original_text = true
@use_daemon = true

@api_key = ENV["OPENAI_API_KEY"]

# use 'gpt-4', 'gpt-3.5-turbo', etc
@model = "gpt-3.5-turbo"

# code:
def generate_file_name
  Time.now.strftime("%Y-%m-%d %H-%M-%S") + ".md"
end

def request_gpt(chunk)
  uri = URI("https://api.openai.com/v1/chat/completions")
  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "Bearer #{@api_key}"
  request["Content-Type"] = "application/json"
  request.body = JSON.dump({
    "messages" => [
      { "role": "system", "content": "You are a helpful assistant that transcribes large text into summaries. Expound on your summaries with detailed paragraphs, pulling out key moments in the text. Keep your responses under 2000 characters" },
      { "role": "user", "content": "Please summarize this into a few long paragraphs, under 2000 characters total:\n\n #{chunk}." },
    ],
    "model" => @model,
    "temperature" => 0.5,
    "max_tokens" => 350,
  })

  puts "calling API with a chunk"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  JSON.parse(response.body)
end

def split_content(content)
  content.scan(/.{1,4800}/)
end

def process_file(file_path)
  content = File.read(file_path).gsub(/[\r\n]+/, " ")
  chunks = split_content(content)

  # In the process_file method
  gpt_responses = chunks.map do |chunk|
    puts "Sending chunk to #{@model} API"
    response = request_gpt(chunk)
    puts "Received chunk's #{@model} API response"
    response
  end

  # Before combining the responses
  puts "Combining #{@model} responses"
  result_content = gpt_responses.map do |response|
    if response["choices"] && response["choices"][0] && response["choices"][0]["message"] && response["choices"][0]["message"]["content"]
      response["choices"][0]["message"]["content"]
    else
      puts "Unexpected #{@model} response: #{response}"
      ""
    end
  end.join

  puts "Writing result to file"
  file_name = generate_file_name

  # Add metadata and Topics line to the output file
  metadata = <<~METADATA
    ---
    create_date: #{file_name.gsub(".md", "")}
    ---

    Topics:: [[GPT Summaries]]

    ---

  METADATA

  if @append_original_text
    formatted_content = metadata + result_content + "\n\n---\n\nOriginal Text:\n\n" + content
  else
    formatted_content = metadata + result_content
  end
  # save file to disk
  File.write(File.join(@directory_to_write, file_name), formatted_content)
  puts "Done"
end

listener = Listen.to(@directory_to_watch) do |modified, added, removed|
  added.each do |added_file|
    if File.extname(added_file) == ".txt"
      process_file(added_file)
    end
  end
end

if @use_daemon
  def daemon_running?(pid_file_path)
    if File.exist?(pid_file_path)
      pid = File.read(pid_file_path).to_i
      Process.kill(0, pid)
      true
    else
      false
    end
  rescue Errno::ESRCH, Errno::ENOENT
    false
  end

  pid_file_path = "/tmp/gpt-4-listen-and-summarize.pid"
  if daemon_running?(pid_file_path)
    puts "Daemon process already running"
  else
    Daemons.run_proc('gpt-4-listen-and-summarize', :pidfile => pid_file_path) do
      listener.start
      sleep
    end
  end
else
  puts "Listener started"
  listener.start
  sleep
end
