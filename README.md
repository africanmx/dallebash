# DALL-E Terminal Chat

A comprehensive Bash script to interact with OpenAI's DALL-E API, allowing users to generate images from text prompts directly from their terminal. The script supports configuration management and stores generated images in a user-defined directory.

## Features

- Generate images from text prompts using the OpenAI API.
- Store generated images in a specified output directory.
- Configuration management for API key and output directory.
- Easy to set up and use.
- Configuration wizard for initial setup and changes.
- Continuous prompt input, allowing multiple images to be generated in one session.
- Multiline input support.

## Requirements

- Bash
- curl
- jq

## Installation

Run the provided `install.sh` script to set up the necessary files and permissions.

```bash
./install.sh
```

## Usage

### Initial Setup

To configure your API key and output directory, run:

```bash
dallebash --config
```

or

```bash
dallebash --wizard
```

### Generating Images

To generate an image from a text prompt, run:

```bash
dallebash "Your prompt here"
```

You can also run the script without arguments to enter the prompt interactively:

```bash
dallebash
```

While in interactive mode, enter your prompt and press **Ctrl+Enter** to submit. The program will stay active and ask for the next prompt or you can exit by pressing **Ctrl+C**.

### Help

To display the help message, use:

```bash
dallebash --help
```

### Configuration

To change the API key or output directory, use:

```bash
dallebash --config
```

or

```bash
dallebash --wizard
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
