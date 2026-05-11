const { S3Client, ListObjectsV2Command, PutObjectCommand } = require("@aws-sdk/client-s3");

const s3 = new S3Client({ region: process.env.AWS_REGION });
const BUCKET = process.env.S3_BUCKET_NAME;
const HEALTH_URL = process.env.HEALTH_URL;

exports.handler = async () => {
  const timestamp = new Date().toISOString();

  // 1. Health check
  let healthStatus = "unknown";
  let healthData = {};
  try {
    const response = await fetch(HEALTH_URL);
    healthData = await response.json();
    healthStatus = response.ok ? "healthy" : "unhealthy";
  } catch (err) {
    healthStatus = "unreachable";
    healthData = { error: err.message };
  }

  // 2. S3 metadata
  let documentCount = 0;
  try {
    const result = await s3.send(new ListObjectsV2Command({
      Bucket: BUCKET,
      Prefix: "documents/"
    }));
    documentCount = result.KeyCount || 0;
  } catch (err) {
    console.error("S3 list error:", err.message);
  }

  // 3. Report
  const report = {
    timestamp,
    health: {
      status: healthStatus,
      ...healthData
    },
    s3: {
      documentCount
    }
  };

  // 4. Save report to S3
  const reportKey = `reports/health-${timestamp}.json`;
  await s3.send(new PutObjectCommand({
    Bucket: BUCKET,
    Key: reportKey,
    Body: JSON.stringify(report, null, 2),
    ContentType: "application/json"
  }));

  console.log("Report saved:", reportKey);
  return report;
};