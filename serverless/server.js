const express = require("express");
const bodyParser = require("body-parser");
const { handler } = require("./index");

const app = express();
app.use(bodyParser.json());

app.post("/generate-images", async (req, res) => {
  try {
    const result = await handler(req.body);
    res.json(result);
  } catch (error) {
    console.error("Error handling request:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
