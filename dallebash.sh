#!/bin/bash

CONFIG_FILE="$HOME/.dalle_config"
API_KEY_FILE="$HOME/.openai_api_key"
OUTPUT_DIR_FILE="$HOME/.dalle_output_dir"
DALLE_URL="https://api.openai.com/v1/images/generations"
GPT4_API_URL="https://api.openai.com/v1/chat/completions"

show_progress_animation() {
    chars="/-\|"
    while :; do
        for ((i = 0; i < ${#chars}; i++)); do
            sleep 0.1
            echo -en " Working... ${chars:$i:1} " "\r"
        done
    done
}

stop_progress_animation() {
    kill $1
    echo -en "\033[2K"
}

get_api_key() {
    read -p "Enter your OpenAI API key: " api_key
    echo "$api_key" > "$API_KEY_FILE"
}

get_output_dir() {
    read -p "Enter your desired output directory: " output_dir
    echo "$output_dir" > "$OUTPUT_DIR_FILE"
}

load_config() {
    if [ -f "$API_KEY_FILE" ]; then
        api_key=$(cat "$API_KEY_FILE" | xargs)
    else
        get_api_key
    fi

    if [ -f "$OUTPUT_DIR_FILE" ]; then
        output_dir=$(cat "$OUTPUT_DIR_FILE")
    else
        get_output_dir
    fi

    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi
}

save_config() {
    echo "api_key=\"$api_key\"" > "$CONFIG_FILE"
    echo "output_dir=\"$output_dir\"" >> "$CONFIG_FILE"
}

set_config() {
    echo "Configuring DALL-E settings:"
    get_api_key
    get_output_dir
    save_config
}

wizard() {
    set_config
}

generate_creative_prompt() {
    original_prompt="$1"

    request_payload=$(jq -n --arg prompt "$original_prompt" \
        '{
            model: "gpt-4o-mini",
            messages: [
                {
                    role: "system",
                    content: "You are a creative assistant for image generation prompt design."
                },
                {
                    role: "user",
                    content: "Create a new image prompt based on this input: \($prompt). Make it original and different and add it your own creativity."
                }
            ],
            max_tokens: 100
        }')

    response=$(curl -s -X POST "$GPT4_API_URL" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json" \
      -d "$request_payload")

    if echo "$response" | grep -q '"error"'; then
        error_message=$(echo "$response" | jq -r '.error.message')
        echo "Error generating creative prompt: $error_message"
        return 1
    fi

    creative_prompt=$(echo "$response" | jq -r '.choices[0].message.content')
    echo "$creative_prompt"
}

generate_image() {
    show_progress_animation &

    prompt="$1"

    request_payload=$(jq -n --arg prompt "$prompt" \
        '{
            model: "dall-e-3",
            prompt: $prompt,
            n: 1,
            size: "1792x1024",
            quality: "hd",
            style: "natural"
        }')

    response=$(curl -s -X POST "$DALLE_URL" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json" \
      -d "$request_payload")

    if echo "$response" | grep -q '"error"'; then
        error_message=$(echo "$response" | jq -r '.error.message')
        echo "Error generating image: $error_message"
        stop_progress_animation $!
        return
    fi

    image_url=$(echo "$response" | jq -r '.data[0].url')
    if [ -z "$image_url" ]; then
        echo "Failed to retrieve image URL from the response."
        stop_progress_animation $!
        return
    fi

    image_name=$(date +"%Y%m%d%H%M%S").png
    curl -s "$image_url" -o "$output_dir/$image_name"
    if [ $? -eq 0 ]; then
        echo "Image saved to $output_dir/$image_name"
    else
        echo "Failed to download the image."
    fi
    stop_progress_animation $!
}

prompt_loop() {
    while true; do
        echo -e "\nEnter your prompt for DALL-E (Ctrl+D to send, Ctrl+C to exit):"
        prompt=""
        while IFS= read -e -p "> " -r line; do
            if [[ -z "$line" ]]; then
                break
            fi
            prompt+="$line\n"
        done
        prompt=${prompt%\\n}
        [ -n "$prompt" ] && generate_image "$prompt"
    done
}

generate_proactive_images() {
    original_prompt="$1"
    num_images="$2"

    echo "Will generate $num_images creatively enhanced images based on the prompt: $original_prompt ..."

    for ((i = 1; i <= num_images; i++)); do
        creative_prompt=$(generate_creative_prompt "$original_prompt")
        echo "Working on image $i: $creative_prompt ..."
        if [ $? -eq 0 ] && [ -n "$creative_prompt" ]; then
            generate_image "$creative_prompt"
        else
            echo "Skipping image $i due to error in generating creative prompt."
        fi
    done
}

show_help() {
    echo "DALL-E Terminal Chat"
    echo ""
    echo "Usage: dalle_chat [OPTIONS] [PROMPT]"
    echo ""
    echo "Options:"
    echo "  --config      Configure API key and output directory."
    echo "  --wizard      Run the configuration wizard."
    echo "  --proactive n [transformation] Generate n number of creatively enhanced images."
    echo "  --help        Show this help message and exit."
    echo ""
    echo "Examples:"
    echo "  dalle_chat --config"
    echo "  dalle_chat --wizard"
    echo "  dalle_chat --proactive 3 'A futuristic cityscape at sunset'"
    echo ""
    echo "When run without arguments, the script will enter interactive mode."
}

load_config

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --config|--set) set_config; shift ;;
        --wizard) wizard; shift ;;
        --proactive) num_images="$2"; prompt="$3"; generate_proactive_images "$prompt" "$num_images"; exit 0 ;;
        --help) show_help; exit 0 ;;
        *) break ;;
    esac
done

if [[ "$#" -gt 0 ]]; then
    prompt="$*"
    generate_image "$prompt"
else
    prompt_loop
fi
