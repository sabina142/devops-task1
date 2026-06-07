const express = require("express");
const helmet = require("helmet");

const app = express();

app.use(helmet());

app.get("/", (req, res) => {
  res.send("Hello DevOps 🚀");
});

app.get("/predict", (req, res) => {
  res.json({
    prediction: "sample_prediction",
    confidence: 0.95,
    status: "success"
  });
});

app.listen(3000, () => {
  console.log("Server running on port 3000");
});