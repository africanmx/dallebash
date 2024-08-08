const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const axios = require("axios");

const GPT4_API_URL = "https://api.openai.com/v1/chat/completions";
const DALLE_URL = "https://api.openai.com/v1/images/generations";

// Initialize S3 Client
const s3Client = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  }
});

const apiKey = process.env.OPENAI_API_KEY;
const outputBucket = process.env.OUTPUT_BUCKET || "dalle-generated-images";

if (!apiKey) {
  throw new Error("API key is required. Set OPENAI_API_KEY environment variable.");
}

async function generateCreativePrompt(originalPrompt) {
  const requestPayload = {
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content: "You are a creative assistant for image generation prompt design."
      },
      {
        role: "user",
        content: `Create a new image prompt based on this input: ${originalPrompt}. Make it original and different and add your own creativity.`
      }
    ],
    max_tokens: 100
  };

  try {
    const response = await axios.post(GPT4_API_URL, requestPayload, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      }
    });

    return response.data.choices[0].message.content;
  } catch (error) {
    console.error("Error generating creative prompt:", error.response.data);
    throw new Error("Failed to generate creative prompt.");
  }
}

async function generateImage(prompt) {
  const requestPayload = {
    model: "dall-e-3",
    prompt: prompt,
    n: 1,
    size: "1792x1024",
    quality: "hd",
    style: "natural"
  };

  try {
    const response = await axios.post(DALLE_URL, requestPayload, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      }
    });

    const imageUrl = response.data.data[0].url;
    if (!imageUrl) {
      throw new Error("Failed to retrieve image URL.");
    }

    return imageUrl;
  } catch (error) {
    console.error("Error generating image:", error.response.data);
    throw new Error("Failed to generate image.");
  }
}

async function uploadImageToS3(imageUrl, imageName) {
  try {
    const response = await axios.get(imageUrl, { responseType: "arraybuffer" });

    const params = {
      Bucket: outputBucket,
      Key: imageName,
      Body: response.data,
      ContentType: "image/png"
    };

    const command = new PutObjectCommand(params);
    await s3Client.send(command);
    console.log(`Image uploaded to S3: ${imageName}`);

    const imageUrlS3 = `https://${outputBucket}.s3.amazonaws.com/${imageName}`;
    return imageUrlS3;
  } catch (error) {
    console.error("Error uploading image to S3:", error);
    throw new Error("Failed to upload image to S3.");
  }
}

exports.handler = async (event) => {
  const originalPrompt = event.prompt;
  const numImages = event.numImages || 1;

  if (!originalPrompt) {
    throw new Error("Original prompt is required.");
  }

  console.log(`Generating ${numImages} images for prompt: "${originalPrompt}"`);

  const imageUrls = [];

  for (let i = 1; i <= numImages; i++) {
    try {
      const creativePrompt = await generateCreativePrompt(originalPrompt);
      console.log(`Generated creative prompt: "${creativePrompt}"`);

      const imageUrl = await generateImage(creativePrompt);
      console.log(`Generated image URL: ${imageUrl}`);

      const imageName = `${Date.now()}_${i}.png`;
      const s3Url = await uploadImageToS3(imageUrl, imageName);
      imageUrls.push(s3Url);
    } catch (error) {
      console.error(`Failed to process image ${i}:`, error);
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Successfully generated ${numImages} images.`,
      imageUrls
    }),
  };
};
