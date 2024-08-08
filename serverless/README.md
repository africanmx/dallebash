# DALL-E Serverless Backend

A serverless backend implementation for interacting with OpenAI's DALL-E API. This backend supports generating images from text prompts and can be used in conjunction with the DALL-E Terminal Chat.

## Features

- Generate images from text prompts using the OpenAI API.
- Configurable through environment variables.
- Docker support for easy deployment.

## Requirements

- Node.js (v14.x or later)
- Docker (for containerized deployment)
- Docker Compose (for managing multi-container Docker applications)

## Installation

### Local Setup

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd dallebash/serverless
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Create a `.env` file from the example:

   ```bash
   cp .env.example .env
   ```

4. Update the `.env` file with your OpenAI API key and other configuration settings.

### Docker Deployment

1. Build and run the Docker container:

   ```bash
   docker-compose up --build
   ```

2. The backend will be accessible at `http://localhost:3000` by default.

## Usage

### Generating Images

The backend exposes an endpoint to generate images. You can interact with it using HTTP POST requests.

**Example Request:**

```bash
curl -X POST http://localhost:3000/generate -H "Content-Type: application/json" -d '{"prompt": "Your prompt here"}'
```

**Example Response:**

```json
{
  "image_url": "http://localhost:3000/images/generated_image.png"
}
```

### Configuration

To change the API key or other configuration settings, update the `.env` file.

## Testing

Run the provided test script to verify the setup:

```bash
./test.sh
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
