# gpt-4-listen-and-summarize

This Ruby script will watch a folder for new text files, summarizes them, and save them to a different folder.

Does the work of breaking down very large text files into multiple smaller chunks (to get around the API's "max length") and stitching together the responses for you.

## Setup

1. `gem install listen`
2. You'll need an [OpenAI API key](https://platform.openai.com/account/api-keys), set as an env variable (OPENAI-API-KEY)
3. `ruby listen.rb`

Build using Ruby 3.2.1

```
ruby 3.2.1 (2023-02-08 revision 31819e82c8) [x86_64-darwin21]
```
