# API Keys Configuration

This directory contains configuration files for API keys used in the application.

## Setup Instructions

1. Copy the `api_keys.dart.example` file to `api_keys.dart`:
   ```
   cp api_keys.dart.example api_keys.dart
   ```

2. Edit the `api_keys.dart` file and replace the placeholder values with your actual API keys:
   ```dart
   class ApiKeys {
     /// Google Gemini API key
     static const String geminiApiKey = 'your_actual_gemini_api_key_here';
     
     /// OpenAI API key (if needed)
     static const String openAIApiKey = 'your_actual_openai_api_key_here';
   }
   ```

## Security Notes

- The `api_keys.dart` file is included in `.gitignore` and should never be committed to version control.
- Only commit the `api_keys.dart.example` file with placeholder values.
- For production deployments, consider using environment variables or a secure key management system.

## Getting API Keys

### Google Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Get API key" or "Create API key"
4. Copy the key and paste it in the `api_keys.dart` file

### OpenAI API Key (if needed)

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign in to your OpenAI account
3. Click "Create new secret key"
4. Copy the key and paste it in the `api_keys.dart` file
