# frozen_string_literal: true

# RubyLLM Configuration
# This initializer configures the RubyLLM gem for AI-powered CV analysis.
#
# You need to set at least one API key for the LLM provider you want to use.
# It's recommended to use environment variables to store your API keys securely.
#
# Supported providers:
# - OpenAI (GPT-4, GPT-3.5, etc.)
# - Anthropic (Claude)
# - Google (Gemini)
# - And more...
#
# To get started:
# 1. Sign up for an API key from your preferred provider
# 2. Set the corresponding environment variable:
#    - For OpenAI: export OPENAI_API_KEY=your_key_here
#    - For Anthropic: export ANTHROPIC_API_KEY=your_key_here
#    - For Gemini: export GEMINI_API_KEY=your_key_here

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
  # config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", nil)

  # Default model to use for chat completions
  # Uncomment and modify based on your preferred provider:
  # config.default_model = "anthropic/claude-opus-4.5"
  config.default_model = "qwen2.5:latest"

  # Request timeout in seconds (default is 120)
  config.request_timeout = 120

  # Maximum number of retries for failed requests (default is 3)
  config.max_retries = 3

  # Use Rails logger for debugging
  config.logger = Rails.logger if defined?(Rails)
end
