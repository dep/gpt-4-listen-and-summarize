# gpt-4-listen-and-summarize

This Ruby script will watch a folder for new text files, summarize them with GPT (using gpt-4, gpt-3.5-turbo, or another model of your choosing, by updating @model in the script), and save them to a different folder. I'm using this in conjunction with [recorder.google.com](https://recorder.google.com) which does a very nice job of transcribing long conversations and offering a .txt download feature.

Breaks down very large text files into multiple smaller chunks (to get around the API's "max length") and stitches together the responses for you.

I save mine right to my Obsidian vault but you might have other use cases.

## Setup

1. `gem install listen`
2. You'll need an [OpenAI API key](https://platform.openai.com/account/api-keys), set as an env variable (OPENAI-API-KEY)
3. `ruby listen.rb`

Build using Ruby 3.2.1

```
ruby 3.2.1 (2023-02-08 revision 31819e82c8) [x86_64-darwin21]
```
