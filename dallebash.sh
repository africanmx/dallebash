#!/bin/bash

CONFIG_FILE="$HOME/.dalle_config"
API_KEY_FILE="$HOME/.openai_api_key"
OUTPUT_DIR="$HOME/.dalle_output_dir"

# Function to prompt for API key and store it
get_api_key() {
    read -p "Enter your OpenAI API key: " api_key
    echo "$api_key" > "$API_KEY_FILE"
}

# Function to prompt for output directory and store it
get_output_dir() {
    read -p "Enter your desired output directory: " output_dir
    echo "$output_dir" > "$OUTPUT_DIR"
}

# Function to load config
load_config() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
    [ -f "$API_KEY_FILE" ] && api_key=$(cat "$API_KEY_FILE") || get_api_key
    [ -f "$OUTPUT_DIR" ] && output_dir=$(cat "$OUTPUT_DIR") || get_output_dir
}

# Function to save config
save_config() {
    echo "api_key=\"$api_key\"" > "$CONFIG_FILE"
    echo "output_dir=\"$output_dir\"" >> "$CONFIG_FILE"
}

# Function to set configuration
set_config() {
    echo "Configuring DALL-E settings:"
    get_api_key
    get_output_dir
    save_config
}

# Function to show wizard
wizard() {
    set_config
}

# Function to interact with DALL-E
generate_image() {
    prompt="$1"
    echo "Generating image, please wait..."
    response=$(curl -s -X POST https://api.openai.com/v1/images/generations \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json" \
      -d '{
        "prompt": "'"$prompt"'",
        "n": 1,
        "size": "1024x1024"
      }')
    image_url=$(echo "$response" | grep -oP '(?<="url": ")[^"]*')
    image_name=$(date +"%Y%m%d%H%M%S").png
    curl -s "$image_url" -o "$output_dir/$image_name"
    echo "Image saved to $output_dir/$image_name"
}

# Function to handle prompts
prompt_loop() {
    while true; do
        echo -e "\nEnter your prompt for DALL-E (Ctrl+Enter to send, Ctrl+C to exit):"
        prompt=""
        while IFS= read -e -p "> " -r line; do
            if [[ -z "$line" ]]; then
                break
            fi
            prompt+="$line\n"
        done
        prompt=${prompt%\\n}  # Remove the trailing newline
        [ -n "$prompt" ] && generate_image "$prompt"
    done
}

# Function to display help
show_help() {
    echo "DALL-E Terminal Chat"
    echo ""
    echo "Usage: dalle_chat [OPTIONS] [PROMPT]"
    echo ""
    echo "Options:"
    echo "  --config      Configure API key and output directory."
    echo "  --wizard      Run the configuration wizard."
    echo "  --help        Show this help message and exit."
    echo ""
    echo "Examples:"
    echo "  dalle_chat --config"
    echo "  dalle_chat --wizard"
    echo "  dalle_chat 'A futuristic cityscape at sunset'"
    echo ""
    echo "When run without arguments, the script will enter interactive mode."
}

# Main logic
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --config|--set) set_config; shift ;;
        --wizard) wizard; shift ;;
        --help) show_help; exit 0 ;;
        *) break ;;
    esac
done

load_config

if [[ "$#" -gt 0 ]]; then
    prompt="$*"
    generate_image "$prompt"
else
    prompt_loop
fi
