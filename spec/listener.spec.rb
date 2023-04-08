require "minitest/autorun"
require "minitest/mock"
require "tempfile"

class TestTranscriptionScript < Minitest::Test
  def test_generate_file_name
    file_name = generate_file_name
    assert_match(/^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}\.md$/, file_name, "File name format is incorrect")
  end

  def test_split_content
    long_text = "a" * 10000
    chunks = split_content(long_text)
    assert_equal(3, chunks.size, "Split content should create 3 chunks")
    assert_equal(4800, chunks[0].size, "First chunk should have 4800 characters")
    assert_equal(4800, chunks[1].size, "Second chunk should have 4800 characters")
    assert_equal(400, chunks[2].size, "Third chunk should have 400 characters")
  end

  def test_process_file
    # Create a temporary input file
    input_file = Tempfile.new("test_input.txt")
    input_file.write("Example content")
    input_file.rewind

    # Mock API response
    mock_api_response = {
      "choices" => [
        {
          "message" => {
            "role" => "assistant",
            "content" => "Mock summary",
          },
        },
      ],
    }

    # Mock request_gpt4 function
    mock_request_gpt4 = Minitest::Mock.new
    mock_request_gpt4.expect(:call, mock_api_response, [String])

    # Mock File.write to prevent writing to the actual file system
    File.stub(:write, nil) do
      process_file(input_file.path, mock_request_gpt4)
    end

    # Ensure the mock_request_gpt4 function was called as expected
    mock_request_gpt4.verify

    input_file.close
    input_file.unlink
  end
end
