# Curaclam

<img width="1645" height="1275" alt="image" src="https://github.com/user-attachments/assets/2ac7b4f5-87f3-45ba-90bd-fc674d72f9ab" />

<img width="2157" height="1268" alt="image" src="https://github.com/user-attachments/assets/fa69ba72-90da-4771-8ff4-4b9e3a0ee118" />

<img width="2266" height="872" alt="image" src="https://github.com/user-attachments/assets/6559a296-eac6-46f7-bfb3-b11839d94dd3" />

This app can help you to upload a cv file and delegate the analyis to a local or cloud LLM model and see the info organized in a nice dashboard.

## How to run
```bash
rails s
```

## How to setup LLM model and provider

Just update/adjust the `ruby_llm.rb` and check the https://rubyllm.com/ docs setup your own LLM setup.

```ruby
RubyLLM.configure do |config|
  # OpenAI Configuration
  # Get your API key from: https://platform.openai.com/api-keys
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)

  # Anthropic Configuration (Claude)
  # Get your API key from: https://console.anthropic.com/
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", nil)

  # Google Gemini Configuration
  # Get your API key from: https://makersuite.google.com/app/apikey
  config.gemini_api_key = ENV.fetch("GEMINI_API_KEY", nil)

  config.ollama_api_base = "http://localhost:11434/v1"

  # Default model to use for chat completions
  # Uncomment and modify based on your preferred provider:
  config.default_model = "qwen2.5:latest"

  # Request timeout in seconds (default is 120)
  config.request_timeout = 120

  # Maximum number of retries for failed requests (default is 3)
  config.max_retries = 3

  # Use Rails logger for debugging
  config.logger = Rails.logger if defined?(Rails)
end
```
