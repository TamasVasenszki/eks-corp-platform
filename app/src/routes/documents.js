const express = require("express");
const router = express.Router();
const { S3Client, PutObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const authMiddleware = require("../middleware/auth");

const s3 = new S3Client({ region: process.env.AWS_REGION });
const BUCKET = process.env.S3_BUCKET_NAME;

router.use(authMiddleware);

router.get("/upload-url/:employeeId/:filename", async (req, res) => {
  try {
    const key = `documents/${req.params.employeeId}/${req.params.filename}`;
    const url = await getSignedUrl(
      s3,
      new PutObjectCommand({ Bucket: BUCKET, Key: key }),
      { expiresIn: 300 }
    );
    res.json({ url, key });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/download-url/:employeeId/:filename", async (req, res) => {
  try {
    const key = `documents/${req.params.employeeId}/${req.params.filename}`;
    const url = await getSignedUrl(
      s3,
      new GetObjectCommand({ Bucket: BUCKET, Key: key }),
      { expiresIn: 300 }
    );
    res.json({ url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;