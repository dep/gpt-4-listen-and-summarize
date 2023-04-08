require "listen"
require "net/http"
require "uri"
require "json"

directory_to_watch = "/Users/dep/Downloads/to-transcribe"
directory_to_write = "/Users/dep/Google Drive/Obsidian/Brain 2.0/Journal"
api_key = ENV["OPENAI_API_KEY"]

def generate_file_name
  Time.now.strftime("%Y-%m-%d-%H-%M-%S") + ".md"
end

def request_gpt4(chunk, api_key)
  puts "request gpt4"
  uri = URI("https://api.openai.com/v1/chat/completions")
  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "Bearer #{api_key}"
  request["Content-Type"] = "application/json"
  request.body = JSON.dump({
    "messages" => [
      { "role": "system", "content": "You are a helpful assistant that transcribes large text into summaries. Really expound on your summaries with several detailed paragraphs, pulling out key moments in the text." },
      { "role": "user", "content": "Please summarize this using several long paragraphs:\n\n #{chunk}." },
    ],
    "model" => "gpt-4",
    "temperature" => 0.5,
    "max_tokens" => 500,
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

def process_file(file_path, api_key)
  puts "process_file"
  content = File.read(file_path).gsub(/[\r\n]+/, " ")
  chunks = split_content(content)

  # In the process_file method
  gpt_responses = chunks.map do |chunk|
    puts "Sending chunk to GPT-4 API: #{chunk}"
    response = request_gpt4(chunk, api_key)
    puts "Received GPT-4 API response: #{response}"
    response
  end

  # Before combining the GPT-4 responses
  puts "Combining GPT-4 responses"
  result_content = gpt_responses.map do |response|
    if response["choices"] && response["choices"][0] && response["choices"][0]["message"] && response["choices"][0]["message"]["content"]
      puts "GPT-4 response: #{response["choices"][0]["message"]["content"]}"
      response["choices"][0]["message"]["content"]
    else
      puts "Unexpected GPT-4 response: #{response}"
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

    Topics:: [[Journal]], [[GPT-4 Summaries]]

    ---

  METADATA

  formatted_content = metadata + result_content

  # save file to disk
  File.write("#{directory_to_write}/#{file_name}", formatted_content)
  puts "Done"
end

listener = Listen.to(directory_to_watch) do |modified, added, removed|
  added.each do |added_file|
    if File.extname(added_file) == ".txt"
      process_file(added_file, api_key)
    end
  end
end

puts "listening for files in #{directory_to_watch}"
listener.start
sleep
