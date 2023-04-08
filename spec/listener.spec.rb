require "minitest/autorun"

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
end
